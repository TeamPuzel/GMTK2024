
import Assets

class Entity: Drawable {
    // SAFETY: An entity must not be used in any way if it doesn't belong to a floor.
    unowned(unsafe) var floor: Floor!
    
    final var width: Int { 32 }
    final var height: Int { 32 }
    subscript(x: Int, y: Int) -> Color { .clear }
    
    final var position: Vector2<Int> = .zero
    final var x: Int {
        get { position.x }
        set { position.x = newValue }
    }
    final var y: Int {
        get { position.y }
        set { position.y = newValue }
    }
    
    func update() {}
    
    static let sheet: DrawableGrid<Image> = UnsafeTGAPointer(SHEET_TGA).flatten().grid(itemWidth: 32, itemHeight: 32)
}

extension Entity: Hashable {
    public static func == (lhs: Entity, rhs: Entity) -> Bool { lhs === rhs }
    public func hash(into hasher: inout Hasher) { hasher.combine(ObjectIdentifier(self)) }
}

class Elf: Entity {
    override subscript(x: Int, y: Int) -> Color { Self.sheet[0, 0][x, y] }
}
