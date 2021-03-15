import Foundation

typealias Parser<I, O> = (Iterated<I>) throws -> Iterated<O>

enum ParseError: Error {
    case notImpelemented
}

extension String: LocalizedError {
    public var errorDescription: String? { self }
}

var logger: ((String) -> Void)?

struct Iterated<T> {
    let value: T
    let position: Int
    
    init(value: T, position: Int = 0, logger: ((String) -> Void)? = nil) {
        self.value = value
        self.position = position
    }
}

extension Iterated {
    func log(_ msg: String) {
        if let str = value as? String {
            logger?("\(msg) : \(str.split(position: position).joined(separator: "👉"))")
        } else {
            logger?("\(msg) with input \(value) at position \(position)")
        }
    }
}

func +<I, O1, O2, O3, O4, O5>(a: @escaping Parser<I, (O1, O2, O3, O4)>, b: @escaping Parser<I, O5>) -> Parser<I, (O1, O2, O3, O4, O5)> {
    return { input in
        input.log("enter: \(#function) ((O1, O2, O3, O4), O5)")
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
        input.log("enter: \(#function) ((O1, O2, O3), O4)")
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
        input.log("enter: \(#function) ((O1, O2), O3)")
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
        input.log("enter: \(#function) (Void, O)")
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
        input.log("enter: \(#function) (O, Void)")
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
        input.log("enter: \(#function) (O1, O2)")
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
        input.log("enter: \(#function)")
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
        input.log("enter: \(#function)")
        do {
            return try a(input)
        } catch {
            input.log("catch error: \(#function) \(error.localizedDescription)")
            return try b(input)
        }
    }
}

func many<I, O>(_ parser: @escaping Parser<I, O>) -> Parser<I, [O]> {
    return { input in
        input.log("enter: \(#function)")
        var i = input
        var arr = [O]()
        while let result = try? parser(i) {
            input.log("many: success \(arr.count)")
            i = Iterated(value: input.value, position: result.position)
            arr.append(result.value)
        }
        if arr.isEmpty {
            throw "many: not matched"
        }
        return Iterated(value: arr, position: i.position)
    }
}

func map<Input, Output1, Output2>(_ parser: @escaping Parser<Input, Output1>, _ fn: @escaping (Output1) throws -> Output2) -> Parser<Input, Output2> {
    return { input in
        input.log("enter: \(#function)")
        if (input.position == 10) {
            print(input.value)
        }
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
        input.log("enter: \(#function)")
        do {
            let result = try parser(input)
            return Iterated(value: result.value, position: result.position)
        } catch {
            input.log("catch error: \(#function) \(error.localizedDescription)")
            return Iterated(value: nil, position: input.position)
        }
    }
}

func ignore<I, O>(_ parser: @escaping Parser<I, O>) -> Parser<I, Void> {
    return { input in
        input.log("enter: \(#function)")
        let result = try parser(input)
        return Iterated(value: (), position: result.position)
    }
}

func lazy<I, O>(_ parser: @autoclosure @escaping () -> Parser<I, O>) -> Parser<I, O> {
    return { try parser()($0) }
}

extension StringProtocol {
    subscript(offset: Int) -> Character { self[index(startIndex, offsetBy: offset)] }
    
    func split(position: Int) -> [String] {
        let i = index(startIndex, offsetBy: position)
        return [String(prefix(upTo: i)), String(suffix(from: i))]
    }
}

prefix func !(_ parser: @escaping Parser<String, String>) -> Parser<String, String> {
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

func charRange(_ from: Unicode.Scalar, _ to: Unicode.Scalar) -> Parser<String, String> {
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

func char(_ char: Character) -> Parser<String, String> {
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

func any() -> Parser<String, String> {
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

func join(_ parser: @escaping Parser<String, [String]>, separator: String = "") -> Parser<String, String> {
    return map(parser, { $0.joined(separator: separator) })
}

func eof() -> Parser<String, Void> {
    return { input in
        guard input.position == input.value.count else {
            throw "\(input.position) is not eof"
        }
        return Iterated(value: (), position: input.position)
    }
}
