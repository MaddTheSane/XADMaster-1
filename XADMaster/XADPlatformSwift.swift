//
//  XADPlatformSwift.swift
//  XADMaster
//
//  Created by C.W. Betts on 4/19/17.
//
//

import Foundation

extension XADPlatform {
	@nonobjc public class func extractResourceForkEntry(with dict: [XADArchiveKeys : Any], unarchiver: XADUnarchiver, toPath destpath: String) throws {
		let err = __extractResourceForkEntry(with: dict, unarchiver: unarchiver, toPath: destpath)
		if err != .none {
			throw XADError(err)
		}
	}
	
	@nonobjc public class func updateFileAttributes(atPath path: String, forEntryWith dict: [XADArchiveKeys : Any], parser: XADArchiveParser, preservePermissions preservepermissions: Bool) throws {
		let err = __updateFileAttributes(atPath: path, forEntryWith: dict, parser: parser, preservePermissions: preservepermissions)
		if err != .none {
			throw XADError(err)
		}
	}
	
	@nonobjc public class func createLink(atPath path: String, withDestinationPath link: String) throws {
		let err = __createLink(atPath: path, withDestinationPath: link)
		if err != .none {
			throw XADError(err)
		}
	}
}
