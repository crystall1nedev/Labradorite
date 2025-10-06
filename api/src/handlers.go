package main

import (
	"fmt"
	"net/http"
)

// Handles the invalid stuff.
func defaultHandler(writer http.ResponseWriter, request *http.Request) {
	if request.Method != http.MethodGet { http.Error(writer, badMethod, http.StatusMethodNotAllowed); return }

	// use 404 or 400?
	http.Error(writer, badEndpoint, http.StatusBadRequest)
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

// Serves /identifier/ requests.
func serveIdentifier(writer http.ResponseWriter, request *http.Request) { serveDevice(writer, request, "identifier") }

// Serves /model/ requests.
func serveModelCode(writer http.ResponseWriter, request *http.Request) { serveDevice(writer, request, "model") }

// Serves /boardconfig/ requests.
func serveBoardconfig(writer http.ResponseWriter, request *http.Request) { serveDevice(writer, request, "boardconfig") }