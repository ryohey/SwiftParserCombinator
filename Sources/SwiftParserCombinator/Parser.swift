import Foundation

public typealias Parser<I, O> = (Iterated<I>) throws -> Iterated<O>

extension String: LocalizedError {
    public var errorDescription: String? { self }
}

public var logger: ((String) -> Void)?

public struct Iterated<T> {
    public let value: T
    public let position: Int
    
    public init(value: T, position: Int = 0, logger: ((String) -> Void)? = nil) {
        self.value = value
        self.position = position
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
