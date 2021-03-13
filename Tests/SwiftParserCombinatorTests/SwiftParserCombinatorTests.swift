import XCTest
@testable import SwiftParserCombinator

final class SwiftParserCombinatorTests: XCTestCase {
    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        let hash = CharParser("#")
        let hex = CharRangeParser("0", "9") || CharRangeParser("a", "f")
        let component = map(hex + hex, { (tuple: (String, String)) -> Int in
            let str = tuple.0 + tuple.1
            var rgbValue: UInt64 = 0
            Scanner(string: str).scanHexInt64(&rgbValue)
            return Int(rgbValue)
        })
        let r = component
        let g = component
        let b = component
        let gb = g + b
        let colorParser = map(hash + r + g + b, { (tuple: (((String, Int), Int), Int)) in
            return (r: tuple.0.0.1, g: tuple.0.1, b: tuple.1)
        })
        let input = Iterated(value: "#ff6400", position: 0)
        let result = try colorParser.parse(input)
        XCTAssertEqual(result.value.r, 255)
        XCTAssertEqual(result.value.g, 100)
        XCTAssertEqual(result.value.b, 0)
        XCTAssertEqual(result.position, 7)
        XCTAssertThrowsError(try colorParser.parse(Iterated(value: "#ff400", position: 0)))
        XCTAssertThrowsError(try colorParser.parse(Iterated(value: "#ff400_", position: 0)))
        XCTAssertThrowsError(try colorParser.parse(Iterated(value: "ff4000", position: 0)))
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
