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

var fileReadErrorMessage = "Specs machine brokey! File read error."

var mappingFileMissingMessage = "Specs machine brokey! Couldn't find the mapping file."
var mappedFileMissingMessage = "Specs machine brokey! Couldn't find the file that mapping is pointing to."

var deviceNotFoundMessage = "Specs machine brokey! Couldn't find that %s"
var deviceFileMissingMessage = "Specs machine brokey! Couldn't find the file that %s is pointing to."

var keyNotFoundMessage = "Specs machine brokey! Couldn't find that key."

var generalError = "Specs machine brokey! Encountered an error. Try again later."

var mappings = map[string]interface{}{
	"boardconfig": nil,
	"model":       nil,
	"identifiers": nil,
}

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

// Custom response writer to capture status codes.
type responseWriter struct {
	http.ResponseWriter
	statusCode int
}

// Capture the status code for logging.
func (rw *responseWriter) WriteHeader(code int) {
	rw.statusCode = code
	rw.ResponseWriter.WriteHeader(code)
}

// Serves /identifier/ requests.
func serveIdentifier(writer http.ResponseWriter, request *http.Request) {
	parseAndServeJSON(writer, request, "identifier")
}

// Serves /model/ requests.
func serveModelCode(writer http.ResponseWriter, request *http.Request) {
	parseAndServeJSON(writer, request, "model")
}

// Serves /boardconfig/ requests.
func serveBoardconfig(writer http.ResponseWriter, request *http.Request) {
	parseAndServeJSON(writer, request, "boardconfig")
}

// Reusable function to parse the JSON at filePath, drill down using subkeys, and serve the result.
func parseAndServeJSON(writer http.ResponseWriter, request *http.Request, mapping string) {
	id, subkeys, ok := extractPathAfter(mapping, request.URL.Path)
	if !ok {
		// Error: extractPathAfter failed, bad request
		// This is user error, throw 400
		// Show to the user: "Unable to parse request"
		// Show in console:  ""
		http.Error(writer, "", http.StatusBadRequest)
		return
	}

	// Handle mapping JSON being missing
	mappingPath := fmt.Sprintf("mappings/%ss.json", mapping)
	if _, err := os.Stat(mappingPath); os.IsNotExist(err) {
		// Error: Mapping file is missing
		// This is a server error, throw 500
		// Show to the user: "Unable to locate the file we were looking for."
		// Show in console:  ""
		http.Error(writer, "", http.StatusInternalServerError)
		return
	}

	fmt.Printf("[Request for %s] Loading the %s mapping file from \"%s\"\n", id, mapping, mappingPath)

	lookupRaw, err := loadJSON(mappingPath)
	if err != nil {
		// Error: Mapping file is unloadable
		// This is server error, throw 500
		// Show to the user: "Unable to parse the file we were looking for."
		// Show in console:  ""
		http.Error(writer, "", http.StatusInternalServerError)
		return
	}

	lookup, ok := lookupRaw.(map[string]interface{})
	if !ok {
		http.Error(writer, "", http.StatusInternalServerError)
		return
	}

	fmt.Printf("[Request for %s] Ensuring %s\n", id, id)

	val, exists := lookup[id]
	if !exists {
		// Error: Mapping file didn't return data for that device
		// This is user error (or server outdated), throw 404
		// Show to the user: "Unable to locate the provided device in database."
		// Show in console:  ""
		http.Error(writer, "", http.StatusNotFound)
		return
	}

	valStr, ok := val.(string)
	if !ok {
		http.Error(writer, "", http.StatusInternalServerError)
		return
	}

	filePath := filepath.Join(valStr)

	fmt.Printf("[Request for %s] Getting ready to serve the %s data from \"%s\"\n", id, mapping, filePath)

	if _, err := os.Stat(filePath); os.IsNotExist(err) {
		// Error: Device file is missing
		// This is server error, throw 500
		// Show to the user: "Unable to find the file we were looking for."
		// Show in console:  ""
		http.Error(writer, "", http.StatusInternalServerError)
		return
	}

	fmt.Printf("[Request for %s] Found our file at \"%s\", now parsing it.\n", id, filePath)

	data, err := loadJSON(filePath)
	if err != nil {
		// Error: Device file is unloadable
		// This is server error, throw 500
		// Show to the user: "Unable to parse the file we were looking for."
		// Show in console:  ""
		http.Error(writer, "", http.StatusInternalServerError)
		return
	}

	fmt.Printf("[Request for %s] Checking if we need to drill down further\n", id)

	for _, key := range subkeys {
		fmt.Printf("[Request for %s] Drilling down farther\n", id)
		m, ok := data.(map[string]interface{})
		if !ok {
			// Error: Nested parsing failed
			// This is a server error, throw 500
			// Show to the user: "Unable to parse nested properties, try removing them."
			// Show in console:  ""
			http.Error(writer, "", http.StatusInternalServerError)
			return
		}
		fmt.Printf("[Request for %s] Attempting to get value for \"%s\"\n", id, key)
		val, exists := m[key]
		if !exists {
			// Error: The key that was requested doesn't exist
			// This is a user error, throw 400
			// Show to the user: "Requested key does not exist here."
			// Show in console:  ""
			http.Error(writer, "", http.StatusBadRequest)
			return
		}
		fmt.Printf("[Request for %s] Value retrieved, continuing.\n", id)
		data = val
	}

	fmt.Printf("[Request for %s] Remarshalling...\n", id)

	response, err := json.Marshal(data)
	if err != nil {
		// Error: Remarshalling failed.
		// This is a server error, throw 500
		// Show to the user: "Unable to rebuild JSON."
		// Show in console:  ""
		http.Error(writer, "", http.StatusInternalServerError)
		return
	}

	fmt.Printf("[Request for %s] Setting headers and sending response\n", id)
	writer.Header().Set("Content-Type", "application/json")
	writer.Header().Set("Gay", "true")
	writer.Write(response)
}

// Handles the invalid stuff.
func defaultHandler(writer http.ResponseWriter, request *http.Request) {
	if request.Method != http.MethodGet {
		http.Error(writer, "Specs machine brokey! You can't use that method here.", http.StatusMethodNotAllowed)
		return
	}

	http.Error(writer, "Specs machine brokey! Invalid endpoint.", http.StatusNotFound)
}

func loadMappings(mapping string) interface{} {
	/*
		// Handle mapping JSON being missing


		lookupRaw, err := loadJSON(mappingPath)
		if err != nil {
			// Error: Mapping file is unloadable
			// This is server error, throw 500
			// Show to the user: "Unable to parse the file we were looking for."
			// Show in console:  ""
			http.Error(writer, "", http.StatusInternalServerError)
			return
		}

		lookup, ok := lookupRaw.(map[string]interface{})
		if !ok {
			http.Error(writer, "", http.StatusInternalServerError)
			return
		}
	*/
	mappingPath := fmt.Sprintf("mappings/%ss.json", mapping)
	if _, err := os.Stat(mappingPath); os.IsNotExist(err) {
		// Error: Mapping file is missing
		// Show in console:  ""
		os.Exit(1)
	}

	fmt.Printf("Loading the %s mapping file from \"%s\"\n", mapping, mappingPath)

	mappingJSONRaw, err := loadJSON(fmt.Sprintf("mappings/%ss.json"))

	if err != nil {
		os.Exit(1)

	}

	mappingJSON, ok := mappingJSONRaw.(map[string]interface{})
	if !ok {
		os.Exit(1)
	}

	return mappingJSON
}

// Kinda self-explanatory.
func main() {
	mux := http.NewServeMux()

	//mappings["boardconfig"] = loadJSON("mappings/boardconfigs.json")

	mux.HandleFunc("/api/v0/identifier/", serveIdentifier)
	mux.HandleFunc("/api/v0/boardconfig/", serveBoardconfig)
	mux.HandleFunc("/api/v0/model/", serveModelCode)

	mux.HandleFunc("/identifier/", serveIdentifier)
	mux.HandleFunc("/boardconfig/", serveBoardconfig)
	mux.HandleFunc("/model/", serveModelCode)

	mux.HandleFunc("/", defaultHandler)

	fmt.Println("API running at http://localhost:8080")
	log.Fatal(http.ListenAndServe(":8080", loggingMiddleware(mux)))
}
