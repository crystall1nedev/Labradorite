//
//  Terminal.swift
//  labradorite-server
//
//  Created by Eva Isabella Luna on 10/26/25.
//

import Foundation

class Terminal {
	var arguments: Arguments!
	var interactivity: Interactivity!
	
	init() {
		self.arguments = Arguments()
		self.interactivity = Interactivity(parent: self)
	}
	
	let queue     = DispatchQueue(label: "dev.crystall1ne.Labradorite.TerminalQueue")
	let output    = FileHandle.standardOutput
	let escape    = String(UnicodeScalar(0x1B))
	
	let prompt    = "> "
	
	let colorMap: [String: String] = [
		"Initialization": "\u{1B}[31m",   // red
		"Request": "\u{1B}[32m",          // green
		"Mappings": "\u{1B}[33m",         // yellow
		"Devices": "\u{1B}[34m",          // blue
		"Arguments": "\u{1B}[35m",        // magenta
		"Console": "\u{1B}[36m",          // cyan
	]
	
	@inline(__always) func flushStdout() { fflush(stdout) }
	
	public func logToRawTerminal(_ group: String, _ msg: String, _ shouldPrintPrompt: Bool) {
		func formatGroup(_ group: String) -> String {
			guard arguments.shouldUseColors else { return "[\(group)]" }
			let color = colorMap[group] ?? "\u{1B}[31m"
			return color + "[\(group)]\u{1B}[0m"
		}

		var finalMsg: String
		if !group.isEmpty {
			let padding = max(1, 20 - (group.count + 2))
			let padStr = String(repeating: " ", count: padding)
			finalMsg = formatGroup(group) + padStr + msg
		} else {
			finalMsg = msg
		}
		
		if arguments.shouldBeInteractive { print("\u{001B}[2K\r", terminator: "") }
		if arguments.shouldLogToConsole { print(finalMsg) }
		if arguments.shouldBeInteractive && shouldPrintPrompt { print(prompt, terminator: "") }
		flushStdout()
	}

}
