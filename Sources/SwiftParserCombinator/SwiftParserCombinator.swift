import Foundation

// Parser を関数とした場合. Generics 周りでうまく行かなそうな雰囲気
//
//protocol Stream {
//    associatedtype T
//    func read() -> T
//}
//
//typealias Parser<I, O> = (I) throws -> O
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

protocol Parser {
    associatedtype Input
    associatedtype Output
    
    func parse(_ input: Iterated<Input>) throws -> Iterated<Output>
}

struct OrParser<P1: Parser, P2: Parser>: Parser where
    P1.Input == P2.Input,
    P1.Output == P2.Output {
    typealias Input = P1.Input
    typealias Output = P2.Output
    
    private let a: P1
    private let b: P2
    
    init(_ a: P1, _ b: P2){
        self.a = a
        self.b = b
    }
    
    func parse(_ input: Iterated<Input>) throws -> Iterated<Output> {
        do {
            return try a.parse(input)
        } catch {
            return try b.parse(input)
        }
    }
}

func ||<P1: Parser, P2: Parser>(a: P1, b: P2) -> OrParser<P1, P2> where
    P1.Input == P2.Input,
    P1.Output == P2.Output {
    return OrParser(a, b)
}

struct SequenceParser<P1: Parser, P2: Parser>: Parser where
    P2.Input == P1.Input {
    typealias Input = P1.Input
    typealias Output = (P1.Output, P2.Output)
    
    private let a: P1
    private let b: P2
    
    init(_ a: P1, _ b: P2){
        self.a = a
        self.b = b
    }
    
    func parse(_ input: Iterated<Input>) throws -> Iterated<Output> {
        let output1 = try a.parse(input)
        let output2 = try b.parse(Iterated(value: input.value, position: output1.position))
        return Iterated(
            value: (output1.value, output2.value),
            position: output2.position
        )
    }
}

struct TupleParser<P1: Parser, P2: Parser, O1, O2>: Parser where
    P1.Output == (O1, O2),
    P2.Input == P1.Input {
    typealias Input = P1.Input
    typealias Output = (O1, O2, P2.Output)
    
    private let a: P1
    private let b: P2
    
    init(_ a: P1, _ b: P2){
        self.a = a
        self.b = b
    }
    
    func parse(_ input: Iterated<Input>) throws -> Iterated<Output> {
        let output1 = try a.parse(input)
        let output2 = try b.parse(Iterated(value: input.value, position: output1.position))
        return Iterated(
            value: (output1.value.0, output1.value.1, output2.value),
            position: output2.position
        )
    }
}
//
//func +<P1: Parser, P2: Parser, O1, O2>(a: P1, b: P2) -> TupleParser<P1, P2, O1, O2> where
//    P1.Output == (O1, O2),
//    P2.Input == P1.Input {
//    return TupleParser(a, b)
//}
//
//func +<P1: , P2: Parser>(a: SequenceParser, b: P2) -> TupleParser<P1, P2> where P2.Input == P1.Input {
//    return TupleParser(a, b)
//}

func +<P1: Parser, P2: Parser>(a: P1, b: P2) -> SequenceParser<P1, P2> where P2.Input == P1.Input {
    return SequenceParser(a, b)
}

struct MapParser<P: Parser, Output>: Parser {
    private let parser: P
    private let fn: (P.Output) throws -> Output
    
    init(_ parser: P, _ fn: @escaping (P.Output) throws -> Output) {
        self.parser = parser
        self.fn = fn
    }
    
    func parse(_ input: Iterated<P.Input>) throws -> Iterated<Output> {
        let result = try parser.parse(input)
        return Iterated(
            value: try fn(result.value),
            position: result.position
        )
    }
}

func map<P: Parser, Output>(_ parser: P, _ fn: @escaping (P.Output) throws -> Output) -> MapParser<P, Output> {
    return MapParser(parser, fn)
}

extension StringProtocol {
    subscript(offset: Int) -> Character { self[index(startIndex, offsetBy: offset)] }
}

struct CharParser: Parser {
    typealias Input = String
    typealias Output = String
    
    private let char: Character
    
    init(_ char: Character) {
        self.char = char
    }
    
    func parse(_ input: Iterated<Input>) throws -> Iterated<Output> {
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

struct CharRangeParser: Parser {
    typealias Input = String
    typealias Output = String
    
    private let range: ClosedRange<UInt32>
    
    init(_ from: Unicode.Scalar, _ to: Unicode.Scalar) {
        range = UInt32(from)...UInt32(to)
    }
    
    func parse(_ input: Iterated<Input>) throws -> Iterated<Output> {
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

func char(_ c: Character) -> CharParser {
    return CharParser(c)
}
