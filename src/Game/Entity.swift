
import Assets

class Entity: Drawable {
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
    
    final var isPrimary: Bool { floor.world.primary === self }
    
    convenience init(x: Int, y: Int) {
        self.init()
        self.x = x
        self.y = y
    }
    
    var name: String { "Unknown" }
    var description: String { name }
    
    var isStorable: Bool { false }
    
    var experienceValue: Int { 0 }
    var experience = 0
    
    var level = 1
    var maxHealth: Int { 1 }
    var attack: ClosedRange<Int> { 0...0 }
    lazy var health = maxHealth
    
    func update() {}
    func frame() {}
    
    /// Turn method for the player controlled entity.
    func makePrimaryTurn(x: Int, y: Int) -> Bool {
        return false
    }
    
    func primaryUseItem(index: Int) {
        
    }
    
    /// Turn method for AI controlled entities.
    func makeTurn() {
        
    }
    
    func becomePrimary() {
        floor.world.primary = self
    }
    
    func die(from entity: Entity) {
        if self.isPrimary {
            floor.world.log("You are dead", color: .Pico.red, duration: 999999)
            floor.world.primaryAiming = nil
            let grave = Grave()
            grave.position = self.position
            floor.add(grave)
            floor.world.primary = grave
        } else {
            floor.world.log(name + " dies")
        }
        
        floor.remove(self)
    }
    
    func interact(_ entity: Entity) {
        let damage = Int.random(in: entity.attack)
        if self.isPrimary {
            floor.world.log("You take \(damage) damage from " + (entity.isPrimary ? "You" : entity.name))
        } else {
            floor.world.log(name + " takes \(damage) damage from " + (entity.isPrimary ? "You" : entity.name))
        }
        self.health -= damage
        
        if self.health <= 0 {
            self.die(from: entity)
            
            if experienceValue > 0 && entity.isPrimary {
                floor.world.log((entity.isPrimary ? "You gain" : entity.name + " gains") + " \(experienceValue) experience")
                entity.experience += experienceValue
            }
        }
    }
    
    static let sheet: DrawableGrid<Image> = UnsafeTGAPointer(SHEET_TGA).flatten().grid(itemWidth: 32, itemHeight: 32)
}

extension Entity: Hashable {
    public static func == (lhs: Entity, rhs: Entity) -> Bool { lhs === rhs }
    public func hash(into hasher: inout Hasher) { hasher.combine(ObjectIdentifier(self)) }
}

// MARK: - Creatures

class Creature: Entity {
    var storageItem: StorageItem? = nil
    
    override func die(from entity: Entity) {
        super.die(from: entity)
        
        if let storageItem {
            storageItem.drop()
        }
    }
    
    override func primaryUseItem(index: Int) {
        (storageItem?.storage[index] as? Usable)?.use(on: self)
    }
    
    override func makePrimaryTurn(x: Int, y: Int) -> Bool {
        switch (x, y) {
            case
                (self.x + 1, self.y)     where floor.entities.contains { $0.x == x && $0.y == y },
                (self.x - 1, self.y)     where floor.entities.contains { $0.x == x && $0.y == y },
                (self.x, self.y + 1)     where floor.entities.contains { $0.x == x && $0.y == y },
                (self.x, self.y - 1)     where floor.entities.contains { $0.x == x && $0.y == y },
                (self.x + 1, self.y + 1) where floor.entities.contains { $0.x == x && $0.y == y },
                (self.x - 1, self.y + 1) where floor.entities.contains { $0.x == x && $0.y == y },
                (self.x - 1, self.y - 1) where floor.entities.contains { $0.x == x && $0.y == y },
                (self.x + 1, self.y - 1) where floor.entities.contains { $0.x == x && $0.y == y }:
                    for entity in floor.entities where entity.x == x && entity.y == y {
                        entity.interact(self)
                    }
                    return true
            
            case (self.x + 1, self.y): self.x += 1
            case (self.x - 1, self.y): self.x -= 1
            case (self.x, self.y + 1): self.y += 1
            case (self.x, self.y - 1): self.y -= 1
                
            case (self.x + 1, self.y + 1): self.x += 1; self.y += 1
            case (self.x - 1, self.y + 1): self.x -= 1; self.y += 1
            case (self.x - 1, self.y - 1): self.x -= 1; self.y -= 1
            case (self.x + 1, self.y - 1): self.x += 1; self.y -= 1
                
            case (self.x, self.y): break
                
            case (_, _): return false
        }
        
        let tile = floor[self.x, self.y]
        
        if let stairs = tile as? Stairs {
            stairs.use(self)
        }
        
        return true
    }
}

class Elf: Creature {
    override var name: String { "Elf" }
    override var description: String { "Elf Mage" }
    
    override var maxHealth: Int { 4 + level * 2 }
    override var attack: ClosedRange<Int> { 1...(2 * level) }
    
    override subscript(x: Int, y: Int) -> Color { Self.sheet[0, 0][x, y] }
    
    override func update() {
        super.update()
        self.storageItem?.update()
        
        if experience > 4 && level == 1 {
            level = 2; floor.world.log("Level up, damage \(attack.lowerBound)-\(attack.upperBound)", color: .Pico.green)
        }
        if experience > 8 && level == 2 {
            level = 3; floor.world.log("Level up, damage \(attack.lowerBound)-\(attack.upperBound)", color: .Pico.green)
        }
    }
    
    override init() {
        super.init()
        self.storageItem = OldBackpack(equippedBy: self)
    }
}

class Grave: Entity {
    override var name: String { "Grave" }
    
    override var maxHealth: Int { 30 }
    
    override subscript(x: Int, y: Int) -> Color { Self.sheet[0, 1][x, y] }
}

class Skeleton: Creature {
    override var name: String { "Skeleton" }
    var delay: Int = 0
    
    override var experienceValue: Int { 2 * level }
    
    override var maxHealth: Int { 2 + level * 2 }
    override var attack: ClosedRange<Int> { 0...(1 + level) }
    
    override subscript(x: Int, y: Int) -> Color { Self.sheet[1, 0 + (level - 1)][x, y] }
    
    override func interact(_ entity: Entity) {
        super.interact(entity)
        delay = 1
    }
    
    override func makeTurn() {
        delay += 1
        guard delay % 2 == 0 else { return }
//        guard floor.world.primary is Elf else { return }
        
        let (px, py) = (floor.world.primary.x, floor.world.primary.y)
        var move = self.position
        
        if px > x { move.x += 1 }
        if px < x { move.x -= 1 }
        if py > y { move.y += 1 }
        if py < y { move.y -= 1 }
        
        if floor.entities.contains(where: { $0.x == move.x && $0.y == move.y }) {
            for entity in floor.entities where entity.x == move.x && entity.y == move.y {
                entity.interact(self)
            }
        } else {
            self.position = move
        }
    }
    
    override func die(from entity: Entity) {
//        if Int.random(in: 0..<8) == 0 { floor.add(Potion(x: x, y: y)) }
        super.die(from: entity)
    }
}

class Slime: Creature {
    override var name: String { "Slime" }
    var delay: Int = 0
    
    override var experienceValue: Int { 1 * level }
    
    override var maxHealth: Int { 2 }
    override var attack: ClosedRange<Int> { 0...2 }
    
    override subscript(x: Int, y: Int) -> Color { Self.sheet[0, 2][x, y] }
    
    override func interact(_ entity: Entity) {
        super.interact(entity)
    }
    
    override func makeTurn() {
        var move = self.position
        
        switch Int.random(in: 1...4) {
            case 1: move.x += 1
            case 2: move.x -= 1
            case 3: move.y += 1
            case 4: move.y -= 1
                
            case _: fatalError()
        }
        
        guard move.x >= 0 && move.x < Floor.width && move.y >= 0 && move.y < Floor.height else { return }
        
        if floor.entities.contains(where: { $0.x == move.x && $0.y == move.y }) {
            for entity in floor.entities where entity.x == move.x && entity.y == move.y {
                entity.interact(self)
            }
        } else {
            self.position = move
        }
    }
    
    override func die(from entity: Entity) {
        super.die(from: entity)
    }
}

class SkeletonKing: Skeleton {
    override var name: String { "Skeleton King" }
    override var delay: Int { get { 2 } set {} }
    
    override var level: Int { get { 5 } set {} }
    
    override var experienceValue: Int { 20 }
    
    override var maxHealth: Int { 20 }
    override var attack: ClosedRange<Int> { 2...4 }
    
    override subscript(x: Int, y: Int) -> Color { Self.sheet[1, 3][x, y] }
    
    override func die(from entity: Entity) {
        if !self.isPrimary { floor.add(Amulet(x: x, y: y)) }
        storageItem = nil
        super.die(from: entity)
    }
}

// MARK: - Items

class Item: Entity {
    override var isStorable: Bool { true }
}

class Equippable: Item {
    unowned(unsafe) var equippedBy: Creature?
    
    convenience init(equippedBy creature: Creature) {
        self.init()
        self.equippedBy = creature
    }
    
    func equip(by creature: Creature) throws(EquipError) {
        self.equippedBy = creature
        if creature.isPrimary { creature.floor.world.log("You equip " + name) }
        if floor.entities.contains(self) { floor.remove(self) }
    }
    
    @discardableResult
    func unequip() throws(UnequipError) -> Self {
        let creature = self.equippedBy!
        (self.x, self.y) = (creature.x, creature.y)
        creature.floor.add(self)
        if creature.isPrimary { floor.world.log("You unequip " + name) }
        
        self.equippedBy = nil
        return self
    }
    
    @discardableResult
    final func drop() -> Self {
        let creature = self.equippedBy!
        (self.x, self.y) = (creature.x, creature.y)
        creature.floor.add(self)
        if creature == creature.floor.world.primary { floor.world.log("You unequip " + name) }
        
        self.equippedBy = nil
        return self
    }
    
    enum EquipError: Error {
        
    }

    enum UnequipError: Error {
        case cursed
    }
}

class Usable: Item {
    func use(on entity: Entity) {
        (entity as? Creature)?.storageItem?.delete(self)
    }
    
    func performAimed(on entity: Entity) {
        
    }
    
    override func interact(_ entity: Entity) {
        guard let creature = entity as? Creature else { return }
        guard creature.isPrimary else { return }
        
        do {
            try creature.storageItem?.insert(self) ?? creature.floor.world.log("You do not have anywhere to store the item.")
            // creature.floor.world.log("You pick up 1 " + name)
        } catch let error {
            switch error {
                case .outOfSpaceFor(_): creature.floor.world.log("You do not have any space left to store the item.")
                case .notStorable(_): break
            }
        }
    }
}

class Scroll: Usable {
    override var name: String { "Empty Scroll" }
    
    override subscript(x: Int, y: Int) -> Color { Self.sheet[3, 1][x, y] }
    
    override func use(on entity: Entity) {
        if entity.isPrimary { entity.floor.world.enterPrimaryAimMode(of: self) }
        super.use(on: entity)
    }
    
    override func performAimed(on entity: Entity) {
        
    }
    
    static func random(x: Int, y: Int) -> Scroll {
        switch Int.random(in: 1...6) {
            case 1: FireScroll(x: x, y: y)
            case 2: SwapScroll(x: x, y: y)
            case 3: HealthScroll(x: x, y: y)
            case 4: PositionScroll(x: x, y: y)
            case 5: SlimeScroll(x: x, y: y)
            case 6: SlimeChaosScroll(x: x, y: y)
                
            case _: fatalError()
        }
    }
}

class FireScroll: Scroll {
    override var name: String { "Scroll of Fire" }
    
    override var attack: ClosedRange<Int> { 8...16 }
    
    override func performAimed(on entity: Entity) {
        entity.interact(self)
    }
}

class SwapScroll: Scroll {
    override var name: String { "Scroll of Mind Exchange" }
    
    override func performAimed(on entity: Entity) {
        entity.becomePrimary()
    }
}

class GoldenTouchScroll: Scroll {
    override var name: String { "Scroll of Golden Touch" }
    
    override func performAimed(on entity: Entity) {
        let pouch = CoinPouch(x: entity.x, y: entity.y, count: entity.experienceValue * 16)
        entity.floor.add(pouch)
        if entity.isPrimary { pouch.becomePrimary() }
        entity.floor.remove(entity)
    }
}

class SlimeScroll: Scroll {
    override var name: String { "Scroll of Slime Form" }
    
    override func performAimed(on entity: Entity) {
        let slime = Slime(x: entity.x, y: entity.y)
        entity.floor.add(slime)
        if entity.isPrimary { slime.becomePrimary() }
        entity.floor.remove(entity)
    }
}

class HealthScroll: Scroll {
    override var name: String { "Scroll of Full Health" }
    
    override func performAimed(on entity: Entity) {
        entity.health = entity.maxHealth
    }
}

class PositionScroll: Scroll {
    override var name: String { "Scroll of Position Exchange" }
    
    override func performAimed(on entity: Entity) {
        let pos = entity.floor.world.primary.position
        entity.floor.world.primary.position = entity.position
        entity.position = pos
    }
}

class SlimeChaosScroll: Scroll {
    override var name: String { "Scroll of Slime Chaos" }
    
    override func performAimed(on entity: Entity) {
        let (x, y) = (entity.x, entity.y)
        
        entity.floor.weakAdd(Slime(), x: x + 1, y: y)
        entity.floor.weakAdd(Slime(), x: x - 1, y: y)
        entity.floor.weakAdd(Slime(), x: x, y: y + 1)
        entity.floor.weakAdd(Slime(), x: x, y: y - 1)
    }
}

class Amulet: Item {
    override var name: String { "Mysterious Amulet" }
    
    override var level: Int { get { 9000 } set {} }
    
    override var maxHealth: Int { 9000 }
    
    override subscript(x: Int, y: Int) -> Color { Self.sheet[4, 0][x, y] }
    
    override func interact(_ entity: Entity) {
        floor.world.log("You find a mysterious amulet.", duration: 1000)
        floor.world.log("For reasons unknown to you, you are free of the curse", duration: 1000)
        floor.world.log("and the game is now over.", duration: 1000)
        floor.world.log("Thank you for playing :)", color: .Pico.green, duration: 1100)
        if let creature = entity as? Creature, let storage = creature.storageItem, storage is CursedBackpack {
            creature.storageItem = nil
        }
        floor.remove(self)
    }
}

class CoinPouch: Item {
    let count: Int
    
    override var name: String { "Coin Pouch" }
    override var description: String { "Pouch of \(count) " + (count == 1 ? "coin" : "coins") }
    
    init(x: Int, y: Int, count: Int) {
        self.count = count
        super.init()
        self.x = x
        self.y = y
    }
    
    override subscript(x: Int, y: Int) -> Color { Self.sheet[2, 1][x, y] }
}

class Potion: Usable {
    override var name: String { "Potion" }
    
    override subscript(x: Int, y: Int) -> Color { Self.sheet[5, 0][x, y] }
    
    override func use(on entity: Entity) {
        entity.health = (entity.health + 4).clamped(to: 0...entity.maxHealth)
        entity.floor.world.log((entity.isPrimary ? "You are" : entity.name + " is") + " healed by 4", color: .Pico.green)
        super.use(on: entity)
    }
}

// MARK: - Storage

class StorageItem: Equippable, Sequence {
    var capacity: Int { 0 }
    var storage: [Entity] = []
    
    final func insert(_ entity: Entity) throws(StorageError) {
        guard storage.count < capacity else { throw .outOfSpaceFor(entity) }
        guard entity.isStorable else { throw .notStorable(entity) }
        
        entity.floor.remove(entity)
        storage.append(entity)
    }
    
    final func remove(by creature: Creature, at index: Int) -> Entity {
        let item = storage[index]
        creature.floor.add(item)
        return item
    }
    
    final func delete(_ entity: Entity) {
        storage.removeAll { $0 === entity }
    }
    
    override func interact(_ entity: Entity) {
        guard let creature = entity as? Creature else { return }
        
        if let existing = creature.storageItem {
            do {
                try existing.unequip()
                try! self.equip(by: creature)
            } catch let error {
                switch error {
                    case .cursed:
                        floor.world.log("You try to take off your current item", color: .Pico.red)
                        floor.world.log("but curiously enough you find yourself unable to", color: .Pico.red)
                }
            }
        } else {
            try! self.equip(by: creature)
        }
    }
    
    override func equip(by creature: Creature) throws(EquipError) {
        creature.storageItem = self
        try super.equip(by: creature)
    }
    
    @discardableResult
    override func unequip() throws(UnequipError) -> Self {
        self.equippedBy!.storageItem = nil
        return try super.unequip()
    }
    
    func makeIterator() -> [Entity].Iterator {
        storage.makeIterator()
    }
    
    enum StorageError: Error {
        case outOfSpaceFor(_ entity: Entity)
        case notStorable(_ entity: Entity)
    }
}

class OldBackpack: StorageItem {
    override var capacity: Int { 1 }
    
    override var name: String { "Old backpack" }
    
    override subscript(x: Int, y: Int) -> Color { Self.sheet[2, 0][x, y] }
}

class SkeletonBackpack: StorageItem {
    override var capacity: Int { 2 }
    
    override init() {
        super.init()
        self.storage.append(Scroll.random(x: 0, y: 0))
    }
    
    override var name: String { "Skeleton backpack" }
    
    override subscript(x: Int, y: Int) -> Color { Self.sheet[2, 2][x, y] }
}

class CursedBackpack: StorageItem {
    override var capacity: Int {
        return if let owner = equippedBy {
            owner.maxHealth - owner.health + 1
        } else {
            999
        }
    }
    
    override func equip(by creature: Creature) throws(EquipError) {
        try super.equip(by: creature)
        if creature.isPrimary {
            creature.floor.world.log("Something feels off about this backpack.", color: .Pico.red)
        }
    }
    
    @discardableResult
    override func unequip() throws(UnequipError) -> Self {
        throw .cursed
    }
    
    override var name: String { "Strange backpack" }
    
    override subscript(x: Int, y: Int) -> Color { Self.sheet[3, 0][x, y] }
    
    override func update() {
        if storage.count > capacity {
            storage = Array(storage[0..<capacity])
            
            equippedBy?.floor.world.log("The backpack shrinks and consumes excess items", color: .Pico.red)
            equippedBy?.floor.world.log("never to be seen again.", color: .Pico.red)
        }
    }
}
