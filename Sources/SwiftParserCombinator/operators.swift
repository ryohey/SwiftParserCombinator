import Foundation

public func +<I, O1, O2, O3, O4, O5>(a: Parser<I, (O1, O2, O3, O4)>, b: Parser<I, O5>) -> Parser<I, (O1, O2, O3, O4, O5)> {
    Parser(name: "concat", description: "\(a.description)\(b.description)") { input in
        let output1 = try a(input)
        let output2 = try b(Iterated(value: input.value, position: output1.position))
        return Iterated(
            value: (output1.value.0, output1.value.1, output1.value.2, output1.value.3, output2.value),
            position: output2.position
        )
    }
}

public func +<I, O1, O2, O3, O4>(a: Parser<I, (O1, O2, O3)>, b: Parser<I, O4>) -> Parser<I, (O1, O2, O3, O4)> {
    Parser(name: "concat", description: "\(a.description)\(b.description)") { input in
        let output1 = try a(input)
        let output2 = try b(Iterated(value: input.value, position: output1.position))
        return Iterated(
            value: (output1.value.0, output1.value.1, output1.value.2, output2.value),
            position: output2.position
        )
    }
}

public func +<I, O1, O2, O3>(a: Parser<I, (O1, O2)>, b: Parser<I, O3>) -> Parser<I, (O1, O2, O3)> {
    Parser(name: "concat", description: "\(a.description)\(b.description)") { input in
        let output1 = try a(input)
        let output2 = try b(Iterated(value: input.value, position: output1.position))
        return Iterated(
            value: (output1.value.0, output1.value.1, output2.value),
            position: output2.position
        )
    }
}

public func +<I, O>(a: Parser<I, Void>, b: Parser<I, O>) -> Parser<I, O> {
    Parser(name: "concat", description: "\(a.description)\(b.description)") { input in
        let output1 = try a(input)
        let output2 = try b(Iterated(value: input.value, position: output1.position))
        return Iterated(
            value: output2.value,
            position: output2.position
        )
    }
}

public func +<I, O>(a: Parser<I, O>, b: Parser<I, Void>) -> Parser<I, O> {
    Parser(name: "concat", description: "\(a.description)\(b.description)") { input in
        let output1 = try a(input)
        let output2 = try b(Iterated(value: input.value, position: output1.position))
        return Iterated(
            value: output1.value,
            position: output2.position
        )
    }
}

public func +<I, O1, O2>(a: Parser<I, O1>, b: Parser<I, O2>) -> Parser<I, (O1, O2)> {
    Parser(name: "concat", description: "\(a.description)\(b.description)") { input in
        let output1 = try a(input)
        let output2 = try b(Iterated(value: input.value, position: output1.position))
        return Iterated(
            value: (output1.value, output2.value),
            position: output2.position
        )
    }
}

public func &<I, O>(a: Parser<I, O>, b: Parser<I, O>) -> Parser<I, O> {
    Parser(name: "and", description: "(\(a.description)&\(b.description))") { input in
        let output1 = try a(input)
        let output2 = try b(input)
        return Iterated(
            value: output1.value,
            position: output2.position
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
    Parser(name: "many") { input in
        var i = input
        var arr = [O]()
        while let result = try? parser(i) {
            i = Iterated(value: input.value, position: result.position)
            arr.append(result.value)
        }
        if arr.isEmpty {
            throw ParseError(context: input.context, message: "many: not matched")
        }
        return Iterated(value: arr, position: i.position)
    }
}

public func map<Input, Output1, Output2>(_ parser: Parser<Input, Output1>, _ fn: @escaping (Output1) throws -> Output2) -> Parser<Input, Output2> {
    Parser(name: "map") { input in
        let result = try parser(input)
        return Iterated(
            value: try fn(result.value),
            position: result.position
        )
    }
}
func mapTo<Input, Output1, Output2>(_ parser: Parser<Input, Output1>, _ value: Output2) -> Parser<Input, Output2> {
    Parser(name: "mapTo") { input in
        let result = try parser(input)
        return Iterated(
            value: value,
            position: result.position
        )
    }
}

// doing nothing, but help compiler within some complex expression with binary operators
public func pass<I, O>(_ parser: Parser<I, O>) -> Parser<I, O> {
    return parser
}

public func optional<I, O>(_ parser: Parser<I, O>) -> Parser<I, O?> {
    Parser(name: "optional") { input in
        do {
            let result = try parser(input)
            return Iterated(value: result.value, position: result.position, context: result.context)
        } catch {
            return Iterated(value: nil, position: input.position, context: input.context)
        }
    }
}

public func ignore<I, O>(_ parser: Parser<I, O>) -> Parser<I, Void> {
    Parser(name: "ignore") { input in
        let result = try parser(input)
        return Iterated(value: (), position: result.position, context: result.context)
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

    func ignore() -> Parser<Input, Void> {
        SwiftParserCombinator.ignore(self)
    }
}
