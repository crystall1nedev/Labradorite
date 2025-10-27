//
//  main.swift
//  Labradorite-Server
//
//  Created by Eva Isabella Luna on 10/18/25.
//

import Foundation
import Network

let utilities = Utilities()

func welcome() {
	print("Welcome to the Labradorite API server.")
	print("Made by Eva with <3 since 2025.")
	print("")
}

func loadIntoMemory() {
	utilities.log("[Initialization] Loading mappings and device db into memory")
	if !utilities.device.memory.loadMappingsIntoMemory() {
		utilities.log("Failed to load mapping jsons into memory! Exiting.")
		if !utilities.terminal.arguments.safetyOff { exit(1) }
	}

	if !utilities.device.memory.loadDeviceJSONsIntoMemory() {
		utilities.log("Failed to load device jsons into memory! Exiting.")
		if !utilities.terminal.arguments.safetyOff { exit(1) }
	}
}

let port: NWEndpoint.Port = 8080

var mappings: [String: [String: Any]] = [
	"boardconfig": [:],
	"model": [:],
	"identifier": [:]
]

var boardconfigDevices: [String: Any] = [:]
var modelDevices: [String: Any] = [:]
var identifierDevices: [String: Any] = [:]

let badEndpoint         = "Specs machine doesn't have that endpoint. Try requesting /help."
let badMethod           = "Specs machine doesn't allow that method."
let badRequest          = "Specs machine didn't understand that request."
let badKey              = "Specs machine couldn't find that property."

let badDevice           = "Specs machine couldn't find that device."
let badDataRead         = "Specs machine encountered some bad data while trying to read files."
let badDataWrite        = "Specs machine encountered some bad data while trying to write files."
let badPath             = "Specs machine couldn't find the file it was looking for."
let badResponse         = "Specs machine couldn't supply the proper response."
let badNestedParsing    = "Specs machine wasn't able to fine-tune. Try boardening your search."

let listener = try NWListener(using: .tcp, on: port)

listener.newConnectionHandler = { newConnection in
	newConnection.start(queue: .global())
	newConnection.receive(minimumIncompleteLength: 1, maximumLength: 64 * 1024) { (data, _, isComplete, error) in
		guard let data = data, !data.isEmpty else {
			newConnection.cancel()
			return
		}

		guard let req = utilities.http.parseHTTPRequest(data) else {
			let body = Data(badRequest.utf8)
			utilities.http.respondHeadersAndBody(connection: newConnection, status: 400, body: body)
			return
		}

		utilities.log("%@ %@ from %@", req.method, req.path, utilities.http.clientIP(from: newConnection))

		// Only GET supported
		if req.method != "GET" {
			let body = Data(badMethod.utf8)
			utilities.http.respondHeadersAndBody(connection: newConnection, status: 405, body: body)
			return
		}

		// Route handling
		let lowerPath = req.path.lowercased()
		if lowerPath.hasPrefix("/api/v0/identifier/") || lowerPath.hasPrefix("/api/identifier/") {
			utilities.device.serveDevice(connection: newConnection, method: req.method, path: req.path, headers: req.headers)
		} else if lowerPath.hasPrefix("/api/v0/model/") || lowerPath.hasPrefix("/api/model/") {
			utilities.device.serveDevice(connection: newConnection, method: req.method, path: req.path, headers: req.headers)
		} else if lowerPath.hasPrefix("/api/v0/boardconfig/") || lowerPath.hasPrefix("/api/boardconfig/") {
			utilities.device.serveDevice(connection: newConnection, method: req.method, path: req.path, headers: req.headers)
		} else if lowerPath == "/help" {
			utilities.http.handlers.handleHelp(connection: newConnection)
		} else if lowerPath == "/cow" {
			utilities.http.handlers.handleCow(connection: newConnection)
		} else {
			utilities.http.handlers.handleDefault(connection: newConnection)
		}

		if isComplete || error != nil {
			newConnection.cancel()
		}
	}
}

welcome()

loadIntoMemory()

listener.stateUpdateHandler = { state in
	switch state {
	case .ready:
		utilities.log("[Initialization] API running at http://localhost:%d", Int(port.rawValue))
		utilities.terminal.interactivity.runInteractiveLoop()
	case .failed(let err):
		utilities.log("Listener failed: %@", String(describing: err))
		exit(1)
	default:
		break
	}
}

listener.start(queue: .global())

dispatchMain()

