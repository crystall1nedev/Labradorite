//
//  Arguments.swift
//  labradorite-server
//
//  Created by Eva Isabella Luna on 10/26/25.
//

import Foundation

extension Terminal {
	class Arguments {
		var parent: Terminal!
		
		private let arguments = CommandLine.arguments
		private var index = 1
		public var dataPath: String? = nil
		public var safetyOff: Bool = false
		public var hasHitUnknownArgument: Bool = false
		
		init(parent: Terminal) {
			self.parent = parent
			while index < arguments.count {
				let argument = arguments[index]
				switch argument {
				case "--disable-safety":
					safetyOff = true
				case "--data", "-d":
					dataPath = parseMultiPartStringArgument() ?? nil
				case "--help", "-h":
					returnServerHelp(); exit(0)
				default:
					print("Unknown argument");
					hasHitUnknownArgument = true
				}
				index += 1
			}
			
			if hasHitUnknownArgument && !safetyOff { exit(1) }
		}
		
		func parseMultiPartStringArgument() -> String? {
			let secondIndex = index + 1
			guard secondIndex < arguments.count else {
				print("Missing value for " + arguments[index] + ".")
				exit(1)
			}
			
			guard !arguments[secondIndex].hasPrefix("-") else {
				print("Missing value for " + arguments[index] + ".")
				exit(1)
			}
			
			guard FileManager.default.fileExists(atPath: arguments[secondIndex], isDirectory: nil) else {
				print("Value for " + arguments[index] + " is invalid.")
				exit(1)
			}
			
			index += 1
			return arguments[secondIndex].hasSuffix("/") ? arguments[secondIndex] : (arguments[secondIndex] + "/")
		}
		
		func returnServerHelp() {
			print("Available command line flags:")
			print("")
			print("--data, -d")
			print("  Specify a custom directory for devices and mappings.")
			print("  Defaults to the current directory when not specified.")
			print(" ")
			print("Available endpoints:")
			print("/api/v0/identifier")
			print("  - Returns a JSON based on the provided model identifier (i.e. iPhone17,2)")
			print("  - Rolling release endpoint is available at /api/identifier")
			print("/api/v0/model")
			print("  - Returns a JSON based on the provided model number (i.e. A3084)")
			print("  - Rolling release endpoint is available at /api/model")
			print("/api/v0/boardconfig")
			print("  - Returns a JSON based on the provided boardconfig (i.e. D94AP)")
			print("  - Rolling release endpoint is available at /api/boardconfig")
			print("Notes on endpoints:")
			print("The entire API is under construction.")
			print("  - DO NOT DEPEND ON THE OUTPUT OF THIS API UNTIL /api/v1 ENDPOINTS ARE AVAILABLE.")
			print("  - Many devices and data are missing or corrupted.")
			print("  - The format of each returned JSON is subject to change - minimal or complete.")
			print("All endpoints support drilling. You can supply nested key names to only return those values.")
			print("  - /api/boardconfig/D94AP will return the full json for \"D94AP\".")
			print("  - /api/boardconfig/D94AP/chips/soc will return the value for \"chips.soc\" in the json for \"D94AP\".")
		}
	}
}
