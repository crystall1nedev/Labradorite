//
//  Interactivity.swift
//  labradorite-server
//
//  Created by Eva Isabella Luna on 10/26/25.
//

import Foundation

extension Terminal {
	class Interactivity {
		var parent: Terminal!
		
		init(parent: Terminal) { self.parent = parent }
		
		public func runInteractiveLoop() {
			fflush(stdout)
			
			while let line = readLine() {
				parseTerminalCommands(line)
			}
		}
		
		public func parseTerminalCommands(_ buffer: String) {
			print("\u{001B}[1A\u{001B}[2K\r", terminator: "")
			switch buffer {
			case _ where buffer.starts(with: "test"):
				utilities.log("Console", "Running test")
				returnTestResults(buffer)
			case "reload":
				utilities.log("Console", "Reloading mappings and devices in memory...")
				loadIntoMemory()
			case "exit":
				utilities.log("Console", "Goodbye!", printPrompt: false)
				exit(0)
			case "help": returnServerCommandsHelp()
			default:
				utilities.log("Console", "Unknown command: \(buffer). Type \"help\" for a list.")
			}
		}
		
		public func returnServerCommandsHelp() {
			utilities.log("Console", "", printPrompt: false)
			utilities.log("Console", "Available console commands:", printPrompt: false)
			utilities.log("Console", "", printPrompt: false)
			utilities.log("Console", "help                   - Show this help message.", printPrompt: false)
			utilities.log("Console", "reload                 - Reloads mappings and devices currently stored in memory from disk.", printPrompt: false)
			utilities.log("Console", "exit                   - Shuts down Labradorite Server.", printPrompt: false)
			utilities.log("Console", "test /endpoint/device  - Tests server responses for /endpoint/device")
		}
		
		public func returnTestResults(_ buffer: String) {
			var command = [ ] as [String]
			for str in buffer.split(separator: " ") { command.append(String(str)) }
			
			if command.count == 1 {
				utilities.log("Console", "This command requires requesting a device.")
			} else {
				utilities.device.serveDevice(path: command.last ?? "", headers: [:], console: true)
			}
		}
	}
}
