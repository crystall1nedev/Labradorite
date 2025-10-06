package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"time"
)

// Stores device mappings in memory for better performance
// Essential to starting the server!
var mappings = map[string]interface{}{
	"boardconfig": nil,
	"model":       nil,
	"identifier": nil,
}

// Stores device JSONs in memory for better performance
// TODO: Maybe not duplicate this sh*t three times...
var boardconfigDevices = map[string]interface{}{}
var modelDevices = map[string]interface{}{}
var identifierDevices = map[string]interface{}{}

// Error messages for the requestor being dumb
var badEndpoint      = "Specs machine doesn't have that endpoint. Try requesting /help."
var badMethod        = "Specs machine doesn't allow that method."
var badRequest       = "Specs machine didn't understand that request."
var badKey           = "Specs machine couldn't find that property."

// Error messages for the server being dumb
var badDevice        = "Specs machine couldn't find that device."
var badDataRead      = "Specs machine encountered some bad data while trying to read files."
var badDataWrite     = "Specs machine encountered some bad data while trying to write files."
var badPath          = "Specs machine couldn't find the file it was looking for."
var badResponse      = "Specs machine couldn't supply the proper response."
var badNestedParsing = "Specs machine wasn't able to fine-tune. Try boardening your search."

// Custom response writer to capture status codes.
type responseWriter struct { http.ResponseWriter; statusCode int }

// Capture the status code for logging.
func (rw *responseWriter) WriteHeader(code int) { rw.statusCode = code; rw.ResponseWriter.WriteHeader(code) }

// Serves /identifier/ requests.
func serveIdentifier(writer http.ResponseWriter, request *http.Request) { serveDevice(writer, request, "identifier") }

// Serves /model/ requests.
func serveModelCode(writer http.ResponseWriter, request *http.Request) { serveDevice(writer, request, "model") }

// Serves /boardconfig/ requests.
func serveBoardconfig(writer http.ResponseWriter, request *http.Request) { serveDevice(writer, request, "boardconfig") }

// Splits strings based on "/" to allow precise parsing.
// i.e. D94AP -> the entire json, D94AP/chips -> the "chips" dictionary, so on and so forth.
func extractPathAfter(target string, path string) (id string, subkeys []string, ok bool) {
	path = strings.TrimSuffix(path, "/")

	parts := strings.Split(path, "/")
	for i, part := range parts {
		if part == target && i+1 < len(parts) {
			return strings.ToLower(parts[i+1]), parts[i+2:], true
		}
	}
	return "", nil, false
}

// Loads a JSON file and returns its content as an interface{} for flexible traversal.
func loadJSON(path string) (interface{}, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}
	var result interface{}
	err = json.Unmarshal(data, &result)
	return result, err
}

// Extracts the client's IP address from the request headers or remote address.
func getClientIP(request *http.Request) string {
	xForwardedFor := request.Header.Get("X-Forwarded-For")
	if xForwardedFor != "" {
		parts := strings.Split(xForwardedFor, ",")
		if len(parts) > 0 {
			return strings.TrimSpace(parts[0])
		}
	}

	xRealIP := request.Header.Get("X-Real-IP")
	if xRealIP != "" {
		return xRealIP
	}
	return request.RemoteAddr
}

// Logs each request with method, path, status code, duration, and client IP.
func loggingMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(writer http.ResponseWriter, request *http.Request) {
		start := time.Now()

		rw := &responseWriter{writer, http.StatusOK}
		next.ServeHTTP(rw, request)

		duration := time.Since(start)
		clientIP := getClientIP(request)
		log.Printf("%s %s %d %s from %s", request.Method, request.URL.Path, rw.statusCode, duration, clientIP)
	})
}

// Reusable function to parse and server the JSON we loaded into memory, and fall back to on-disk JSON if required.
func serveDevice(writer http.ResponseWriter, request *http.Request, mapping string) {
	id, subkeys, ok := extractPathAfter(mapping, request.URL.Path)
	if !ok {
		// Error: extractPathAfter failed, bad request
		http.Error(writer, badRequest, http.StatusBadRequest)
		fmt.Printf("[Request] Unable to parse request \"%s\"\n", request.URL.RequestURI())
		return
	}

	var dict map[string]interface{}

	switch mapping {
	case "boardconfig": dict = boardconfigDevices
	case "identifier": dict = identifierDevices
	case "model": dict = modelDevices
	}

	lookup, ok := dict[id] 
	if !ok {
		fmt.Printf("[Request] Couldn't find that device in memory, restarting from on-disk.\n")
		lookupMap, ok := mappings[mapping].(map[string]interface{})
		if !ok {
			http.Error(writer, "", http.StatusInternalServerError)
			return
		}

		val, exists := lookupMap[id]
		if !exists {
			// Error: Mapping didn't return data for that device
			http.Error(writer, badDevice, http.StatusNotFound)
			fmt.Printf("[Request] Unable to find device \"%s\"\n", id)
			return
		}

		valStr, ok := val.(string)
		if !ok {
			// Error: Unable to convert JSON path into string
			http.Error(writer, badDataRead, http.StatusInternalServerError)
			fmt.Printf("[Request] Unable to convert value to string \"%s\"\n", val)
			return
		}

		filePath := filepath.Join(valStr)

		fmt.Printf("[Request] Getting ready to serve the %s data from \"%s\"\n", mapping, filePath)

		if _, err := os.Stat(filePath); os.IsNotExist(err) {
			// Error: Device file is missing
			http.Error(writer, badPath, http.StatusInternalServerError)
			fmt.Printf("[Request] Unable to locate \"%s\"\n", filePath)
			return
		}

		fmt.Printf("[Request] Found our file at \"%s\", now parsing it.\n", filePath)

		var err error
		lookup, err = loadJSON(filePath)
		if err != nil {
			// Error: Device file is unloadable
			http.Error(writer, badDataRead, http.StatusInternalServerError)
			fmt.Printf("[Request] Unable to parse the JSON at \"%s\"\n", filePath)
			return
		}
	}

	jsonResponse := parseDeviceJSON(writer, subkeys, lookup)
	if jsonResponse == nil { return }

	if !respondToGet(writer, jsonResponse) {
		http.Error(writer, badResponse, http.StatusInternalServerError)
		fmt.Printf("[Request] Failed to send a response to the client.\n")
		return
	}
}

// Parses the device JSON - whether ir be from in memory, or on disk.
func parseDeviceJSON(writer http.ResponseWriter, subkeys []string, data interface{}) []byte {
	fmt.Printf("[Request] Checking if we need to drill down further\n")

	for _, key := range subkeys {
		fmt.Printf("[Request] Drilling down farther\n")
		m, ok := data.(map[string]interface{})
		if !ok {
			// Error: Nested parsing failed
			http.Error(writer, badNestedParsing, http.StatusInternalServerError)
			fmt.Printf("[Request] Unable to parse the JSON at \"%s\"\n", m)
			return nil
		}
		fmt.Printf("[Request] Attempting to get value for \"%s\"\n", key)
		val, exists := m[key]
		if !exists {
			// Error: The key that was requested doesn't exist
			http.Error(writer, badKey, http.StatusBadRequest)
			fmt.Printf("[Request] Unable to find key \"%s\"\n", key)
			return nil
		}
		fmt.Printf("[Request] Value retrieved, continuing.\n")
		data = val
	}

	fmt.Printf("[Request] Remarshalling...\n")

	response, err := json.Marshal(data)
	if err != nil {
		// Error: Remarshalling failed.
		http.Error(writer, badDataWrite, http.StatusInternalServerError)
		fmt.Printf("[Request] Unable to marshal the JSON: \"%s\"\n", err)
		return nil
	}

	return response
}

// Sends the HTTP response and headers to the client.
func respondToGet(writer http.ResponseWriter, response []byte) bool {
	fmt.Printf("[Request] Setting headers and sending response\n")
	writer.Header().Set("Content-Type", "application/json")
	writer.Header().Set("Cow", "true")
	writer.Write(response)

	return true
}

// Handles the invalid stuff.
func defaultHandler(writer http.ResponseWriter, request *http.Request) {
	if request.Method != http.MethodGet {
		http.Error(writer, badMethod, http.StatusMethodNotAllowed)
		return
	}

	http.Error(writer, badEndpoint, http.StatusNotFound)
}

// Handles someone asking for help.
func helpHandler(writer http.ResponseWriter, request *http.Request) {
	response := "Welcome to the Labradorite API server.\n"
	response += "Made by Eva with <3 since 2025.\n"
	response += "\n"
	response += "Available endpoints:\n"
	response += "\n"
	response += "/api/v0/identifier\n"
	response += "  - Returns a JSON based on the provided model identifier (i.e. iPhone17,2)\n"
	response += "  - Rolling release endpoint is available at /api/identifier\n"
	response += "/api/v0/model\n"
	response += "  - Returns a JSON based on the provided model number (i.e. A3084)\n"
	response += "  - Rolling release endpoint is available at /api/model\n"
	response += "/api/v0/boardconfig\n"
	response += "  - Returns a JSON based on the provided boardconfig (i.e. D94AP)\n"
	response += "  - Rolling release endpoint is available at /api/boardconfig\n"
	response += "\n"
	response += "Notes on endpoints:\n"
	response += "\n"
	response += "The entire API is under construction.\n"
	response += "  - DO NOT DEPEND ON THE OUTPUT OF THIS API UNTIL /api/v1 ENDPOINTS ARE AVAILABLE.\n"
	response += "  - Many devices and data are missing or corrupted.\n"
	response += "  - The format of each returned JSON is subject to change - minimal or complete.\n"
	response += "All endpoints support drilling. You can supply nested key names to only return those values.\n"
	response += "  - /api/boardconfig/D94AP will return the full json for \"D94AP\".\n"
	response += "  - /api/boardconfig/D94AP/chips/soc will return the value for \"chips.soc\" in the json for \"D94AP\".\n"

	if !respondToGet(writer, []byte(response)) {
		http.Error(writer, badResponse, http.StatusInternalServerError)
		fmt.Printf("[Request] Failed to send a response to the client.\n")
		return
	}
}

// ...
func moo(writer http.ResponseWriter, request *http.Request) { http.Error(writer, "moo", http.StatusTeapot) }

// Loads the specified mapping file and returns its contents
func loadMappingsIntoMemory(mapping string) interface{} {
	mappingPath := fmt.Sprintf("mappings/%ss.json", mapping)
	if _, err := os.Stat(mappingPath); os.IsNotExist(err) {
		// Error: Mapping file is missing
		// Show in console
		fmt.Printf("[Mappings] Mapping file \"mappings/%ss.json\" is not present! Stopping server...\n", mapping)
		os.Exit(1)
	}

	fmt.Printf("[Mappings] Loading the %s mapping file from \"%s\"\n", mapping, mappingPath)

	mappingJSONRaw, err := loadJSON(fmt.Sprintf("mappings/%ss.json", mapping))

	if err != nil {
		// Error: Mapping file is unloadable
		// Show in console
		fmt.Printf("[Mappings] Mapping file \"mappings/%ss.json\" is not loadable! Stopping server...\n", mapping)
		os.Exit(1)

	}

	fmt.Printf("[Mappings] Loaded the %s mapping file, attempting to parse and return\n", mapping)

	mappingJSON, ok := mappingJSONRaw.(map[string]interface{})
	if !ok {
		// Error: Mapping file couldn't be parsed
		// Show in console
		fmt.Printf("[Mappings] Mapping file \"mappings/%ss.json\" is not loadable! Stopping server...\n", mapping)
		os.Exit(1)
	}

	fmt.Printf("[Mappings] Parsed the %s mapping file successfully.\n", mapping)

	return mappingJSON
}

func loadDeviceJSONsIntoMemory() bool {
	// first load boardconfig mapping json
	// then a for loop:
	// - load device json for board
	// - add 

	for dict := range mappings {
		mapping, ok := mappings[dict].(map[string]interface{})
		if !ok { return false }

		for key := range mapping {
			val, exists := mapping[key]
			if !exists {
				// Error: Mapping file didn't return data for that device
				// This is user error (or server outdated), throw 404
				// Show to the user: "Unable to locate the provided device in database."
				// Show in console:  ""
				return false
			}

			valStr, ok := val.(string)
			if !ok {
				return false
			}

			filePath := filepath.Join(valStr)

			if _, err := os.Stat(filePath); os.IsNotExist(err) {
				// Error: Device file is missing
				// This is server error, throw 500
				// Show to the user: "Unable to find the file we were looking for."
				// Show in console:  ""
				return false
			}

			//fmt.Printf("[Request] Found our file at \"%s\", now parsing it.\n", filePath)

			data, err := loadJSON(filePath)
			if err != nil {
				// Error: Device file is unloadable
				// This is server error, throw 500
				// Show to the user: "Unable to parse the file we were looking for."
				// Show in console:  ""
				return false
			}

			switch dict {
				case "boardconfig": boardconfigDevices[key] = data
				case "model": modelDevices[key] = data
				case "identifier": identifierDevices[key] = data
			}
		}
	}

	return true
}

// Kinda self-explanatory.
func main() {
	mux := http.NewServeMux()

	// Load all mappings into memory before offering any endpoints
	mappings["boardconfig"]      = loadMappingsIntoMemory("boardconfig")
	mappings["model"]            = loadMappingsIntoMemory("model")
	mappings["identifier"]       = loadMappingsIntoMemory("identifier")

	if !loadDeviceJSONsIntoMemory() {
		fmt.Println("Failed to load device jsons into memory!")
		os.Exit(1)
	}

	//fmt.Printf("[Initalization] Testing device interface: %s, %s\n", "d94ap", boardconfigDevices["d94ap"])
	//fmt.Printf("[Initalization] Testing device interface: %s, %s\n", "a3084", modelDevices["a3084"])
	//fmt.Printf("[Initalization] Testing device interface: %s, %s\n", "iphone17,2", identifierDevices["iphone17,2"])

	fmt.Println("")

	mux.HandleFunc("/api/v0/identifier/", serveIdentifier)
	mux.HandleFunc("/api/v0/boardconfig/", serveBoardconfig)
	mux.HandleFunc("/api/v0/model/", serveModelCode)

	mux.HandleFunc("/api/identifier/", serveIdentifier)
	mux.HandleFunc("/api/boardconfig/", serveBoardconfig)
	mux.HandleFunc("/api/model/", serveModelCode)

	mux.HandleFunc("/help", helpHandler)

	mux.HandleFunc("/cow", moo)
	mux.HandleFunc("/", defaultHandler)

	fmt.Println("[Initalization] API running at http://localhost:8080")
	log.Fatal(http.ListenAndServe(":8080", loggingMiddleware(mux)))
}
