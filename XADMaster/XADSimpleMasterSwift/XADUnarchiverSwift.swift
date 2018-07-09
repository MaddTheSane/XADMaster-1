//
//  XADUnarchiverSwift.swift
//  XADMaster
//
//  Created by C.W. Betts on 4/19/17.
//
//

import Foundation
import XADMaster.Unarchiver

extension XADUnarchiver {
	@nonobjc public func parseAndUnarchive() throws {
		let error = __parseAndUnarchive()
		if error != .none {
			throw XADError(error)
		}
	}
}
