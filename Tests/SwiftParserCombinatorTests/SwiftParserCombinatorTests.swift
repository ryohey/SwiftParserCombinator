import XCTest
@testable import SwiftParserCombinator

final class SwiftParserCombinatorTests: XCTestCase {
    let logger = { print($0) }

    func testOperators() throws {
        let start = string("hello")
        let anyStr = many(anyChar() & !char("!")).joined()
        let suffix = string("!")
        let parser = prefix(start + char(" "), anyStr).suffix(suffix)
        let result = try parser(.init(value: "hello world!", context: Context(logger: logger)))
        XCTAssertEqual(result.value, "world")
        XCTAssertEqual(result.position, 12)
    }
    
    func testHexColor() throws {
        let hash = char("#")
        let hex = charRange("0", "9") | charRange("a", "f")
        let component = (hex + hex).map { (tuple: (String, String)) -> Int in
            let str = tuple.0 + tuple.1
            var rgbValue: UInt64 = 0
            Scanner(string: str).scanHexInt64(&rgbValue)
            return Int(rgbValue)
        }
        let r = component
        let g = component
        let b = component
        let colorParser = (hash + r + g + b).map { (r: $1, g: $2, b: $3) }
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
        XCTAssertEqual(try string(Iterated(value: "\"hello\"")).value, "hello")
        XCTAssertEqual(try number(Iterated(value: "123.4")).value, 123.4)
        
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
        
        do {
            let input = Iterated(value: "{ \"user\": { \"name\": \"mokha\", \"age\": 10} }")
            let result = try jsonParser(input)
            XCTAssertEqual(result.value[0].0, "user")
            XCTAssertEqual(result.value[0].1, .object([("name", .string("mokha")),
                                                       ("age", .number(10))]))
        }
    }

    func testExpression() throws {
        lazy var expr: Parser<String, Int> = {
            (term + many0(prefix(char("+"), term))).map { lhs, rhs in
                lhs + rhs.reduce(0, { $0 + $1 })
            }
        }()
        lazy var term: Parser<String, Int> = {
            (factor + many0(prefix(char("*"), factor))).map { lhs, rhs in
                lhs * rhs.reduce(1, { $0 * $1 })
            }
        }()
        lazy var factor: Parser<String, Int> = {
            digit | lazy(expr)
        }()
        let digit = join(many(charRange("0", "9"))).map { Int($0)! }
        let result = try expr(.init(value: "1+2+3*4*5"))
        XCTAssertEqual(result.value, 63)
    }

    static var allTests = [
        ("testOperators", testOperators),
        ("testHexColor", testHexColor),
        ("testJSON", testJSON),
    ]
}
