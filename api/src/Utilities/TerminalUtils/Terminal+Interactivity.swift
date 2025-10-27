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
		
		var buffer    = ""
		var prompt    = "> "
		
		public func runInteractiveLoop() {
			do {
				try parent.enableRawMode()
			} catch {
				exit(1)
			}
			
			defer {
				parent.disableRawMode()
				parent.queue.sync {
					running = false
					parent.writeToRawTerminal("\r" + parent.escape + "[2K")
					parent.writeToRawTerminal("Shutting down Labradorite cleanly.\n")
					exit(0)
				}
			}
			
			parent.queue.sync {
				parent.repaint(prompt: prompt, buffer: buffer)
			}
			
			let fd = STDIN_FILENO
			var inbuf = [UInt8](repeating: 0, count: 1)
			
			while running {
				let line = read(fd, &inbuf, 1)
				if line <= 0 { break }
				
				let char = inbuf[0]
				
				parent.queue.sync {
					switch char {
					case 3:
						running = false
					case 10, 13:
						if !buffer.isEmpty {
							parent.writeToRawTerminal("\r" + parent.escape + "[2K")
							parseTerminalCommands(buffer)
							buffer = ""
							parent.repaint(prompt: prompt, buffer: buffer)
						}
					case 127:
						if !buffer.isEmpty {
							buffer.removeLast()
							parent.repaint(prompt: prompt, buffer: buffer)
						}
					default:
						if char >= 32, char <= 126 {
							buffer.append(Character(UnicodeScalar(char)))
							parent.repaint(prompt: prompt, buffer: buffer)
						}
					}
				}
			}
		}
		
		public func parseTerminalCommands(_ buffer: String) {
			switch buffer {
			//case _ where buffer.starts(with: "test"):
			//	utilities.log("Console", "Running test")
			//	returnTestResults(buffer)
			case "reload":
				utilities.log("Console", "Reloading mappings and devices in memory...")
				loadIntoMemory()
			case "exit": running = false
			case "help": returnServerCommandsHelp()
			default:
				parent.writeToRawTerminal("\r" + parent.escape + "[2K")
				utilities.log("Console", "Unknown command: \(buffer). Type \"help\" for a list.")
			}
		}
		
		public func returnServerCommandsHelp() {
			utilities.log("Console", "help   - Show this help message.")
			utilities.log("Console", "reload - Reloads mappings and devices currently stored in memory from disk.")
			utilities.log("Console", "exit   - Shuts down Labradorite Server.")
			utilities.log("Console", "test   - implement test command wen")
		}
		
		/*public func returnTestResults(_ buffer: String) {
			utilities.log("Console", "Not implemented yet :(")
			var command = [ ] as [String]
			for str in buffer.split(separator: " ") { command.append(String(str)) }
			utilities.log("Console", "Command: \(command)")
		}*/
	}
}
