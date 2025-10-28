//
//  Handlers.swift
//  Labradorite-Server
//
//  Created by Eva Isabella Luna on 10/18/25.
//

import Foundation
import Network
#if canImport(UIKit)
import UIKit
#endif

extension HTTP {
	class Handlers {
		var parent: HTTP!
		
		init(parent: HTTP) {
			self.parent = parent
		}
		
		func handleHelp(connection: NWConnection) {
			var response = "Welcome to the Labradorite API server.\n"
			response += "Made by Eva with <3 since 2025.\n\n"
			response += "Available endpoints:\n\n"
			response += "/api/v0/identifier\n"
			response += "  - Returns a JSON based on the provided model identifier (i.e. iPhone17,2)\n"
			response += "  - Rolling release endpoint is available at /api/identifier\n"
			response += "/api/v0/model\n"
			response += "  - Returns a JSON based on the provided model number (i.e. A3084)\n"
			response += "  - Rolling release endpoint is available at /api/model\n"
			response += "/api/v0/boardconfig\n"
			response += "  - Returns a JSON based on the provided boardconfig (i.e. D94AP)\n"
			response += "  - Rolling release endpoint is available at /api/boardconfig\n\n"
			response += "Notes on endpoints:\n\n"
			response += "The entire API is under construction.\n"
			response += "  - DO NOT DEPEND ON THE OUTPUT OF THIS API UNTIL /api/v1 ENDPOINTS ARE AVAILABLE.\n"
			response += "  - Many devices and data are missing or corrupted.\n"
			response += "  - The format of each returned JSON is subject to change - minimal or complete.\n"
			response += "All endpoints support drilling. You can supply nested key names to only return those values.\n"
			response += "  - /api/boardconfig/D94AP will return the full json for \"D94AP\".\n"
			response += "  - /api/boardconfig/D94AP/chips/soc will return the value for \"chips.soc\" in the json for \"D94AP\".\n"
			
			let body = Data(response.utf8)
			parent.respondHeadersAndBody(connection: connection, status: 200, body: body)
		}
		
		func handleCow(connection: NWConnection) {
			let body = Data("moo".utf8)
			parent.respondHeadersAndBody(connection: connection, status: 418, body: body)
		}
		
		func handleDefault(connection: NWConnection) {
			let body = Data(badEndpoint.utf8)
			parent.respondHeadersAndBody(connection: connection, status: 400, body: body)
		}
		
		func handleHost(connection: NWConnection) {
			#if os(Windows)
				let host = "Windows"
			#elseif os(Linux)
				let host = "Linux"
			#elseif os(iOS) || os(tvOS)
				let host = UIDevice.current.systemName
			#elseif os(macOS)
				let host = "macOS"
			#endif
			let body = Data("""
				{
					"server_version": 1.0,
					"server_host": "\(host)"
				}
				""".utf8)
			parent.respondHeadersAndBody(connection: connection, status: 200, body: body)
		}
	}
}
