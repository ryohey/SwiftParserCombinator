//
//  ParseError.swift
//  
//
//  Created by Ryohei Kameyama on 2022/12/22.
//

import Foundation

public struct ParseError: LocalizedError {
    let context: Context
    let message: String

    public var errorDescription: String? {
        let stack = context.callStack
            .map { "- \($0.name)" }
            .joined(separator: "\n")

        return """
            \(message)
            
            [Call stack]
            \(stack)
            """
    }
}
