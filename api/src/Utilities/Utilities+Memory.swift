//
//  Utilities+Memory.swift
//  Labradorite-Server
//
//  Created by Eva Isabella Luna on 10/18/25.
//

import Foundation

extension Utilities {
	class Memory {
		var parent: Utilities
		
		init(parent: Utilities) { self.parent = parent }
		
		func loadMappingsIntoMemory() -> Bool {
			for key in Array(mappings.keys) {
				let mappingPath = "mappings/\(key)s.json"
				if !FileManager.default.fileExists(atPath: mappingPath) {
					parent.log("[Mappings] Mapping file \"%@\" is not present! Stopping server...", mappingPath)
					return false
				}
				parent.log("[Mappings] Loading the %@ mapping file from \"%@\"", key, mappingPath)
				do {
					let raw = try parent.json.loadJSON(at: mappingPath)
					guard let parsed = raw as? [String: Any] else {
						parent.log("[Mappings] Mapping file \"%@\" is not loadable! Stopping server...", mappingPath)
						return false
					}
					mappings[key] = parsed
					parent.log("[Mappings] Parsed the %@ mapping file successfully.", key)
				} catch {
					parent.log("[Mappings] Mapping file \"%@\" is not loadable! Stopping server... (%@)", mappingPath, String(describing: error))
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
					let filePath = valStr
					if !FileManager.default.fileExists(atPath: filePath) {
						parent.log("[Request] Unable to locate \"%@\"", filePath)
						return false
					}
					do {
						let data = try parent.json.loadJSON(at: filePath)
						switch dict {
						case "boardconfig": boardconfigDevices[key] = data
						case "model": modelDevices[key] = data
						case "identifier": identifierDevices[key] = data
						default: break
						}
					} catch {
						parent.log("[Request] Unable to parse the JSON at \"%@\" (%@)", filePath, String(describing: error))
						return false
					}
				}
			}
			return true
		}
	}
}
