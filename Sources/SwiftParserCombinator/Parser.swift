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
        input.context.logger(.init(status: .enter, parser: self, input: input))
        let context = input.context.push(call: .init(name: name, value: description))
        let input2 = Iterated(value: input.value, position: input.position, context: context)
        do {
            let result = try fn(input2)
            input.context.logger(.init(status: .success, parser: self, input: input))
            return Iterated(value: result.value, position: result.position, context: result.context.pop())
        } catch {
            input.context.logger(.init(status: .failure, parser: self, input: input))
            throw error
        }
    }

    public func callAsFunction(_ input: Iterated<Input>) throws -> Iterated<Output> {
        try parse(input)
    }
}

extension String: LocalizedError {
    public var errorDescription: String? { self }
}

public typealias Logger = (Log) -> Void

public struct Log {
    public let status: Status
    public let parserName: String
    public let parserDescription: String
    public let position: Int
    public let context: Context

    init<Input, Output>(status: Status, parser: Parser<Input, Output>, input: Iterated<Input>) {
        self.status = status
        self.parserName = parser.name
        self.parserDescription = parser.description
        self.position = input.position
        self.context = input.context
    }

    public enum Status {
        case enter
        case success
        case failure
    }
}

public struct Context {
    public let logger: Logger
    public let callStack: [Call]

    public init(logger: @escaping Logger = { _ in }, callStack: [Call] = []) {
        self.logger = logger
        self.callStack = callStack
    }

    public func push(call: Call) -> Context {
        .init(logger: logger,
              callStack: callStack + [call])
    }

    public func pop() -> Context {
        .init(logger: logger,
              callStack: callStack.dropLast())
    }

    public struct Call {
        public let name: String
        public let value: String
    }

    var stackTrace: String {
        callStack
            .map { "- \($0.name)() \($0.value)" }
            .joined(separator: "\n")
    }
}

public struct Iterated<T> {
    public let value: T
    public let position: Int
    public let context: Context
    
    public init(value: T,
                position: Int = 0,
                context: Context = .init()) {
        self.value = value
        self.position = position
        self.context = context
    }
}
