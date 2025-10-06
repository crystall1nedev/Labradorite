package main

import (
	"encoding/json"
	"fmt"
	"net/http"
	"os"
)

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