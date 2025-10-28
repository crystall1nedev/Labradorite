//
//  main.swift
//  Labradorite-Server
//
//  Created by Eva Isabella Luna on 10/18/25.
//

import Foundation
import Network

let utilities = Utilities()
utilities.terminal.arguments.parse()

func welcome() {
	utilities.log("", "Labradorite Server", printPrompt: false)
	utilities.log("", "Made by Eva with <3 since 2025.", printPrompt: false)
	utilities.log("", "", printPrompt: false)
}

welcome()

for issue in utilities.terminal.arguments.issues {
	switch issue {
	case .unknown(let arg, _):
		utilities.log("Arguments", "Unknown argument: \(arg)", printPrompt: false)
	case .missingValue(let arg, _):
		utilities.log("Arguments", "Missing value for \(arg)", printPrompt: false)
	case .missingPath(let arg, _):
		utilities.log("Arguments", "Missing path: \(arg)", printPrompt: false)
	case .helpShown:
		utilities.terminal.arguments.returnServerHelp()
		exit(0)
	}
}

if !utilities.terminal.arguments.issues.isEmpty && !utilities.terminal.arguments.safetyOff {
	utilities.log("", "", printPrompt: false)
	utilities.terminal.arguments.returnServerHelp()
	exit(1)
}

func loadIntoMemory() {
	if !utilities.device.memory.loadMappingsIntoMemory() {
		utilities.log("Mappings", "Failed to load mapping jsons into memory! Exiting.")
		if !utilities.terminal.arguments.safetyOff { exit(1) }
	}

	if !utilities.device.memory.loadDeviceJSONsIntoMemory() {
		utilities.log("Devices", "Failed to load device jsons into memory! Exiting.")
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

		utilities.log("Request", "\(req.method) \(req.path) from \(utilities.http.clientIP(from: newConnection))")

		// Only GET supported
		if req.method != "GET" {
			let body = Data(badMethod.utf8)
			utilities.http.respondHeadersAndBody(connection: newConnection, status: 405, body: body)
			return
		}

		// Route handling
		let lowerPath = req.path.lowercased()
		
		switch lowerPath {
		case _ where lowerPath.hasPrefix("/api/v0") || lowerPath.hasPrefix("/api"):
			utilities.device.serveDevice(connection: newConnection, method: req.method, path: req.path, headers: req.headers, console: false)
		case "/help":
			utilities.http.handlers.handleHelp(connection: newConnection)
		case "/cow":
			utilities.http.handlers.handleHelp(connection: newConnection)
		case "/host":
			if utilities.terminal.arguments.shouldEnableHostInfo { utilities.http.handlers.handleHost(connection: newConnection)
			} else { utilities.http.handlers.handleDefault(connection: newConnection)}
		default:
			utilities.http.handlers.handleDefault(connection: newConnection)
		}

		if isComplete || error != nil {
			newConnection.cancel()
		}
	}
}

utilities.log("Initialization", "Loading mappings and device db into memory...")
loadIntoMemory()

listener.stateUpdateHandler = { state in
	switch state {
	case .ready:
		utilities.log("Initialization", "API running at http://localhost:%d", Int(port.rawValue))
		if utilities.terminal.arguments.shouldBeInteractive { utilities.terminal.interactivity.runInteractiveLoop() }
	case .failed(let err):
		utilities.log("Initialization", "Listener failed: \(String(describing: err))")
		exit(1)
	default:
		break
	}
}

listener.start(queue: .global())

dispatchMain()


