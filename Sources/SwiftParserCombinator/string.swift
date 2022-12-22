import Foundation

extension StringProtocol {
    subscript(offset: Int) -> Character { self[index(startIndex, offsetBy: offset)] }
    
    func split(position: Int) -> [String] {
        let i = index(startIndex, offsetBy: position)
        return [String(prefix(upTo: i)), String(suffix(from: i))]
    }
}

public prefix func !(_ parser: @escaping Parser<String, String>) -> Parser<String, String> {
    return { input in
        let context = input.context.append(call: .init(name: "!", value: ""))

        do {
            _ = try parser(input)
        } catch {
            guard input.position < input.value.count else {
                throw ParseError(context: context, message: "\(input.position) is out of string range")
            }
            return Iterated(
                value: "\(input.value[input.position])",
                position: input.position + 1,
                context: context
            )
        }
        throw ParseError(context: context, message: "matched")
    }
}

public func charRange(_ from: Unicode.Scalar, _ to: Unicode.Scalar) -> Parser<String, String> {
    let range = UInt32(from)...UInt32(to)
    return { input in
        let context = input.context.append(call: .init(name: "charRange", value: "\(range)"))

        guard input.position < input.value.count else {
            throw ParseError(context: context, message: "\(input.position) is out of string range")
        }
        let char = input.value[input.position]
        let c = char.unicodeScalars.first!
        guard range.contains(UInt32(c)) else {
            throw ParseError(context: context, message: "\(c) is not contained in character range: \(range)")
        }
        return Iterated(
            value: "\(char)",
            position: input.position + 1,
            context: context
        )
    }
}

public func char(_ char: Character) -> Parser<String, String> {
    return { input in
        let context = input.context.append(call: .init(name: "char", value: "\(char)"))

        guard input.position < input.value.count else {
            throw ParseError(context: context, message: "\(input.position) is out of string range")
        }
        let c = input.value[input.position]
        guard c == char else {
            throw ParseError(context: context, message: "\(c) is not \(char)")
        }
        return Iterated(
            value: "\(char)",
            position: input.position + 1,
            context: context
        )
    }
}

public func any() -> Parser<String, String> {
    return { input in
        let context = input.context.append(call: .init(name: "any", value: ""))

        guard input.position < input.value.count else {
            throw ParseError(context: context, message: "\(input.position) is out of string range")
        }
        let c = input.value[input.position]
        return Iterated(
            value: "\(c)",
            position: input.position + 1,
            context: context
        )
    }
}

public func join(_ parser: @escaping Parser<String, [String]>, separator: String = "") -> Parser<String, String> {
    return map(parser, { $0.joined(separator: separator) })
}

public func eof() -> Parser<String, Void> {
    return { input in
        let context = input.context.append(call: .init(name: "eof", value: ""))

        guard input.position == input.value.count else {
            throw ParseError(context: context, message: "\(input.position) is not eof")
        }
        return Iterated(
            value: (),
            position: input.position,
            context: context
        )
    }
}
