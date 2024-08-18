
/// A target independent game that can be run by a runtime for any platform.
protocol Game {
    init()
    mutating func update(input: borrowing Input)
    mutating func frame(input: borrowing Input, target: inout some MutableDrawable)
}
