//
//  Utilities+HTTP.swift
//  Labradorite-Server
//
//  Created by Eva Isabella Luna on 10/18/25.
//

import Foundation
import Network

class HTTP {
	var handlers: Handlers!
	
	init() {
		self.handlers = Handlers(parent: self)
	}
	
	func respondHeadersAndBody(connection: NWConnection, status: Int = 200, headers: [String: String] = [:], body: Data = Data()) {
		var headerLines = "HTTP/1.0 \(status) \(statusDescription(status))\r\n"
		headerLines += "Content-Length: \(body.count)\r\n"
		headerLines += "Content-Type: application/json\r\n"
		headerLines += "Cow: true\r\n"
		for (k,v) in headers {
			headerLines += "\(k): \(v)\r\n"
		}
		headerLines += "\r\n"
		let headerData = headerLines.data(using: .utf8) ?? Data()
		connection.send(content: headerData + body, completion: .contentProcessed({ _ in
			connection.cancel()
		}))
	}
	
	func statusDescription(_ status: Int) -> String {
		switch status {
		case 200: return "OK"
		case 400: return "Bad Request"
		case 404: return "Not Found"
		case 405: return "Method Not Allowed"
		case 418: return "I'm a teapot"
		case 500: return "Internal Server Error"
		default: return "Status"
		}
	}
	
	func clientIP(from connection: NWConnection, request: HTTP.ParsedRequest?) -> String {
		if let request {
			if let xForwardedFor = request.headers["X-Forwarded-For"] {
				let parts = xForwardedFor.split(separator: ",")
				if let firstIP = parts.first {
					return firstIP.trimmingCharacters(in: .whitespaces)
				}
			}
			
			if let xRealIP = request.headers["X-Real-IP"] {
				return xRealIP
			}
		}
		
		if let endpoint = connection.currentPath?.remoteEndpoint {
			switch endpoint {
			case .hostPort(let host, let port):
				return "\(host.debugDescription):\(port.debugDescription)"
			default:
				return "\(endpoint)"
			}
		}
		
		return "unknown"
	}
	
	struct ParsedRequest {
		let method: String
		let path: String
		let headers: [String: String]
	}
	
	func parseHTTPRequest(_ data: Data) -> ParsedRequest? {
		guard let raw = String(data: data, encoding: .utf8) else { return nil }
		let lines = raw.components(separatedBy: "\r\n")
		guard lines.count > 0 else { return nil }
		let requestLineParts = lines[0].split(separator: " ")
		guard requestLineParts.count >= 2 else { return nil }
		let method = String(requestLineParts[0])
		let path = String(requestLineParts[1])
		var headers: [String: String] = [:]
		for i in 1..<lines.count {
			let line = lines[i]
			if line.isEmpty { break }
			if let colonRange = line.range(of: ":") {
				let key = String(line[..<colonRange.lowerBound]).trimmingCharacters(in: .whitespaces)
				let value = String(line[colonRange.upperBound...]).trimmingCharacters(in: .whitespaces)
				headers[key] = value
			}
		}
		return ParsedRequest(method: method, path: path, headers: headers)
	}
}
