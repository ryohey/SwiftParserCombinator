//
//  ParseError.swift
//  
//
//  Created by Ryohei Kameyama on 2022/12/22.
//

import Foundation

public struct ParseError: LocalizedError {
    public let context: Context
    public let message: String

    public init(context: Context, message: String) {
        self.context = context
        self.message = message
    }

    public var errorDescription: String? {
        let stack = context.callStack
            .map { "- \($0.name)() \($0.value)" }
            .joined(separator: "\n")

        return """
            \(message)

            [Call stack]
            \(stack)
            """
    }
}
