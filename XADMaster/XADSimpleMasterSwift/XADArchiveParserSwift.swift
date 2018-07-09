//
//  XADArchiveSwift.swift
//  XADMaster
//
//  Created by C.W. Betts on 4/19/17.
//
//

import Foundation
import XADMaster.ArchiveParser
import XADMaster.Exception

extension XADPath {
	@available(*, deprecated, renamed: "sanitizedPathString(with:)")
	open func sanitizedPathString(withEncoding encoding: String.Encoding) -> String {
		return __sanitizedPathString(withEncoding: encoding.rawValue)
	}
	
	open func sanitizedPathString(with encoding: String.Encoding) -> String {
		return __sanitizedPathString(withEncoding: encoding.rawValue)
	}

}

extension XADError: CustomStringConvertible {
	public var description: String {
		if let errDesc = XADDescribeError(code) {
			return errDesc
		}
		if self == .none {
			return "No Error"
		}
		return "Unknown error \(code.rawValue)"
	}
}

extension XADArchiveParser {
	/// - returns: `true` if the checksum is valid,
	/// `false` otherwise.
	/// Throws if there was a failure.
	@nonobjc open func testChecksum() throws -> Bool {
		let err = __testChecksumWithoutExceptions()
		switch err {
		case .checksum:
			return false
			
		case .none:
			return true
			
		default:
			throw XADError(err)
		}
	}
	
	open func reportInterestingFile(withReason reason: String, _ args: [CVarArg]) {
		withVaList(args) { (valist) -> Void in
			reportInterestingFile(withReason: reason, format: valist)
		}
	}
	
	@available(*, deprecated, renamed: "testChecksum()")
	@nonobjc open func testChecksumWithoutExceptions() throws {
		if try testChecksum() == false {
			// match the Objective-C method's behavior
			throw XADError(.checksum)
		}
	}
	
	@available(*, deprecated, renamed: "parse()")
	@nonobjc open func parseWithoutExceptions() throws {
		try parse()
	}
}
