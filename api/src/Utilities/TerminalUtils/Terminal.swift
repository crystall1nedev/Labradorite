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
		self.arguments = Arguments(parent: self)
		self.interactivity = Interactivity(parent: self)
	}
	
	let queue     = DispatchQueue(label: "dev.crystall1ne.Labradorite.TerminalQueue")
	let output    = FileHandle.standardOutput
	let escape    = String(UnicodeScalar(0x1B))
	var original  = termios()
	var lastGroup = ""
	
	let colorMap: [String: String] = [
		"Initialization": "\u{1B}[31m",   // red
		"Request": "\u{1B}[32m",          // green
		"Mappings": "\u{1B}[33m",         // yellow
		"Devices": "\u{1B}[34m",          // blue
		"Arguments": "\u{1B}[35m",        // magenta
		"Console": "\u{1B}[36m",          // cyan
	]
	
	@inline(__always) func writeToRawTerminal(_ string: String) {
		if let data = string.data(using: .utf8) { output.write(data) }
	}
	
	@inline(__always) func flushStdout() { fflush(stdout) }
	
	public func enableRawMode() throws {
		guard tcgetattr(STDIN_FILENO, &original) == 0 else { throw NSError(domain: "termios", code: 1) }
		var raw = original
		raw.c_lflag &= ~(UInt(ECHO) | UInt(ICANON) | UInt(ISIG) | UInt(IEXTEN))
		raw.c_iflag &= ~(UInt(IXON) | UInt(ICRNL) | UInt(INPCK) | UInt(ISTRIP) | UInt(BRKINT))
		raw.c_oflag &= ~(UInt(OPOST))
		raw.c_cc.6 = 1
		raw.c_cc.5 = 0
		guard tcsetattr(STDIN_FILENO, TCSAFLUSH, &raw) == 0 else { throw NSError(domain: "termios", code: 2) }
	}
	
	public func disableRawMode() {
		_ = tcsetattr(STDIN_FILENO, TCSAFLUSH, &original)
	}
	
	public func repaint(prompt: String, buffer: String) {
		writeToRawTerminal(escape + "[0G" + escape + "[2K")
		writeToRawTerminal(prompt + buffer)
		flushStdout()
	}
	
	public func logToRawTerminal(_ group: String, _ msg: String, prompt: String, buffer: String) {
		func parseGroupAndMessage(_ input: String) -> (group: String?, message: String) {
			if let close = input.firstIndex(of: "]"),
			   input.hasPrefix("[") {
				let group = String(input[input.index(after: input.startIndex)..<close])
				let msgStart = input.index(after: close)
				let message = input[msgStart...].trimmingCharacters(in: .whitespaces)
				return (group, message)
			}
			return (nil, input)
		}
		
		let reset = "\u{1B}[0m"
		
		var finalMsg = ""
		var coloredGroup = ""
		if group != "" {
			if arguments.shouldUseColors {
				let color = colorMap[group] ?? "\u{1B}[31m"
				coloredGroup = color + "[\(group)]" + reset
			}
			let padding = max(1, 20 - (group.count + 2))
			let padStr = String(repeating: " ", count: padding)
			finalMsg = (arguments.shouldUseColors ? coloredGroup : "[\(group)]") + padStr + msg
		} else {
			finalMsg = msg
		}
		
		writeToRawTerminal("\r" + escape + "[2K")
		if lastGroup != group { writeToRawTerminal("\n"); lastGroup = group }
		writeToRawTerminal(finalMsg + "\n")
		if arguments.shouldBeInteractive { repaint(prompt: prompt, buffer: buffer) }
	}
}
