import XCTest
@testable import SwiftParserCombinator

indirect enum JSONValue: Equatable {
    case string(String)
    case number(Double)
    case object([(String, JSONValue)])
}

func ==(lhs: JSONValue, rhs: JSONValue) -> Bool {
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

final class SwiftParserCombinatorTests: XCTestCase {
    override func setUpWithError() throws {
        logger = { print($0) }
    }
    
    func testHexColor() throws {
        let hash = char("#")
        let hex = charRange("0", "9") | charRange("a", "f")
        let component = map(hex + hex, { (tuple: (String, String)) -> Int in
            let str = tuple.0 + tuple.1
            var rgbValue: UInt64 = 0
            Scanner(string: str).scanHexInt64(&rgbValue)
            return Int(rgbValue)
        })
        let r = component
        let g = component
        let b = component
        let colorParser = map(hash + r + g + b, { (r: $1, g: $2, b: $3) })
        let input = Iterated(value: "#ff6400")
        let result = try colorParser(input)
        XCTAssertEqual(result.value.r, 255)
        XCTAssertEqual(result.value.g, 100)
        XCTAssertEqual(result.value.b, 0)
        XCTAssertEqual(result.position, 7)
        XCTAssertThrowsError(try colorParser(Iterated(value: "#ff400")))
        XCTAssertThrowsError(try colorParser(Iterated(value: "#ff400_")))
        XCTAssertThrowsError(try colorParser(Iterated(value: "ff4000")))
    }
    
    func testJSON() throws {
        let space = ignore(optional(many(char(" ") | char("\n"))))
        
        let string = join(map(char("\"") + many(any() & !char("\"")) + char("\""), { $0.1 }))
        XCTAssertEqual(try string(Iterated(value: "\"hello\"")).value, "hello")
        
        let number = map(join(many(charRange("0", "9") | char("."))), { Double($0)! })
        XCTAssertEqual(try number(Iterated(value: "123.4")).value, 123.4)
        
        let stringValue: Parser<String, JSONValue> = map(string, { JSONValue.string($0) })
        let numberValue: Parser<String, JSONValue> = map(number, { JSONValue.number($0) })
        var objectParser: Parser<String, [(String, JSONValue)]>!
        let objectValue: Parser<String, JSONValue> = lazy(map(objectParser, { JSONValue.object($0) }))
        let value: Parser<String, JSONValue> = stringValue | numberValue | objectValue
        
        let separator = ignore(space + pass(char(":") + space))
        let keyValue = map(string + separator + value, { ($0, $1) })
        
        let singleKeyValue: Parser<String, [(String, JSONValue)]> = map(keyValue, { [$0] })
        let lineSeparator = ignore(space + pass(char(",") + space))
        let manyKeyValue: Parser<String, [(String, JSONValue)]> = map(many(keyValue + lineSeparator) + keyValue, { $0 + [$1] })

        objectParser = pass(ignore(char("{") + space) + pass(manyKeyValue | singleKeyValue) + ignore(space + char("}")))
        
        do {
            let result = try keyValue(Iterated(value: "\"foo\": \"hi\"")).value
            XCTAssertEqual(result.0, "foo")
            XCTAssertEqual(result.1, .string("hi"))
        }

        do {
            let result = try keyValue(Iterated(value: "\"bar\": 3.141")).value
            XCTAssertEqual(result.0, "bar")
            XCTAssertEqual(result.1, .number(3.141))
        }

        do {
            let input = Iterated(value: "{ \"name\": \"mokha\", \"age\": 10}")
            let result = try objectValue(input)
            XCTAssertEqual(result.value, .object([("name", .string("mokha")),
                                                  ("age", .number(10))]))
        }
        
        do {
            let input = Iterated(value: "{ \"user\": { \"name\": \"mokha\", \"age\": 10} }")
            let result = try objectValue(input)
            XCTAssertEqual(result.value, .object([("user", .object([("name", .string("mokha")),
                                                                    ("age", .number(10))]))]))
        }
        
        let jsonParser: Parser<String, [(String, JSONValue)]> = objectParser + ignore(eof())
        
        do {
            let input = Iterated(value: "{ \"user\": { \"name\": \"mokha\", \"age\": 10} }")
            let result = try jsonParser(input)
            XCTAssertEqual(result.value[0].0, "user")
            XCTAssertEqual(result.value[0].1, .object([("name", .string("mokha")),
                                                       ("age", .number(10))]))
        }
    }

    static var allTests = [
        ("testHexColor", testHexColor),
    ]
}
