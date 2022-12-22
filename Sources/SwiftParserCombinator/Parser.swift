import Foundation

public typealias Parser<I, O> = (Iterated<I>) throws -> Iterated<O>

extension String: LocalizedError {
    public var errorDescription: String? { self }
}

public typealias Logger = (String) -> Void
public var logger: ((String) -> Void)?

public struct Context {
    public let logger: Logger
    public let callStack: [Call]

    public init(logger: Logger, callStack: [Call]) {
        self.logger = Logger
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

public extension Iterated {
    func log(_ msg: String) {
        if let str = value as? String {
            logger?("\(msg) : \(str.split(position: position).joined(separator: "👉"))")
        } else {
            logger?("\(msg) with input \(value) at position \(position)")
        }
    }
}
