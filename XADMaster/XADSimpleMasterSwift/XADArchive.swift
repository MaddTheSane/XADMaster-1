//
//  XADArchive.swift
//  XADMaster
//
//  Created by C.W. Betts on 4/19/17.
//
//

import Foundation
import XADMaster.Exception
import XADMaster.XADArchive

extension XADArchive {
	@nonobjc open var nameEncoding: String.Encoding {
		get {
			return String.Encoding(rawValue: __nameEncoding)
		}
		set {
			__nameEncoding = newValue.rawValue
		}
	}
	
	@nonobjc open func contents(ofEntry n: Int) throws -> Data {
		guard let dat = __contents(ofEntry: n) else {
			throw XADError(lastError)
		}
		return dat
	}
}
