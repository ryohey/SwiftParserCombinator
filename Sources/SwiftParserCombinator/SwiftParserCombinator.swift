import Foundation

// Parser を関数とした場合. Generics 周りでうまく行かなそうな雰囲気
//
//protocol Stream {
//    associatedtype T
//    func read() -> T
//}
//
//
//func ||<I, O>(a: @escaping Parser<I, O>, b: @escaping Parser<I, O>) -> Parser<I, O> {
//    return {
//        do {
//            return try a($0)
//        } catch {
//            return try b($0)
//        }
//    }
//}
//
//func `$`<I: Stream, O>(str: String) -> Parser<I, O> {
//
//}

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
}

func ||<Input, Output>(a: @escaping Parser<Input, Output>, b: @escaping Parser<Input, Output>) -> Parser<Input, Output> {
    return { input in
        do {
            return try a(input)
        } catch {
            return try b(input)
        }
    }
}

func +<Input, Output1, Output2>(a: @escaping Parser<Input, Output1>, b: @escaping Parser<Input, Output2>) -> Parser<Input, (Output1, Output2)> {
    return { input in
        let output1 = try a(input)
        let output2 = try b(Iterated(value: input.value, position: output1.position))
        return Iterated(
            value: (output1.value, output2.value),
            position: output2.position
        )
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

extension StringProtocol {
    subscript(offset: Int) -> Character { self[index(startIndex, offsetBy: offset)] }
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
