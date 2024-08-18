
import Assets

final class World {
    var floor: Floor!
    unowned(unsafe) var primary: Entity
    private(set) var logEntries: [LogEntry] = []
    
    init() {
        let player = Elf()
        self.primary = player
        
        self.floor = Floor(self, depth: 1)
        self.floor.add(player)
        
        log("You enter the dungeon", color: .Pico.green)
    }
    
    func update() {
        if let floor = primary.floor {
            for entity in floor.entities { entity.update() }
        }
        
        for entry in logEntries {
            entry.timeToLive -= 1
            if entry.timeToLive <= 0 { logEntries.removeAll { $0 === entry } }
        }
    }
    
    func log(_ message: String, color: Color = .white) {
        logEntries.append(.init(message, color: color))
        if logEntries.count > 10 { logEntries.removeFirst() }
    }
    
    final class LogEntry {
        let message: String
        let color: Color
        var timeToLive = 300
        
        init(_ message: String, color: Color) {
            self.message = message
            self.color = color
        }
    }
}

final class Floor {
    unowned(unsafe) var world: World
    private var tiles: [Tile]
    private(set) var entities: Set<Entity>
    
    init(_ world: World, depth: Int) {
        self.world = world
        self.tiles = (0..<Self.width * Self.height).map { _ in Ground() }
        self.entities = .init()
    }
    
    func add(_ entity: Entity) {
        entity.floor = self
        entities.insert(entity)
    }
    
    subscript(x: Int, y: Int) -> Tile {
        get { tiles[x + y * Self.width] }
        set { tiles[x + y * Self.width] = newValue }
    }
    
    @_disfavoredOverload
    subscript(x: Int, y: Int) -> Tile? {
        x >= 0 && y >= 0 && x < Self.width && y < Self.height
            ? tiles[x + y * Self.width] : nil
    }
    
    static let width = 16
    static let height = 16
}

class Tile: Drawable {
    final var width: Int { 16 }
    final var height: Int { 16 }
    subscript(x: Int, y: Int) -> Color { .clear }
    
    /// Color used for this tile on the minimap
    var mapColor: Color { .clear }
    
    static let sheet: DrawableGrid<Image> = UnsafeTGAPointer(KENNEY_TGA).flatten().grid(itemWidth: 16, itemHeight: 16)
}

class Ground: Tile {
    private let offset: Int = .random(in: 0...3)
    private let transparency: Int = .random(in: 0...128)
    
    override subscript(x: Int, y: Int) -> Color {
        Self.sheet[offset, 0]
            .colorMap { [self] in
                .init(
                    r: $0.r,
                    g: $0.g,
                    b: $0.b,
                    a: .init(clamping: Int($0.a) - transparency)
                )
            } [x, y]
    }
    
    override var mapColor: Color { .Pico.brown }
}

class Wall: Tile {
    override subscript(x: Int, y: Int) -> Color {
        Self.sheet[1, 0][x, y]
    }
}
