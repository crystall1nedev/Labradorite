//
//  Utilities+Memory.swift
//  Labradorite-Server
//
//  Created by Eva Isabella Luna on 10/18/25.
//

import Foundation

extension Device {
	class Memory {
		var parent: Device!
		
		init(parent: Device) {
			self.parent = parent
		}
		
		func loadMappingsIntoMemory() -> Bool {
			for key in Array(mappings.keys) {
				let mappingPath = NSString.path(withComponents: [utilities.terminal.arguments.dataPath ?? "", "mappings", "\(key)s.json"])
				if !FileManager.default.fileExists(atPath: mappingPath) {
					utilities.log("Mappings", "Mapping file \(mappingPath) is not present! Stopping server...", )
					return false
				}
				utilities.log("Mappings", "Loading the \(key) mapping file from \(mappingPath)")
				do {
					let raw = try utilities.json.loadJSON(at: mappingPath)
					guard let parsed = raw as? [String: Any] else {
						utilities.log("Mappings", "Mapping file \(mappingPath) is not loadable! Stopping server...")
						return false
					}
					mappings[key] = parsed
					utilities.log("Mappings", "Parsed the \(key) mapping file successfully.")
				} catch {
					utilities.log("Mappings", "Mapping file \(mappingPath) is not loadable! Stopping server...")
					return false
				}
			}
			return true
		}
		
		func loadDeviceJSONsIntoMemory() -> Bool {
			for dict in mappings.keys {
				guard let mapping = mappings[dict] else { return false }
				for (key, val) in mapping {
					guard let valStr = val as? String else { return false }
					var pathToJson = [utilities.terminal.arguments.dataPath ?? ""]
					for str in valStr.split(separator: "/") { pathToJson.append(String(str)) }
					let filePath = NSString.path(withComponents: pathToJson)
					if !FileManager.default.fileExists(atPath: filePath) {
						utilities.log("Request", "Unable to locate \(filePath)")
						return false
					}
					do {
						let data = try utilities.json.loadJSON(at: filePath)
						switch dict {
						case "boardconfig": boardconfigDevices[key] = data
						case "model": modelDevices[key] = data
						case "identifier": identifierDevices[key] = data
						default: break
						}
					} catch {
						utilities.log("Request", "Unable to parse the JSON at \(filePath) \(String(describing: error))")
						return false
					}
				}
			}
			return true
		}
	}
}
