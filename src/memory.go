package main

import (
	"fmt"
	"os"
	"path/filepath"
)

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