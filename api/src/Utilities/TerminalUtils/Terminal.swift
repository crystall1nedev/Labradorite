//
//  Terminal.swift
//  labradorite-server
//
//  Created by Eva Isabella Luna on 10/26/25.
//

import Foundation

class Terminal {
	var arguments: Arguments!
	var interactivity: Interactivity!
	
	init() {
		self.arguments = Arguments(parent: self)
		self.interactivity = Interactivity(parent: self)
	}
}
