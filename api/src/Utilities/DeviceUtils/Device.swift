//
//  Utilities+Device.swift
//  Labradorite-Server
//
//  Created by Eva Isabella Luna on 10/18/25.
//

import Foundation
import Network

class Device {
	enum DeviceIssue: Error {
		case noerr(Data)
		case error(Int, String)
	}
	
	public var memory: Memory!
	
	public init() { self.memory = Memory(parent: self) }
	
	public func serveDevice(connection: NWConnection? = nil, method: String? = nil, path: String, headers: [String: String], console: Bool) {
		do {
			var options: JSONSerialization.WritingOptions = []
			if console {
				options = [ .fragmentsAllowed, .withoutEscapingSlashes, .sortedKeys ]
			} else {
				options = [ .prettyPrinted, .fragmentsAllowed, .withoutEscapingSlashes, .sortedKeys ]
			}
			let usedTarget: String
			// determine which target this call comes from by path
			if path.localizedCaseInsensitiveContains("/identifier/") { usedTarget = "identifier" }
			else if path.localizedCaseInsensitiveContains("/model/") { usedTarget = "model" }
			else if path.localizedCaseInsensitiveContains("/boardconfig/") { usedTarget = "boardconfig" }
			else { // fallback try default extraction of first mapping found in path
				usedTarget = ["boardconfig","model","identifier"].first(where: { path.localizedCaseInsensitiveContains("/\($0)/") }) ?? "identifier"
			}
			
			let (id, subkeys, ok) = utilities.extractPathAfter(target: usedTarget, path: path)
			guard ok else {
				utilities.log("Request", "Unable to parse request \(path)")
				throw DeviceIssue.error(400, badRequest)
			}
			
			var dict: [String: Any]
			switch usedTarget {
			case "boardconfig": dict = boardconfigDevices
			case "model": dict = modelDevices
			default: dict = identifierDevices
			}
			
			if let lookup = dict[id] {
				// found in memory
				if let response = utilities.json.parseDeviceJSON(subkeys: subkeys, data: lookup, headers: headers, options: options) {
					throw DeviceIssue.noerr(response)
				} else {
					throw DeviceIssue.error(400, badKey)
				}
			}
			
			utilities.log("Request", "Couldn't find that device in memory, restarting from on-disk")
			guard let lookupMap = mappings[usedTarget] else {
				throw DeviceIssue.error(500, "")
			}
			
			guard let mappedPathRaw = lookupMap[id] else {
				utilities.log("Request", "Unable to find device \(id)")
				throw DeviceIssue.error(500, badDevice)
			}
			
			guard let mappedPath = mappedPathRaw as? String else {
				utilities.log("Request", "Unable to convert value to string \(String(describing: mappedPathRaw))")
				throw DeviceIssue.error(500, badDataRead)
			}
			
			var pathToJson = [utilities.terminal.arguments.dataPath ?? ""]
			for str in mappedPath.split(separator: "/") { pathToJson.append(String(str)) }
			let filePath = NSString.path(withComponents: pathToJson)
			utilities.log("Request", "Getting ready to serve the \(usedTarget) data from \(filePath)")
			
			if !FileManager.default.fileExists(atPath: filePath) {
				utilities.log("Request", "Unable to locate \(filePath)", )
				throw DeviceIssue.error(500, badPath)
			}
			
			utilities.log("Request", "Found our file at \(filePath), now parsing it")
			do {
				let loaded = try utilities.json.loadJSON(at: filePath)
				if let response = utilities.json.parseDeviceJSON(subkeys: subkeys, data: loaded, headers: headers, options: options) {
					throw DeviceIssue.noerr(response)
				} else {
					throw DeviceIssue.error(400, badKey)
				}
			} catch {
				utilities.log("Request", "Unable to parse the JSON at \(filePath)")
				throw DeviceIssue.error(500, badDataRead)
			}
		} catch DeviceIssue.noerr(let data) {
			if console { utilities.log("Request", String(data: data, encoding: .utf8) ?? "Data was unreadable")
			} else { guard let connection = connection else { return }
				utilities.http.respondHeadersAndBody(connection: connection, status: 200, body: data)
			}
		} catch DeviceIssue.error(let code, let body) {
			if console { utilities.log("Request", body)
			} else { guard let connection = connection else { return }
				utilities.http.respondHeadersAndBody(connection: connection, status: code, body: Data(body.utf8))
			}
		} catch {
			utilities.log("Request", "Request failed for an unknown reason")
		}
	}
}
