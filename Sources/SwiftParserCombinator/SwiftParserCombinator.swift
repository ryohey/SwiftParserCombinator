import Foundation

typealias Parser<I, O> = (Iterated<I>) throws -> Iterated<O>

enum ParseError: Error {
    case notImpelemented
}

extension String: LocalizedError {
    public var errorDescription: String? { self }
}

struct Iterated<T> {
    let value: T
    let position: Int
    let logger: ((String) -> Void)?
    
    init(value: T, position: Int = 0, logger: ((String) -> Void)? = nil) {
        self.value = value
        self.position = position
        self.logger = logger
    }
}

extension Iterated {
    func log(_ msg: String) {
        logger?("\(msg) with input \(value) at position \(position)")
    }
}

func +<I, O1, O2, O3, O4, O5>(a: @escaping Parser<I, (O1, O2, O3, O4)>, b: @escaping Parser<I, O5>) -> Parser<I, (O1, O2, O3, O4, O5)> {
    return { input in
        let output1 = try a(input)
        let output2 = try b(Iterated(value: input.value, position: output1.position))
        return Iterated(
            value: (output1.value.0, output1.value.1, output1.value.2, output1.value.3, output2.value),
            position: output2.position
        )
    }
}

func +<I, O1, O2, O3, O4>(a: @escaping Parser<I, (O1, O2, O3)>, b: @escaping Parser<I, O4>) -> Parser<I, (O1, O2, O3, O4)> {
    return { input in
        let output1 = try a(input)
        let output2 = try b(Iterated(value: input.value, position: output1.position))
        return Iterated(
            value: (output1.value.0, output1.value.1, output1.value.2, output2.value),
            position: output2.position
        )
    }
}

func +<I, O1, O2, O3>(a: @escaping Parser<I, (O1, O2)>, b: @escaping Parser<I, O3>) -> Parser<I, (O1, O2, O3)> {
    return { input in
        let output1 = try a(input)
        let output2 = try b(Iterated(value: input.value, position: output1.position))
        return Iterated(
            value: (output1.value.0, output1.value.1, output2.value),
            position: output2.position
        )
    }
}

func +<I, O>(a: @escaping Parser<I, Void>, b: @escaping Parser<I, O>) -> Parser<I, O> {
    return { input in
        let output1 = try a(input)
        let output2 = try b(Iterated(value: input.value, position: output1.position))
        return Iterated(
            value: output2.value,
            position: output2.position
        )
    }
}

func +<I, O>(a: @escaping Parser<I, O>, b: @escaping Parser<I, Void>) -> Parser<I, O> {
    return { input in
        let output1 = try a(input)
        let output2 = try b(Iterated(value: input.value, position: output1.position))
        return Iterated(
            value: output1.value,
            position: output2.position
        )
    }
}

func +<I, O1, O2>(a: @escaping Parser<I, O1>, b: @escaping Parser<I, O2>) -> Parser<I, (O1, O2)> {
    return { input in
        let output1 = try a(input)
        let output2 = try b(Iterated(value: input.value, position: output1.position))
        return Iterated(
            value: (output1.value, output2.value),
            position: output2.position
        )
    }
}

func &<I, O>(a: @escaping Parser<I, O>, b: @escaping Parser<I, O>) -> Parser<I, O> {
    return { input in
        let output1 = try a(input)
        let output2 = try b(input)
        return Iterated(
            value: output1.value,
            position: output2.position
        )
    }
}

func |<I, O>(a: @escaping Parser<I, O>, b: @escaping Parser<I, O>) -> Parser<I, O> {
    return { input in
        do {
            return try a(input)
        } catch {
            return try b(input)
        }
    }
}

func many<I, O>(_ parser: @escaping Parser<I, O>) -> Parser<I, [O]> {
    return { input in
        var i = input
        var arr = [O]()
        while let result = try? parser(i) {
            i = Iterated(value: input.value, position: result.position)
            arr.append(result.value)
        }
        return Iterated(value: arr, position: i.position)
    }
}

func map<Input, Output1, Output2>(_ parser: @escaping Parser<Input, Output1>, _ fn: @escaping (Output1) throws -> Output2) -> Parser<Input, Output2> {
    return { input in
        let result = try parser(input)
        return Iterated(
            value: try fn(result.value),
            position: result.position
        )
    }
}

// doing nothing, but help compiler within some complex expression with binary operators
func pass<I, O>(_ parser: @escaping Parser<I, O>) -> Parser<I, O> {
   return parser
}

func optional<I, O>(_ parser: @escaping Parser<I, O>) -> Parser<I, O?> {
   return { input in
       do {
           let result = try parser(input)
           return Iterated(value: result.value, position: result.position)
       } catch {
           return Iterated(value: nil, position: input.position)
       }
   }
}

func ignore<I, O>(_ parser: @escaping Parser<I, O>) -> Parser<I, Void> {
    return map(parser, { _ in })
}

extension StringProtocol {
    subscript(offset: Int) -> Character { self[index(startIndex, offsetBy: offset)] }
}

prefix func !(_ parser: @escaping Parser<String, String>) -> Parser<String, String> {
    return { input in
        do {
            _ = try parser(input)
        } catch {
            guard input.position < input.value.count else {
                throw "\(input.position) is out of string range"
            }
            return Iterated(
                value: "\(input.value[input.position])",
                position: input.position + 1
            )
        }
        throw "matched"
    }
}

func charRange(_ from: Unicode.Scalar, _ to: Unicode.Scalar) -> Parser<String, String> {
    let range = UInt32(from)...UInt32(to)
    return { input in
        guard input.position < input.value.count else {
            throw "\(input.position) is out of string range"
        }
        let char = input.value[input.position]
        let c = char.unicodeScalars.first!
        guard range.contains(UInt32(c)) else {
            throw "\(c) is not contained in character range: \(range)"
        }
        return Iterated(value: "\(char)", position: input.position + 1)
    }
}

func char(_ char: Character) -> Parser<String, String> {
    return { input in
        input.log("enter: \(#function) \(char)")
        guard input.position < input.value.count else {
            throw "\(input.position) is out of string range"
        }
        let c = input.value[input.position]
        guard c == char else {
            throw "\(c) is not \(char)"
        }
        return Iterated(value: "\(char)", position: input.position + 1)
    }
}

func any() -> Parser<String, String> {
    return { input in
        guard input.position < input.value.count else {
            throw "\(input.position) is out of string range"
        }
        let c = input.value[input.position]
        return Iterated(value: "\(c)", position: input.position + 1)
    }
}

func join(_ parser: @escaping Parser<String, [String]>, separator: String = "") -> Parser<String, String> {
    return map(parser, { $0.joined(separator: separator) })
}
