//
//  Utilities+Device.swift
//  Labradorite-Server
//
//  Created by Eva Isabella Luna on 10/18/25.
//

import Foundation
import Network

extension Utilities {
	class Device {
		var parent: Utilities
		
		init(parent: Utilities) { self.parent = parent }
		
		func serveDevice(connection: NWConnection, method: String, path: String, headers: [String: String]) {
			let usedTarget: String
			// determine which target this call comes from by path
			if path.localizedCaseInsensitiveContains("/identifier/") { usedTarget = "identifier" }
			else if path.localizedCaseInsensitiveContains("/model/") { usedTarget = "model" }
			else if path.localizedCaseInsensitiveContains("/boardconfig/") { usedTarget = "boardconfig" }
			else { // fallback try default extraction of first mapping found in path
				usedTarget = ["boardconfig","model","identifier"].first(where: { path.localizedCaseInsensitiveContains("/\($0)/") }) ?? "identifier"
			}
			
			let (id, subkeys, ok) = parent.extractPathAfter(target: usedTarget, path: path)
			guard ok else {
				parent.log("[Request] Unable to parse request \"%@\"", path)
				let body = Data(badRequest.utf8)
				parent.http.respondHeadersAndBody(connection: connection, status: 400, body: body)
				return
			}
			
			var dict: [String: Any]
			switch usedTarget {
			case "boardconfig": dict = boardconfigDevices
			case "model": dict = modelDevices
			default: dict = identifierDevices
			}
			
			if let lookup = dict[id] {
				// found in memory
				if let response = parent.json.parseDeviceJSON(subkeys: subkeys, data: lookup, headers: headers) {
					parent.http.respondHeadersAndBody(connection: connection, status: 200, body: response)
					return
				} else {
					let body = Data(badKey.utf8)
					parent.http.respondHeadersAndBody(connection: connection, status: 400, body: body)
					return
				}
			}
			
			parent.log("[Request] Couldn't find that device in memory, restarting from on-disk.")
			guard let lookupMap = mappings[usedTarget] else {
				let body = Data("".utf8)
				parent.http.respondHeadersAndBody(connection: connection, status: 500, body: body)
				return
			}
			
			guard let mappedPathRaw = lookupMap[id] else {
				parent.log("[Request] Unable to find device \"%@\"", id)
				let body = Data(badDevice.utf8)
				parent.http.respondHeadersAndBody(connection: connection, status: 404, body: body)
				return
			}
			
			guard let mappedPath = mappedPathRaw as? String else {
				parent.log("[Request] Unable to convert value to string \"%@\"", String(describing: mappedPathRaw))
				let body = Data(badDataRead.utf8)
				parent.http.respondHeadersAndBody(connection: connection, status: 500, body: body)
				return
			}
			
			let filePath = mappedPath
			parent.log("[Request] Getting ready to serve the %@ data from \"%@\"", usedTarget, filePath)
			
			if !FileManager.default.fileExists(atPath: filePath) {
				parent.log("[Request] Unable to locate \"%@\"", filePath)
				let body = Data(badPath.utf8)
				parent.http.respondHeadersAndBody(connection: connection, status: 500, body: body)
				return
			}
			
			parent.log("[Request] Found our file at \"%@\", now parsing it.", filePath)
			do {
				let loaded = try parent.json.loadJSON(at: filePath)
				if let response = parent.json.parseDeviceJSON(subkeys: subkeys, data: loaded, headers: headers) {
					parent.http.respondHeadersAndBody(connection: connection, status: 200, body: response)
					return
				} else {
					let body = Data(badKey.utf8)
					parent.http.respondHeadersAndBody(connection: connection, status: 400, body: body)
					return
				}
			} catch {
				parent.log("[Request] Unable to parse the JSON at \"%@\"", filePath)
				let body = Data(badDataRead.utf8)
				parent.http.respondHeadersAndBody(connection: connection, status: 500, body: body)
				return
			}
		}
	}
}
