//
//  Arguments.swift
//  labradorite-server
//
//  Created by Eva Isabella Luna on 10/26/25.
//

import Foundation

extension Terminal {
	enum ArgumentIssue {
		case unknown(String, Int32)
		case helpShown
		case missingValue(String, Int32)
		case missingPath(String, Int32)
	}

	final class Arguments {
		private let arguments = CommandLine.arguments
		private var index = 1
		
		public var dataPath: String?
		public var safetyOff = false
		public var shouldUseColors = false
		public var shouldLogToConsole = true
		public var shouldBeInteractive = false
		public var shouldEnableHostInfo = false
		public private(set) var issues: [ArgumentIssue] = []
		
		public init() {}
		
		public func parse() {
			while index < arguments.count {
				let arg = arguments[index]
				
				if arg.hasPrefix("-") && !arg.hasPrefix("--") && arg.count > 1 {
					for char in arg.dropFirst() {
						switch char {
						case "S": safetyOff = true
						case "d": dataPath = parseMultiPartStringArgument()
						case "h": returnServerHelp()
						case "C": shouldUseColors = true
						case "q": shouldLogToConsole = false
						case "I": shouldBeInteractive = true
						default: issues.append(.unknown(arg, 1))
						}
					}
				} else {
					switch arg {
					case "--disable-safety": safetyOff = true
					case "--data": dataPath = parseMultiPartStringArgument()
					case "--help": returnServerHelp()
					case "--colors": shouldUseColors = true
					case "--quiet": shouldLogToConsole = false
					case "--interactive": shouldBeInteractive = true
					case "--enable-host-info": shouldEnableHostInfo = true
					default: issues.append(.unknown(arg, 1))
					}
				}
				index += 1
				
				if !shouldLogToConsole { shouldBeInteractive = false; shouldUseColors = false }
			}
		}
		
		public func parseMultiPartStringArgument() -> String? {
			let secondIndex = index + 1
			guard secondIndex < arguments.count, !arguments[secondIndex].hasPrefix("-") else {
				issues.append(.missingValue(arguments[index], 1))
				return nil
			}
			guard FileManager.default.fileExists(atPath: arguments[secondIndex], isDirectory: nil) else {
				issues.append(.missingPath(arguments[secondIndex], 1))
				return nil
			}
			
			index += 1
			return arguments[secondIndex].hasSuffix("/") ? arguments[secondIndex] : (arguments[secondIndex] + "/")
		}
		
		public func returnServerHelp() {
			let help = """
			 Available command-line arguments:
			 
			 --help, -h             - Show this help message and exit
			 --disable-safety, -S   - Disables safeguards for missing files, paths, etc
			 --data, -d [path]      - Specify a custom directory for devices and mappings
			 --no-colors, -C        - Disables color output
			 --interactive, -I      - Enables server console
			 --quiet, -q            - Silences all log output
			 --enable-host-info     - Enables the /host endpoint
			 
			 Available server endpoints (in order of accuracy):
			 
			 /api/v0/boardconfig          - Query device specifications with board configuration 
			 /api/v0/identifier           - Query device specifications with identifier
			 /api/v0/model                - Query device specifications with model number (Axxx)
			 """
			
			utilities.log("", help, printPrompt: false)
			issues.append(.helpShown)
		}
	}
}
