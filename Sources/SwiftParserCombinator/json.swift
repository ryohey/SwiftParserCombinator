//
//  File.swift
//  
//
//  Created by Ryohei Kameyama on 2021/03/17.
//

import Foundation

public indirect enum JSONValue: Equatable {
    case string(String)
    case number(Double)
    case object([(String, JSONValue)])
}

public func ==(lhs: JSONValue, rhs: JSONValue) -> Bool {
    switch lhs {
    case .string(let a):
        switch rhs {
        case .string(let b):
            return a == b
        default:
            return false
        }
    case .number(let a):
        switch rhs {
        case .number(let b):
            return a == b
        default:
            return false
        }
    case .object(let a):
        switch rhs {
        case .object(let b):
            return a.count == b.count && a.indices.allSatisfy {
                a[$0].0 == b[$0].0
                    && a[$0].1 == b[$0].1
            }
        default:
            return false
        }
    }
}

let space = ignore(optional(many(char(" ") | char("\n"))))

let string = join((char("\"") + many(anyChar() & !char("\"")) + char("\"")).map { $0.1 })
let number = join(many(charRange("0", "9") | char("."))).map { Double($0)! }

let stringValue = string.map(JSONValue.string)
let numberValue = number.map(JSONValue.number)

let objectParser = lazy(ignore(char("{") + space) + pass(manyKeyValue | singleKeyValue) + ignore(space + char("}")))
let objectValue = objectParser.map(JSONValue.object)

let value = stringValue | numberValue | objectValue

let separator = ignore(space + pass(char(":") + space))
let keyValue = (string + separator + value).map { ($0, $1) }

let singleKeyValue: Parser<String, [(String, JSONValue)]> = keyValue.map { [$0] }
let lineSeparator = ignore(space + pass(char(",") + space))
let manyKeyValue: Parser<String, [(String, JSONValue)]> = (many(keyValue + lineSeparator) + keyValue).map { $0 + [$1] }

public let jsonParser: Parser<String, [(String, JSONValue)]> = objectParser + ignore(eof())
