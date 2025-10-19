//
//  Utilities+JSON.swift
//  Labradorite-Server
//
//  Created by Eva Isabella Luna on 10/18/25.
//

import Foundation

extension Utilities {
	class JSON {
		var parent: Utilities
		
		init(parent: Utilities) { self.parent = parent }
		
		func loadJSON(at path: String) throws -> Any {
			let url = URL(fileURLWithPath: path)
			let data = try Data(contentsOf: url)
			return try JSONSerialization.jsonObject(with: data, options: .mutableContainers)
		}
		
		func jsonData(from obj: Any) -> Data? {
			guard JSONSerialization.isValidJSONObject(obj) || obj is String || obj is NSNumber || obj is NSArray || obj is NSDictionary else {
				if let s = obj as? String { return "\"\(s)\"".data(using: .utf8) }
				return nil
			}
			return try? JSONSerialization.data(withJSONObject: obj, options: [])
		}
		
		func parseDeviceJSON(subkeys: [String], data: Any, headers: [String: String]) -> Data? {
			parent.log("[Request] Checking if we need to drill down further")
			var current = data
			
			for (i, key) in subkeys.enumerated() {
				parent.log("[Request] Drilling down farther")
				guard let dictionary = current as? [String: Any] else {
					// Nested parsing failed
					parent.log("[Request] Unable to parse the JSON at nested level (not a dictionary).")
					return nil
				}
				parent.log("[Request] Attempting to get value for \"%@\"", key)
				guard let val = dictionary[key] else {
					// Key not found
					parent.log("[Request] Unable to find key \"%@\"", key)
					return nil
				}
				parent.log("[Request] Value retrieved, continuing.")
				current = val
				
				if !(current is [String: Any]) {
					parent.log("[Request] Can't go any farther as we've hit a non-dictionary item.")
					if i != subkeys.count - 1 {
						let headerValue = headers["Labradorite-FailOnSubkeys"] ?? ""
						parent.log("[Request] Non-dictionary item is not at end of requested keys.")
						if headerValue != "true" {
							parent.log("[Request] Ignoring error due to header.")
						} else {
							parent.log("[Request] Header requested strict failure on subkeys.")
							return nil
						}
					}
					break
				}
			}
			
			parent.log("[Request] Remarshalling...")
			if let finalData = jsonData(from: current) {
				return finalData
			} else {
				parent.log("[Request] Unable to marshal the JSON")
				return nil
			}
		}
	}
}
