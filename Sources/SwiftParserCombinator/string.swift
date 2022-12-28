import Foundation

extension StringProtocol {
    subscript(offset: Int) -> Character { self[index(startIndex, offsetBy: offset)] }
}

public prefix func !(_ parser: Parser<String, String>) -> Parser<String, String> {
    Parser(name: "not", description: "^(\(parser.description))") { input in
        do {
            _ = try parser(input)
        } catch {
            guard input.position < input.value.count else {
                throw ParseError(message: "\(input.position) is out of string range")
            }
            return Iterated(
                value: "\(input.value[input.position])",
                position: input.position + 1,
                context: input.context
            )
        }
        throw ParseError(message: "matched")
    }
}

public func charRange(_ from: Unicode.Scalar, _ to: Unicode.Scalar) -> Parser<String, String> {
    let range = UInt32(from)...UInt32(to)

    return Parser(name: "charRange", description: "[\(from)-\(to)]") { input in
        guard input.position < input.value.count else {
            throw ParseError(message: "\(input.position) is out of string range")
        }
        let char = input.value[input.position]
        let c = char.unicodeScalars.first!
        guard range.contains(UInt32(c)) else {
            throw ParseError(message: "\(c) is not contained in character range: \(range)")
        }
        return Iterated(
            value: "\(char)",
            position: input.position + 1,
            context: input.context
        )
    }
}

public func char(_ char: Character) -> Parser<String, String> {
    Parser(name: "char", description: "\(char)") { input in
        guard input.position < input.value.count else {
            throw ParseError(message: "\(input.position) is out of string range")
        }
        let c = input.value[input.position]
        guard c == char else {
            throw ParseError(message: "\(c) is not \(char)")
        }
        return Iterated(
            value: "\(char)",
            position: input.position + 1,
            context: input.context
        )
    }
}

public func string(_ str: String) -> Parser<String, String> {
    Parser(name: "string", description: str) { input in
        guard input.position + str.count <= input.value.count else {
            throw ParseError(message: "\(input.position + str.count) is out of string range")
        }
        let substr = input.value.substring(input.position, input.position + str.count)
        guard substr == str else {
            throw ParseError(message: "\(substr) is not \(str)")
        }
        return Iterated(
            value: str,
            position: input.position + str.count,
            context: input.context
        )
    }
}

private extension String {
    func substring(_ start: Int, _ end: Int) -> String {
        let startIndex = index(self.startIndex, offsetBy: start)
        let endIndex = index(self.startIndex, offsetBy: end)
        return String(self[startIndex..<endIndex])
    }
}

public func anyChar() -> Parser<String, String> {
    Parser(name: "any", description: "*") { input in
        guard input.position < input.value.count else {
            throw ParseError(message: "\(input.position) is out of string range")
        }
        let c = input.value[input.position]
        return Iterated(
            value: "\(c)",
            position: input.position + 1,
            context: input.context
        )
    }
}

public func join<Input>(_ parser: Parser<Input, [String]>, separator: String = "") -> Parser<Input, String> {
    return map(parser, { $0.joined(separator: separator) })
}

public func eof() -> Parser<String, Void> {
    Parser(name: "eof", description: "EOF") { input in
        guard input.position == input.value.count else {
            throw ParseError(message: "\(input.position) is not eof")
        }
        return Iterated(
            value: (),
            position: input.position,
            context: input.context
        )
    }
}

public extension Parser {
    func joined(separator: String = "") -> Parser<Input, String> where Output == [String] {
        join(self)
    }
}
