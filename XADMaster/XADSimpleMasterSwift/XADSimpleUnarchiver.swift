//
//  XADSimpleUnarchiver.swift
//  XADMaster
//
//  Created by C.W. Betts on 4/20/17.
//
//

import Foundation
import XADMaster.Unarchiver.Simple

extension XADSimpleUnarchiver {
	@nonobjc public func parse() throws {
		let err = __parse()
		if err != .none {
			throw XADError(err)
		}
	}
	
	@nonobjc public func unarchive() throws {
		let err = __unarchive()
		if err != .none {
			throw XADError(err)
		}
	}
}
