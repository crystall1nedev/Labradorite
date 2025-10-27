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
		
		init() {}
		
		func parse() {
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
		
		func parseMultiPartStringArgument() -> String? {
			let secondIndex = index + 1
			guard secondIndex < arguments.count, !arguments[secondIndex].hasPrefix("-") else { return nil }
			guard FileManager.default.fileExists(atPath: arguments[secondIndex], isDirectory: nil) else { return nil }
			
			index += 1
			return arguments[secondIndex].hasSuffix("/") ? arguments[secondIndex] : (arguments[secondIndex] + "/")
		}
		
		func returnServerHelp() {
			utilities.log("Arguments", "Available command line flags:")
			utilities.log("Arguments", "")
			utilities.log("Arguments", "--data, -d")
			utilities.log("Arguments", "  Specify a custom directory for devices and mappings.")
			utilities.log("Arguments", "  Defaults to the current directory when not specified.")
			utilities.log("Arguments", " ")
			utilities.log("Arguments", "Available endpoints:")
			utilities.log("Arguments", "/api/v0/identifier")
			utilities.log("Arguments", "  - Returns a JSON based on the provided model identifier (i.e. iPhone17,2)")
			utilities.log("Arguments", "  - Rolling release endpoint is available at /api/identifier")
			utilities.log("Arguments", "/api/v0/model")
			utilities.log("Arguments", "  - Returns a JSON based on the provided model number (i.e. A3084)")
			utilities.log("Arguments", "  - Rolling release endpoint is available at /api/model")
			utilities.log("Arguments", "/api/v0/boardconfig")
			utilities.log("Arguments", "  - Returns a JSON based on the provided boardconfig (i.e. D94AP)")
			utilities.log("Arguments", "  - Rolling release endpoint is available at /api/boardconfig")
			utilities.log("Arguments", "Notes on endpoints:")
			utilities.log("Arguments", "The entire API is under construction.")
			utilities.log("Arguments", "  - DO NOT DEPEND ON THE OUTPUT OF THIS API UNTIL /api/v1 ENDPOINTS ARE AVAILABLE.")
			utilities.log("Arguments", "  - Many devices and data are missing or corrupted.")
			utilities.log("Arguments", "  - The format of each returned JSON is subject to change - minimal or complete.")
			utilities.log("Arguments", "All endpoints support drilling. You can supply nested key names to only return those values.")
			utilities.log("Arguments", "  - /api/boardconfig/D94AP will return the full json for \"D94AP\".")
			utilities.log("Arguments", "  - /api/boardconfig/D94AP/chips/soc will return the value for \"chips.soc\" in the json for \"D94AP\".")
		}
	}
}
