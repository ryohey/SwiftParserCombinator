import XCTest
@testable import SwiftParserCombinator

final class SwiftParserCombinatorTests: XCTestCase {
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
    
    indirect enum JSONValue: Equatable {
        case string(String)
        case number(Double)
        case object(JSONValue)
    }
    
    func testJSON() throws {
        let space = ignore(optional(many(char(" ") | char("\n"))))
        
        let string = join(map(char("\"") + many(any() & !char("\"")) + char("\""), { $0.1 }))
        XCTAssertEqual(try string(Iterated(value: "\"hello\"")).value, "hello")
        
        let number = map(join(many(charRange("0", "9") | char("."))), { Double($0)! })
        XCTAssertEqual(try number(Iterated(value: "123.4")).value, 123.4)
        
        let stringValue = map(string, { JSONValue.string($0) })
        let numberValue = map(number, { JSONValue.number($0) })
        
        let separator = ignore(space + pass(char(":") + space))
        let keyValue = map(string + separator + (stringValue | numberValue), { ($0, $1) })
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
        
        let singleKeyValue = map(keyValue, { [$0] })
        let lineSeparator = ignore(space + pass(char(",") + space))
        let manyKeyValue = map(many(keyValue + lineSeparator) + keyValue, { $0 + [$1] })

        let jsonObj = ignore(char("{") + space) + pass(manyKeyValue | singleKeyValue) + ignore(space + char("}"))
        
        let input = Iterated(value: "{ name: \"mokha\", age: 10}", logger: { print($0) })
        let result = try jsonObj(input)
    }

    static var allTests = [
        ("testHexColor", testHexColor),
    ]
}
