package main

import (
	"fmt"
	"net/http"
	"os"
	"path/filepath"
)

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

	jsonResponse := parseDeviceJSON(writer, request, subkeys, lookup)
	if jsonResponse == nil { return }

	if !respondToGet(writer, jsonResponse) {
		http.Error(writer, badResponse, http.StatusInternalServerError)
		fmt.Printf("[Request] Failed to send a response to the client.\n")
		return
	}
}