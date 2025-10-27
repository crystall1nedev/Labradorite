//
//  Interactivity.swift
//  labradorite-server
//
//  Created by Eva Isabella Luna on 10/26/25.
//

import Foundation
import Darwin
import Dispatch

extension Terminal {
	class Interactivity {
		var parent: Terminal!
		
		init(parent: Terminal) { self.parent = parent }
		
		let termQueue = DispatchQueue(label: "dev.crystall1ne.Labradorite.TerminalQueue")		
		var currentInput = ""
		var prompt       = "> "
		
		public func runInteractiveLoop() {
			
		}
	}
}
