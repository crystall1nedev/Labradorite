package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
	"strings"
	"time"
)

var debug = "0";

// Stores device mappings in memory for better performance
// Essential to starting the server!
var mappings = map[string]interface{}{
	"boardconfig": nil,
	"model":       nil,
	"identifier": nil,
}

// Stores device JSONs in memory for better performance
// TODO: Maybe not duplicate this sh*t three times...
var boardconfigDevices  = map[string]interface{}{}
var modelDevices        = map[string]interface{}{}
var identifierDevices   = map[string]interface{}{}

// Error messages for the requestor being dumb
var badEndpoint         = "Specs machine doesn't have that endpoint. Try requesting /help."
var badMethod           = "Specs machine doesn't allow that method."
var badRequest          = "Specs machine didn't understand that request."
var badKey              = "Specs machine couldn't find that property."

// Error messages for the server being dumb
var badDevice           = "Specs machine couldn't find that device."
var badDataRead         = "Specs machine encountered some bad data while trying to read files."
var badDataWrite        = "Specs machine encountered some bad data while trying to write files."
var badPath             = "Specs machine couldn't find the file it was looking for."
var badResponse         = "Specs machine couldn't supply the proper response."
var badNestedParsing    = "Specs machine wasn't able to fine-tune. Try boardening your search."

// Custom response writer to capture status codes.
type responseWriter struct { http.ResponseWriter; statusCode int }

// Capture the status code for logging.
func (rw *responseWriter) WriteHeader(code int) { rw.statusCode = code; rw.ResponseWriter.WriteHeader(code) }

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

// Extracts the client's IP address from the request headers or remote address.
func getClientIP(request *http.Request) string {
	xForwardedFor := request.Header.Get("X-Forwarded-For")
	if xForwardedFor != "" {
		parts := strings.Split(xForwardedFor, ",")
		if len(parts) > 0 { return strings.TrimSpace(parts[0]) }
	}

	xRealIP := request.Header.Get("X-Real-IP")
	if xRealIP != "" { return xRealIP }
	return request.RemoteAddr
}

// Logs each request with method, path, status code, duration, and client IP.
func loggingMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(writer http.ResponseWriter, request *http.Request) {
		start := time.Now()

		rw := &responseWriter{writer, http.StatusOK}
		next.ServeHTTP(rw, request)

		log.Printf("%s %s %d %s from %s", request.Method, request.URL.Path, rw.statusCode, time.Since(start), getClientIP(request))
	})
}

// Sends the HTTP response and headers to the client.
func respondToGet(writer http.ResponseWriter, response []byte) bool {
	fmt.Printf("[Request] Setting headers and sending response\n")
	writer.Header().Set("Content-Type", "application/json")
	writer.Header().Set("Cow", "true")
	writer.Write(response)

	return true
}

// Kinda self-explanatory.
func main() {
	// create a mux to as a middleman for logging stuff
	mux := http.NewServeMux()

	// Load all mappings into memory before offering any endpoints
	if !loadMappingsIntoMemory() { fmt.Println("Failed to load mapping jsons into memory!"); os.Exit(1) }

	// Load all device jsons into memory before offering any endpoints
	if !loadDeviceJSONsIntoMemory() { fmt.Println("Failed to load device jsons into memory!"); os.Exit(1) }

	if debug == "1" {
		fmt.Printf("[Initalization] Testing device interface: %s, %s\n", "d94ap", boardconfigDevices["d94ap"])
		fmt.Printf("[Initalization] Testing device interface: %s, %s\n", "a3084", modelDevices["a3084"])
		fmt.Printf("[Initalization] Testing device interface: %s, %s\n", "iphone17,2", identifierDevices["iphone17,2"])
	}

	fmt.Println("")

	// v0 endpoints, current
	mux.HandleFunc("/api/v0/identifier/", serveIdentifier)
	mux.HandleFunc("/api/v0/boardconfig/", serveBoardconfig)
	mux.HandleFunc("/api/v0/model/", serveModelCode)

	// rolling endpoints
	mux.HandleFunc("/api/identifier/", serveIdentifier)
	mux.HandleFunc("/api/boardconfig/", serveBoardconfig)
	mux.HandleFunc("/api/model/", serveModelCode)

	// help endpoint
	mux.HandleFunc("/help", helpHandler)

	// misc endpoints
	mux.HandleFunc("/cow", moo)
	mux.HandleFunc("/", defaultHandler)

	// start the server
	fmt.Println("[Initalization] API running at http://localhost:8080")
	log.Fatal(http.ListenAndServe(":8080", loggingMiddleware(mux)))
}
