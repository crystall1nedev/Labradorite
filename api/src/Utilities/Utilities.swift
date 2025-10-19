//
//  Utilities.swift
//  Labradorite-Server
//
//  Created by Eva Isabella Luna on 10/18/25.
//

import Foundation
import Network

class Utilities {
	var json: JSON!
	var http: HTTP!
	var memory: Memory!
	var device: Device!
	
	init() {
		self.json = JSON(parent: self)
		self.http = HTTP(parent: self)
		self.memory = Memory(parent: self)
		self.device = Device(parent: self)
	}
	
	func log(_ format: String, _ args: CVarArg...) {
		let msg = String(format: format, arguments: args)
		print(msg)
	}
	
	// Trim trailing slash and split path
	func pathComponents(from requestPath: String) -> [String] {
		var p = requestPath
		if p.hasSuffix("/") { p = String(p.dropLast()) }
		let comps = p.split(separator: "/").map { String($0) }
		return comps
	}
	
	// Extract id and subkeys after target (lowercased id)
	func extractPathAfter(target: String, path: String) -> (id: String, subkeys: [String], ok: Bool) {
		let comps = pathComponents(from: path)
		for i in 0..<comps.count {
			if comps[i].lowercased() == target.lowercased() && i + 1 < comps.count {
				let id = comps[i+1].lowercased()
				let subkeys = Array(comps.dropFirst(i+2))
				return (id, subkeys, true)
			}
		}
		return ("", [], false)
	}
}
