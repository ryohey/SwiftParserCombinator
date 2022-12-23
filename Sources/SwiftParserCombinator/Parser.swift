import Foundation

public struct Parser<Input, Output> {
    private let fn: (Iterated<Input>) throws -> Iterated<Output>
    public let name: String
    public let description: String

    public init(name: String = "",
                description: String = "",
                fn: @escaping (Iterated<Input>) throws -> Iterated<Output>) {
        self.name = name
        self.description = description
        self.fn = fn
    }

    public func parse(_ input: Iterated<Input>) throws -> Iterated<Output> {
        let context = input.context.append(call: .init(name: name, value: description))
        let input2 = Iterated(value: input.value, position: input.position, context: context)
        return try fn(input2)
    }

    public func callAsFunction(_ input: Iterated<Input>) throws -> Iterated<Output> {
        try parse(input)
    }
}

extension String: LocalizedError {
    public var errorDescription: String? { self }
}

public typealias Logger = (String) -> Void
public var logger: ((String) -> Void)?

public struct Context {
    public let logger: Logger
    public let callStack: [Call]

    public init(logger: @escaping Logger, callStack: [Call]) {
        self.logger = logger
        self.callStack = callStack
    }

    public func append(call: Call) -> Context {
        .init(logger: logger,
              callStack: callStack + [call])
    }

    public struct Call {
        public let name: String
        public let value: String
    }
}

public struct Iterated<T> {
    public let value: T
    public let position: Int
    public let context: Context
    
    public init(value: T,
                position: Int = 0,
                context: Context = Context(logger: { _ in }, callStack: [])) {
        self.value = value
        self.position = position
        self.context = context
    }
}
