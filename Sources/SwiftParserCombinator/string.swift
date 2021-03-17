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
        input.log("enter: \(#function)")
        do {
            _ = try parser(input)
        } catch {
            guard input.position < input.value.count else {
                throw "\(input.position) is out of string range"
            }
            input.log("success: \(#function)")
            return Iterated(
                value: "\(input.value[input.position])",
                position: input.position + 1
            )
        }
        throw "matched"
    }
}

public func charRange(_ from: Unicode.Scalar, _ to: Unicode.Scalar) -> Parser<String, String> {
    let range = UInt32(from)...UInt32(to)
    return { input in
        input.log("enter: \(#function) \(from) to \(to)")
        guard input.position < input.value.count else {
            throw "\(input.position) is out of string range"
        }
        let char = input.value[input.position]
        let c = char.unicodeScalars.first!
        guard range.contains(UInt32(c)) else {
            input.log("failure: \(#function) \(from) to \(to)")
            throw "\(c) is not contained in character range: \(range)"
        }
        input.log("success: \(#function) \(from) to \(to)")
        return Iterated(value: "\(char)", position: input.position + 1)
    }
}

public func char(_ char: Character) -> Parser<String, String> {
    return { input in
        input.log("enter: \(#function) \(char)")
        guard input.position < input.value.count else {
            throw "\(input.position) is out of string range"
        }
        let c = input.value[input.position]
        guard c == char else {
            input.log("failure: \(#function) \(char)")
            throw "\(c) is not \(char)"
        }
        input.log("success: \(#function) \(char)")
        return Iterated(value: "\(char)", position: input.position + 1)
    }
}

public func any() -> Parser<String, String> {
    return { input in
        input.log("enter: \(#function)")
        guard input.position < input.value.count else {
            throw "\(input.position) is out of string range"
        }
        let c = input.value[input.position]
        input.log("success: \(#function)")
        return Iterated(value: "\(c)", position: input.position + 1)
    }
}

public func join(_ parser: @escaping Parser<String, [String]>, separator: String = "") -> Parser<String, String> {
    return map(parser, { $0.joined(separator: separator) })
}

public func eof() -> Parser<String, Void> {
    return { input in
        guard input.position == input.value.count else {
            throw "\(input.position) is not eof"
        }
        return Iterated(value: (), position: input.position)
    }
}
