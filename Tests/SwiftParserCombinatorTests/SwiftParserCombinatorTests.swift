import XCTest
@testable import SwiftParserCombinator

final class SwiftParserCombinatorTests: XCTestCase {
    func testHexColor() throws {
        let hash = char("#")
        let hex = charRange("0", "9") || charRange("a", "f")
        let component = map(hex + hex, { (tuple: (String, String)) -> Int in
            let str = tuple.0 + tuple.1
            var rgbValue: UInt64 = 0
            Scanner(string: str).scanHexInt64(&rgbValue)
            return Int(rgbValue)
        })
        let r = component
        let g = component
        let b = component
        let colorParser = map(hash + r + g + b, { (tuple: (String, Int, Int, Int)) in
            return (r: tuple.1, g: tuple.2, b: tuple.3)
        })
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

    static var allTests = [
        ("testHexColor", testHexColor),
    ]
}
