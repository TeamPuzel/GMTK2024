
import Assets

final class World {
    var floors: [Floor] = []
    unowned(unsafe) var primary: Entity
    private(set) var logEntries: [LogEntry] = []
    
    var primaryAiming: Usable? = nil
    
    init() {
        let player = Elf(x: 2, y: 3)
        self.primary = player
        
        for depth in 0...Self.maxDepth {
            floors.append(Floor(self, depth: depth))
        }
                          
        self.floors[0].add(player)
        self.floors[0].add(CursedBackpack(x: 3, y: 3))
        self.floors[0].add(Potion(x: 2, y: 1))
        self.floors[0].add(Potion(x: 3, y: 1))
        self.floors[0].add(Skeleton(x: 6, y: 6))
        
        log("You approach the dungeon, noticing a strange backpack on the floor.", color: .Pico.blue, duration: 600)
        log("You decide to take it with you, as yours can only hold one item.", color: .Pico.blue, duration: 600)
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
    
    func activate(x: Int, y: Int) {
        if primary.makePrimaryTurn(x: x, y: y) {
            activate()
        }
    }
    
    func activate() {
        environmentTurn()
    }
    
    func environmentTurn() {
        for entity in primary.floor.entities where entity !== primary { entity.makeTurn() }
    }
    
    func enterPrimaryAimMode(of item: Usable) {
        primaryAiming = item
    }
    
    func log(_ message: String, color: Color = .white, duration: Int = 300) {
        logEntries.append(.init(message, color: color, timeToLive: duration))
        if logEntries.count > 10 { logEntries.removeFirst() }
    }
    
    final class LogEntry {
        let message: String
        let color: Color
        var timeToLive: Int
        
        init(_ message: String, color: Color, timeToLive: Int) {
            self.message = message
            self.color = color
            self.timeToLive = timeToLive
        }
    }
    
    static let maxDepth = 2
}

final class Floor {
    unowned(unsafe) var world: World
    let depth: Int
    private var tiles: [Tile] = []
    private(set) var entities: Set<Entity>
    
    init(_ world: World, depth: Int) {
        self.world = world
        self.entities = .init()
        self.depth = depth
        self.tiles = (0..<Self.width * Self.height).map { _ in Ground(self) }
        
        if depth == 0 {
            for _ in 0..<4 {
                let (x, y) = (Int.random(in: 0..<Floor.width), Int.random(in: 0..<Floor.height))
                guard self[x, y] is Ground else { continue }
                guard !entities.contains(where: { $0.x == x && $0.y == y }) else { continue }
                self.add(Slime(x: x, y: y))
            }
        }
        
        if depth != World.maxDepth {
            while true {
                let (x, y) = (Int.random(in: 0..<Floor.width), Int.random(in: 0..<Floor.height))
                guard self[x, y] is Ground else { continue }
                self[x, y] = Stairs(self, .down)
                break
            }
        }
        
        if depth != 0 {
            while true {
                let (x, y) = (Int.random(in: 0..<Floor.width), Int.random(in: 0..<Floor.height))
                guard self[x, y] is Ground else { continue }
                self[x, y] = Stairs(self, .up)
                break
            }
        }
        
        if depth == World.maxDepth {
            while true {
                let (x, y) = (Int.random(in: 0..<Floor.width), Int.random(in: 0..<Floor.height))
                guard self[x, y] is Ground else { continue }
                let king = SkeletonKing(x: x, y: y)
                king.storageItem = SkeletonBackpack(equippedBy: king)
                king.storageItem?.storage.append(GoldenTouchScroll())
                self.add(king)
                break
            }
        }
        
        if depth > 0 {
            for _ in 0..<6 {
                let (x, y) = (Int.random(in: 0..<Floor.width), Int.random(in: 0..<Floor.height))
                guard self[x, y] is Ground else { continue }
                guard !entities.contains(where: { $0.x == x && $0.y == y }) else { continue }
                
                let skeleton = Skeleton(x: x, y: y)
                if Int.random(in: 0...4) == 0 { skeleton.storageItem = SkeletonBackpack(equippedBy: skeleton) }
                skeleton.level = .random(in: 1...(depth + 1))
                self.add(skeleton)
            }
            
            for _ in 0..<2 {
                let (x, y) = (Int.random(in: 0..<Floor.width), Int.random(in: 0..<Floor.height))
                guard self[x, y] is Ground else { continue }
                guard !entities.contains(where: { $0.x == x && $0.y == y }) else { continue }
                self.add(Potion(x: x, y: y))
            }
            
            for _ in 0..<10 {
                let (x, y) = (Int.random(in: 0..<Floor.width), Int.random(in: 0..<Floor.height))
                guard self[x, y] is Ground else { continue }
                guard !entities.contains(where: { $0.x == x && $0.y == y }) else { continue }
                self.add(Scroll.random(x: x, y: y))
            }
        }
        
        if depth > 1 {
            for _ in 0..<4 {
                let (x, y) = (Int.random(in: 0..<Floor.width), Int.random(in: 0..<Floor.height))
                guard self[x, y] is Ground else { continue }
                guard !entities.contains(where: { $0.x == x && $0.y == y }) else { continue }
                self.add(CoinPouch(x: x, y: y, count: .random(in: 0...64)))
            }
        }
    }
    
    func add(_ entity: Entity) {
        entity.floor = self
        entities.insert(entity)
    }
    
    func weakAdd(_ entity: Entity, x: Int, y: Int) {
        guard x >= 0 && x < Self.width && y >= 0 && y < Self.height else { return }
        guard self[x, y] is Ground else { return }
        guard !entities.contains(where: { $0.x == x && $0.y == y }) else { return }
        
        (entity.x, entity.y) = (x, y)
        self.add(entity)
    }
    
    @discardableResult
    func remove(_ entity: Entity) -> Entity {
        entities.remove(entity)!
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
    
    static let width = 32
    static let height = 16
}

class Tile: Drawable {
    unowned(unsafe) let floor: Floor
    final var width: Int { 16 }
    final var height: Int { 16 }
    subscript(x: Int, y: Int) -> Color { .clear }
    
    init(_ floor: Floor) {
        self.floor = floor
    }
    
    var name: String { "Unknown" }
    
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
    
    override var name: String { "Ground" }
    
    override var mapColor: Color { .Pico.brown }
}

class Wall: Tile {
    override subscript(x: Int, y: Int) -> Color {
        Self.sheet[10, 17][x, y]
    }
    
    override var name: String { "Wall" }
}

class Stairs: Tile {
    let direction: Direction
    
    init(_ floor: Floor, _ direction: Direction) {
        self.direction = direction
        super.init(floor)
    }
    
    override subscript(x: Int, y: Int) -> Color {
        switch direction {
            case .up: Self.sheet[2, 6][x, y]
            case .down: Self.sheet[3, 6][x, y]
        }
    }
    
    override var name: String { "Stairs " + direction.textName }
    
    func use(_ entity: Entity) {
        let destination = switch direction {
            case .up: floor.world.floors[floor.depth - 1]
            case .down: floor.world.floors[floor.depth + 1]
        }
        
        for x in 0..<Floor.width {
            for y in 0..<Floor.height {
                if let tile = destination[x, y] as? Stairs, tile.direction != direction {
                    entity.floor.remove(entity)
                    (entity.x, entity.y) = (x, y)
                    destination.add(entity)
                    if entity === floor.world.primary {
                        floor.world.log("You take the stairs " + direction.textName + " and arrive at depth \(destination.depth)")
                    }
                }
            }
        }
    }
    
    enum Direction {
        case up, down
        
        var textName: String {
            switch self {
                case .up: "up"
                case .down: "down"
            }
        }
    }
}

class Spikes: Tile {
    
}
