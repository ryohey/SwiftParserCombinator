import Foundation

public func concat<I, O1, O2>(p1: Parser<I, O1>, p2: Parser<I, O2>) -> Parser<I, (O1, O2)> {
    Parser(name: "concat", description: "\(p1.description)\(p2.description)") { input in
        let output1 = try p1(input)
        let output2 = try p2(Iterated(value: input.value, position: output1.position, context: output1.context))
        return Iterated(
            value: (output1.value, output2.value),
            position: output2.position,
            context: output2.context
        )
    }
}

public func concat<I, O1, O2, O3>(p1: Parser<I, O1>, p2: Parser<I, O2>, p3: Parser<I, O3>) -> Parser<I, (O1, O2, O3)> {
    Parser(name: "concat", description: "\(p1.description)\(p2.description)\(p3.description)") { input in
        let output1 = try p1(input)
        let output2 = try p2(Iterated(value: input.value, position: output1.position, context: output1.context))
        let output3 = try p3(Iterated(value: input.value, position: output2.position, context: output2.context))
        return Iterated(
            value: (output1.value, output2.value, output3.value),
            position: output3.position,
            context: output3.context
        )
    }
}

public func concat<I, O1, O2, O3, O4>(p1: Parser<I, O1>, p2: Parser<I, O2>, p3: Parser<I, O3>, p4: Parser<I, O4>) -> Parser<I, (O1, O2, O3, O4)> {
    Parser(name: "concat", description: "\(p1.description)\(p2.description)\(p3.description)") { input in
        let output1 = try p1(input)
        let output2 = try p2(Iterated(value: input.value, position: output1.position, context: output1.context))
        let output3 = try p3(Iterated(value: input.value, position: output2.position, context: output2.context))
        let output4 = try p4(Iterated(value: input.value, position: output3.position, context: output3.context))
        return Iterated(
            value: (output1.value, output2.value, output3.value, output4.value),
            position: output4.position,
            context: output4.context
        )
    }
}

public func +<I, O1, O2, O3, O4, O5>(a: Parser<I, (O1, O2, O3, O4)>, b: Parser<I, O5>) -> Parser<I, (O1, O2, O3, O4, O5)> {
    Parser(name: "+", description: "\(a.description)\(b.description)") { input in
        let output1 = try a(input)
        let output2 = try b(Iterated(value: input.value, position: output1.position, context: output1.context))
        return Iterated(
            value: (output1.value.0, output1.value.1, output1.value.2, output1.value.3, output2.value),
            position: output2.position,
            context: output2.context
        )
    }
}

public func +<I, O1, O2, O3, O4>(a: Parser<I, (O1, O2, O3)>, b: Parser<I, O4>) -> Parser<I, (O1, O2, O3, O4)> {
    Parser(name: "+", description: "\(a.description)\(b.description)") { input in
        let output1 = try a(input)
        let output2 = try b(Iterated(value: input.value, position: output1.position, context: output1.context))
        return Iterated(
            value: (output1.value.0, output1.value.1, output1.value.2, output2.value),
            position: output2.position,
            context: output2.context
        )
    }
}

public func +<I, O1, O2, O3>(a: Parser<I, (O1, O2)>, b: Parser<I, O3>) -> Parser<I, (O1, O2, O3)> {
    Parser(name: "+", description: "\(a.description)\(b.description)") { input in
        let output1 = try a(input)
        let output2 = try b(Iterated(value: input.value, position: output1.position, context: output1.context))
        return Iterated(
            value: (output1.value.0, output1.value.1, output2.value),
            position: output2.position,
            context: output2.context
        )
    }
}

public func +<I, O1, O2>(a: Parser<I, O1>, b: Parser<I, O2>) -> Parser<I, (O1, O2)> {
    Parser(name: "+", description: "\(a.description)\(b.description)") { input in
        let output1 = try a(input)
        let output2 = try b(Iterated(value: input.value, position: output1.position, context: output1.context))
        return Iterated(
            value: (output1.value, output2.value),
            position: output2.position,
            context: output2.context
        )
    }
}

public func &<I, O>(a: Parser<I, O>, b: Parser<I, O>) -> Parser<I, O> {
    Parser(name: "and", description: "(\(a.description)&\(b.description))") { input in
        let output1 = try a(input)
        let output2 = try b(input)
        return Iterated(
            value: output1.value,
            position: output2.position,
            context: output2.context
        )
    }
}

public func |<I, O>(a: Parser<I, O>, b: Parser<I, O>) -> Parser<I, O> {
    Parser(name: "or", description: "(\(a.description)|\(b.description))") { input in
        do {
            return try a(input)
        } catch {
            return try b(input)
        }
    }
}

public func many<I, O>(_ parser: Parser<I, O>) -> Parser<I, [O]> {
    Parser(name: "many", description: parser.description) { input in
        var i = input
        var arr = [O]()
        while let result = try? parser(i) {
            i = Iterated(value: input.value, position: result.position, context: result.context)
            arr.append(result.value)
        }
        if arr.isEmpty {
            throw ParseError(message: "many: not matched")
        }
        return Iterated(value: arr, position: i.position, context: i.context)
    }
}

public func many0<I, O>(_ parser: Parser<I, O>) -> Parser<I, [O]> {
    Parser(name: "many0", description: parser.description) { input in
        var i = input
        var arr = [O]()
        while let result = try? parser(i) {
            i = Iterated(value: input.value, position: result.position, context: result.context)
            arr.append(result.value)
        }
        return Iterated(value: arr, position: i.position, context: i.context)
    }
}

public func map<Input, Output1, Output2>(_ parser: Parser<Input, Output1>, _ fn: @escaping (Output1) throws -> Output2) -> Parser<Input, Output2> {
    Parser(name: "map", description: parser.description) { input in
        let result = try parser(input)
        return Iterated(
            value: try fn(result.value),
            position: result.position,
            context: result.context
        )
    }
}

public func mapTo<Input, Output1, Output2>(_ parser: Parser<Input, Output1>, _ value: Output2) -> Parser<Input, Output2> {
    Parser(name: "mapTo", description: parser.description) { input in
        let result = try parser(input)
        return Iterated(
            value: value,
            position: result.position,
            context: result.context
        )
    }
}

public func prefix<I, O1, O2>(_ start: Parser<I, O1>, _ parser: Parser<I, O2>) -> Parser<I, O2> {
    (start + parser).map { $0.1 }
}

public func suffix<I, O1, O2>(_ parser: Parser<I, O1>, _ end: Parser<I, O2>) -> Parser<I, O1> {
    (parser + end).map { $0.0 }
}

public func delimited<I, O1, O2, O3>(_ start: Parser<I, O1>, _ parser: Parser<I, O2>, _ end: Parser<I, O3>) -> Parser<I, O2> {
    (start + parser + end).map { $0.1 }
}


// doing nothing, but help compiler within some complex expression with binary operators
public func pass<I, O>(_ parser: Parser<I, O>) -> Parser<I, O> {
    return parser
}

public func optional<I, O>(_ parser: Parser<I, O>) -> Parser<I, O?> {
    Parser(name: "optional", description: parser.description) { input in
        do {
            let result = try parser(input)
            return Iterated(value: result.value, position: result.position, context: result.context)
        } catch {
            return Iterated(value: nil, position: input.position, context: input.context)
        }
    }
}

public func lazy<I, O>(_ parser: @autoclosure @escaping () -> Parser<I, O>) -> Parser<I, O> {
    Parser(name: "lazy") { try parser()($0) }
}

public extension Parser {
    func map<Output2>(_ fn: @escaping (Output) throws -> Output2) -> Parser<Input, Output2> {
        SwiftParserCombinator.map(self, fn)
    }

    func mapTo<Output2>(_ value: Output2) -> Parser<Input, Output2> {
        SwiftParserCombinator.mapTo(self, value)
    }

    func optional() -> Parser<Input, Output?> {
        SwiftParserCombinator.optional(self)
    }

    func asVoid() -> Parser<Input, Void> {
        mapTo(())
    }

    func named(_ name: String, description: String = "") -> Parser<Input, Output> {
        Parser(name: name, description: description, fn: parse)
    }

    func surrounded<T>(by parser: Parser<Input, T>) -> Parser<Input, Output> {
        (parser + self + parser).map { $0.1 }
    }

    func suffix<T>(_ end: Parser<Input, T>) -> Parser<Input, Output> {
        SwiftParserCombinator.suffix(self, end)
    }
}
