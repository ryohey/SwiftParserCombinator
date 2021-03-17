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

let string = join(map(char("\"") + many(any() & !char("\"")) + char("\""), { $0.1 }))
let number = map(join(many(charRange("0", "9") | char("."))), { Double($0)! })

let stringValue = map(string, { JSONValue.string($0) })
let numberValue = map(number, { JSONValue.number($0) })

let objectParser = lazy(ignore(char("{") + space) + pass(manyKeyValue | singleKeyValue) + ignore(space + char("}")))
let objectValue = map(objectParser, { JSONValue.object($0) })

let value = stringValue | numberValue | objectValue

let separator = ignore(space + pass(char(":") + space))
let keyValue = map(string + separator + value, { ($0, $1) })

let singleKeyValue: Parser<String, [(String, JSONValue)]> = map(keyValue, { [$0] })
let lineSeparator = ignore(space + pass(char(",") + space))
let manyKeyValue: Parser<String, [(String, JSONValue)]> = map(many(keyValue + lineSeparator) + keyValue, { $0 + [$1] })

public let jsonParser: Parser<String, [(String, JSONValue)]> = objectParser + ignore(eof())
