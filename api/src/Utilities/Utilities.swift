//
//  Utilities.swift
//  Labradorite-Server
//
//  Created by Eva Isabella Luna on 10/18/25.
//

import Foundation
import Network

class Utilities {
	var device:   Device!
	var json:     JSON!
	var http:     HTTP!
	var terminal: Terminal!
	
	init() {
		self.device = Device()
		self.json = JSON()
		self.http = HTTP()
		self.terminal = Terminal()
	}
	
	let logQueue = DispatchQueue(label: "dev.crystall1ne.Labradorite.loggingQueue")
	
	func log(_ group: String, _ format: String, _ args: CVarArg..., sync: Bool? = false) {
		guard let sync = sync else { return }
		let msg = String(format: format, arguments: args)
		if !terminal.arguments.shouldBeInteractive || sync {
			terminal.logToRawTerminal(group, msg, prompt: terminal.interactivity.prompt, buffer: terminal.interactivity.buffer)
		} else {
			terminal.queue.async { [self] in
				terminal.logToRawTerminal(group, msg, prompt: terminal.interactivity.prompt, buffer: terminal.interactivity.buffer)
				terminal.repaint(prompt: terminal.interactivity.prompt, buffer: terminal.interactivity.buffer)
			}
		}
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
