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
		case helpShown(String, Int32)
		case missingValue(String, Int32)
	}

	final class Arguments {
		private let arguments = CommandLine.arguments
		private var index = 1
		
		public var dataPath: String?
		public var safetyOff = false
		public var shouldUseColors = true
		public var shouldBeInteractive = false
		public private(set) var issues: [ArgumentIssue] = []
		
		public init() {}
		
		public func parse() {
			while index < arguments.count {
				let arg = arguments[index]
				switch arg {
				case "--disable-safety":
					safetyOff = true
				case "--data", "-d":
					dataPath = parseMultiPartStringArgument()
					if dataPath == nil { issues.append(.missingValue(arg, 1)) }
				case "--help", "-h":
					returnServerHelp()
					issues.append(.helpShown(arg, 0))
				case "--no-colors":
					shouldUseColors = false
				case "--interactive":
					shouldBeInteractive = true
				default:
					issues.append(.unknown(arg, 1))
				}
				index += 1
			}
		}
		
		public func parseMultiPartStringArgument() -> String? {
			let secondIndex = index + 1
			guard secondIndex < arguments.count, !arguments[secondIndex].hasPrefix("-") else { return nil }
			guard FileManager.default.fileExists(atPath: arguments[secondIndex], isDirectory: nil) else { return nil }
			
			index += 1
			return arguments[secondIndex].hasSuffix("/") ? arguments[secondIndex] : (arguments[secondIndex] + "/")
		}
		
		public func returnServerHelp() {
			let help = """
			 Available command-line arguments:
			 
			 --data, -d [path]            - Specify a custom directory for devices and mappings.
			 --no-colors                  - Disables color output.
			 --interactive                - Enables terminal console.
			 
			 Available server endpoints (in order of accuracy):
			 
			 /api/v0/boardconfig          - Query device specifications with board configuration 
			 /api/v0/identifier           - Query device specifications with identifier
			 /api/v0/model                - Query device specifications with model number (Axxx)
			 """
			
			utilities.log("", help, printPrompt: false)
		}
	}
}
