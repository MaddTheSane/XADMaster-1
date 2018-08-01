//
//  XADHandle.swift
//  XADMaster
//
//  Created by C.W. Betts on 8/1/18.
//

import Foundation
import XADMaster.Handle

extension XADHandle {
	public func readLine(with encoding: String.Encoding) -> String? {
		return __readLine(withEncoding: encoding.rawValue)
	}
}
