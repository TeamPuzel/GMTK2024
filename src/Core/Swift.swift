
public extension Array where Element: Collection {
    func joined() -> [Element.Element] {
        self.reduce(into: []) { acc, el in acc.append(contentsOf: el) }
    }
}

public typealias String = CString
public typealias Character = CChar

public typealias CString = [CChar]

extension Array: @retroactive ExpressibleByUnicodeScalarLiteral where Element == CChar {}
extension Array: @retroactive ExpressibleByExtendedGraphemeClusterLiteral where Element == CChar {}

extension Array: @retroactive ExpressibleByStringInterpolation where Element == CChar {}

extension Array: @retroactive ExpressibleByStringLiteral where Element == CChar {
    public init(stringLiteral value: Swift.String) {
        self = [CChar]()
//        assert(value.isASCII)
        var copy = value
        copy.withUTF8 { ptr in
            self.reserveCapacity(ptr.count + 1)
            for char in ptr { self.append(CChar(char)) }
//            self.append(0)
        }
    }
    
    public init(_ value: Swift.String) {
        self = []
//        assert(value.isASCII)
        var copy = value
        copy.withUTF8 { ptr in
            self.reserveCapacity(ptr.count + 1)
            for char in ptr {
                self.append(CChar(char))
            }
//            self.append(0)
        }
    }
}

extension CChar: @retroactive ExpressibleByUnicodeScalarLiteral {}
extension CChar: @retroactive ExpressibleByExtendedGraphemeClusterLiteral {}

extension CChar: @retroactive ExpressibleByStringLiteral {
    @_disfavoredOverload
    public init(stringLiteral value: StaticString) {
        precondition(value.isASCII)
        self.init()
        value.withUTF8Buffer { ptr in
            precondition(ptr.count == 1)
            self = Int8(bitPattern: ptr.first!)
        }
    }
}
