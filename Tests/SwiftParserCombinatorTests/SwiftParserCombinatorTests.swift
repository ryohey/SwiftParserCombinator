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
        let colorParser = map(hash + r + g + b, { (r: $0.1, g: $0.2, b: $0.3) })
        let input = Iterated(value: "#ff6400", position: 0)
        let result = try colorParser(input)
        XCTAssertEqual(result.value.r, 255)
        XCTAssertEqual(result.value.g, 100)
        XCTAssertEqual(result.value.b, 0)
        XCTAssertEqual(result.position, 7)
        XCTAssertThrowsError(try colorParser(Iterated(value: "#ff400", position: 0)))
        XCTAssertThrowsError(try colorParser(Iterated(value: "#ff400_", position: 0)))
        XCTAssertThrowsError(try colorParser(Iterated(value: "ff4000", position: 0)))
    }
    
    enum JSONValue {
        case string(String)
        case number(Double)
    }
    
    func testJSON() throws {
        let string = join(map(char("\"") + many(any() & !char("\"")) + char("\""), { $0.1 }))
        XCTAssertEqual(try string(Iterated(value: "\"hello\"", position: 0)).value, "hello")
        
        let number = map(join(many(charRange("0", "9") | char("."))), { Double($0)! })
        XCTAssertEqual(try number(Iterated(value: "123.4", position: 0)).value, 123.4)
        
        let stringValue = map(string, { JSONValue.string($0) })
        let numberValue = map(number, { JSONValue.number($0) })
        
        let keyValue = map(string + char(":") + (stringValue | numberValue), { ($0.1, $0.2) })
//        let json = char("{") + string + char(":") + (string | number) + char("}")
        
//        let input = Iterated(value: "{ name: \"mokha\", age: 10 }", position: 0)
//        let result = try jsonParser(input)
    }

    static var allTests = [
        ("testHexColor", testHexColor),
    ]
}
