//
//  XADArchiveSwift.swift
//  XADMaster
//
//  Created by C.W. Betts on 4/19/17.
//
//

import Foundation
import XADMaster.ArchiveParser

extension XADError: Error {
	public var _domain: String {
		return XADErrorDomain
	}
	
	public var _code: Int {
		return Int(rawValue)
	}
}

extension XADArchiveParser {
	@nonobjc public class func archiveParser(for handle: XADHandle, name: String) throws -> XADArchiveParser {
		var error = XADError.noError
		if let archiveParse = XADArchiveParser(__for: handle, name: name, error: &error) {
			return archiveParse
		}
		throw error
	}
	
	@nonobjc public class func archiveParser(for handle: XADHandle, resourceFork fork: XADResourceFork?, name: String) throws -> XADArchiveParser {
		var error = XADError.noError
		if let archiveParse = XADArchiveParser(__for: handle, resourceFork: fork, name: name, error: &error) {
			return archiveParse
		}
		throw error
	}

	@nonobjc public class func archiveParser(for handle: XADHandle, firstBytes header: Data, name: String) throws -> XADArchiveParser {
		var error = XADError.noError
		if let archiveParse = XADArchiveParser(__for: handle, firstBytes: header, name: name, error: &error) {
			return archiveParse
		}
		throw error
	}
	
	@nonobjc public class func archiveParser(for handle: XADHandle, firstBytes header: Data, resourceFork fork: XADResourceFork?, name: String) throws -> XADArchiveParser {
		var error = XADError.noError
		if let archiveParse = XADArchiveParser(__for: handle, firstBytes: header, resourceFork: fork, name: name, error: &error) {
			return archiveParse
		}
		throw error
	}

	@nonobjc public class func archiveParser(forPath filename: String) throws -> XADArchiveParser {
		var error = XADError.noError
		if let archiveParse = XADArchiveParser(__forPath: filename, error: &error) {
			return archiveParse
		}
		throw error
	}
	
	@nonobjc public class func archiveParser(forEntryWith entry: [XADArchiveKeys : Any], archiveParser parser: XADArchiveParser, wantChecksum checksum: Bool) throws -> XADArchiveParser {
		var error = XADError.noError
		if let archiveParse = XADArchiveParser(__forEntryWith: entry, archiveParser: parser, wantChecksum: checksum, error: &error) {
			return archiveParse
		}
		throw error
	}
	
	@nonobjc public class func archiveParser(forEntryWith entry: [XADArchiveKeys : Any], resourceForkDictionary forkentry: [XADArchiveKeys : Any]?, archiveParser parser: XADArchiveParser, wantChecksum checksum: Bool) throws -> XADArchiveParser {
		var error = XADError.noError
		if let archiveParse = XADArchiveParser(__forEntryWith: entry, resourceForkDictionary: forkentry, archiveParser: parser, wantChecksum: checksum, error: &error) {
			return archiveParse
		}
		throw error
	}
}

