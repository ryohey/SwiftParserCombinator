import Foundation

public func +<I, O1, O2, O3, O4, O5>(a: @escaping Parser<I, (O1, O2, O3, O4)>, b: @escaping Parser<I, O5>) -> Parser<I, (O1, O2, O3, O4, O5)> {
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

public func +<I, O1, O2, O3, O4>(a: @escaping Parser<I, (O1, O2, O3)>, b: @escaping Parser<I, O4>) -> Parser<I, (O1, O2, O3, O4)> {
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

public func +<I, O1, O2, O3>(a: @escaping Parser<I, (O1, O2)>, b: @escaping Parser<I, O3>) -> Parser<I, (O1, O2, O3)> {
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

public func +<I, O>(a: @escaping Parser<I, Void>, b: @escaping Parser<I, O>) -> Parser<I, O> {
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

public func +<I, O>(a: @escaping Parser<I, O>, b: @escaping Parser<I, Void>) -> Parser<I, O> {
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

public func +<I, O1, O2>(a: @escaping Parser<I, O1>, b: @escaping Parser<I, O2>) -> Parser<I, (O1, O2)> {
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

public func &<I, O>(a: @escaping Parser<I, O>, b: @escaping Parser<I, O>) -> Parser<I, O> {
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

public func |<I, O>(a: @escaping Parser<I, O>, b: @escaping Parser<I, O>) -> Parser<I, O> {
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

public func many<I, O>(_ parser: @escaping Parser<I, O>) -> Parser<I, [O]> {
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

public func map<Input, Output1, Output2>(_ parser: @escaping Parser<Input, Output1>, _ fn: @escaping (Output1) throws -> Output2) -> Parser<Input, Output2> {
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
public func pass<I, O>(_ parser: @escaping Parser<I, O>) -> Parser<I, O> {
    return parser
}

public func optional<I, O>(_ parser: @escaping Parser<I, O>) -> Parser<I, O?> {
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

public func ignore<I, O>(_ parser: @escaping Parser<I, O>) -> Parser<I, Void> {
    return { input in
        input.log("enter: \(#function)")
        let result = try parser(input)
        return Iterated(value: (), position: result.position)
    }
}

public func lazy<I, O>(_ parser: @autoclosure @escaping () -> Parser<I, O>) -> Parser<I, O> {
    return { try parser()($0) }
}
