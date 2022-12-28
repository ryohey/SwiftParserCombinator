//
//  ParseError.swift
//  
//
//  Created by Ryohei Kameyama on 2022/12/22.
//

import Foundation

public struct ParseError: LocalizedError {
    public let message: String
    
    public init(message: String) {
        self.message = message
    }

    public var errorDescription: String? {
        message
    }
}
