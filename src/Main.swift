
import Assets

let interface = UnsafeTGAPointer(UI_TGA).grid(itemWidth: 16, itemHeight: 16)

let cursor = interface[0, 0]
let cursorPressed = interface[1, 0]
let pause = interface[2, 0]
let slot = Window(width: 16, height: 16)

// This has to be a class now to allow spaghetti input handling
final class Main: Game {
    var world = World()
    
    // This is set by the spaghetti click handlers. Unfortunately the complete layout system is broken without
    // existentials, which embedded swift does not have at this time.
    var pressedSlot: Int? = nil
    var hoveredItem: String? = nil
    
    // Called at a stable 60hz before frame.
    func update(input: borrowing Input) {
        world.update()
        
        if let usable = world.primaryAiming {
            if input.leftClick, let (x, y) = mouseOverTile(input.mouse!) {
                if let target = world.primary.floor.entities
                    .sorted(by: { $0 is Creature && !($1 is Creature) })
                    .first(where: { $0.x == x && $0.y == y })
                        { usable.performAimed(on: target); world.primaryAiming = nil }
            }
        } else if let index = pressedSlot {
            world.primary.primaryUseItem(index: index)
            world.activate()
            pressedSlot = nil
        } else if input.leftClick {
            if let (sx, sy) = mouseOverTile(input.mouse!) {
                world.activate(x: sx, y: sy)
            }
        }
    }
    
    var cameraX: Int { world.primary.x * 16 - target.width / 2 }  // BAD: HARDCODED OFFSET
    var cameraY: Int { world.primary.y * 16 - target.height / 2 } // BAD: HARDCODED OFFSET
    
    // Called every frame, refresh rate dependent.
    func frame(input: borrowing Input, target: inout some MutableDrawable) {
        target.clear(with: .init(luminosity: 24))
        
        // Draw world and entities offset by the camera
        target.withOverlay(x: cameraX, y: cameraY) { overlay in
            for x in 0..<Floor.width {
                for y in 0..<Floor.height {
                    let tile = world.primary.floor[x, y]
                    overlay.draw(tile, x: x * tile.width - 8, y: y * tile.height - 8) // BAD: HARDCODED OFFSET
                }
            }
            
            if let mouse = input.mouse, let (sx, sy) = mouseOverTile(mouse) {
                overlay.draw(
                    Rectangle(
                        width: 16,
                        height: 16,
                        color: world.primaryAiming == nil ? .init(luminosity: 255, alpha: 168) : .Pico.orange,
                        fill: false
                    ),
                    x: sx * 16 - 8,
                    y: sy * 16 - 8
                ) // BAD: HARDCODED OFFSET
            }
            
            if let floor = world.primary.floor {
                for entity in floor.entities.sorted(by: { $0.y < $1.y }).sorted(by: { $1 is Creature && !($0 is Creature) }) {
                    overlay.draw(
                        entity,
                        x: 16 * entity.x - entity.width / 2,     // BAD: HARDCODED OFFSET
                        y: 16 * entity.y - entity.height * 3 / 4 // BAD: HARDCODED OFFSET
                    )
                }
            }
        }
        
        // Darkness effect
        if world.primary.floor.depth > 0 {
            target.clear(with: .init(luminosity: 0, alpha: UInt8(64 + 32 * (world.primary.floor.depth - 1))))
        }
        
//        if let mouse = input.mouse, let (tx, ty) = mouseOverTile(mouse) {
//            target.text("x: \(tx) y: \(ty)", x: 200, y: 2)
//        }
        
        // UI
//        target.draw(pause, x: 0, y: 0)
        drawHotbar(input: input, into: &target)
        drawLog(into: &target)
//        drawMap(into: &target)
        
        target.draw(Rectangle(width: target.width, height: 13, color: .init(luminosity: 0, alpha: 128)))
        target.text(
            "Depth \(world.primary.floor.depth)"
            + " - Health \(world.primary.health)/\(world.primary.maxHealth)"
            + " - Level \(world.primary.level) " + world.primary.description,
            x: 4,
            y: 4
        )
        
        if let mouse = input.mouse {
            if let selected = mouseOverTile(mouse) {
                let tile = world.primary.floor[selected.x, selected.y]
                
                var description = "Selected: " + tile.name
                
                let selectedEntities = world.primary.floor.entities.filter { $0.x == selected.x && $0.y == selected.y }
                if !selectedEntities.isEmpty { description.append(contentsOf: String(" - Contains: ")) }
                
                for entity in world.primary.floor.entities where entity.x == selected.x && entity.y == selected.y {
                    description.append(contentsOf: "Level \(entity.level) " + entity.description + " - Health \(entity.health)/\(entity.maxHealth), ")
                }
                if !selectedEntities.isEmpty { description.removeLast(2) }
                
                target.draw(
                    Text(description)
                        .pad(.all, by: 1)
                        .colorMap(.clear, to: .init(luminosity: 0, alpha: 128)),
                    x: 4 - 1,
                    y: 13 + 2 - 1
                )
            }
            
            target.draw(mouse.left ? cursorPressed : cursor, x: mouse.x - 1, y: mouse.y - 1)
        }
    }
    
    // This code is so bad...
    func mouseOverTile(_ mouse: Input.Mouse) -> (x: Int, y: Int)? { // BAD: HARDCODED OFFSET
        let ret: (x: Int, y: Int) = ((cameraX + mouse.x + 8) / 16, (cameraY + mouse.y + 8) / 16)
        return ret.x >= 0 && ret.x < Floor.width && ret.y >= 0 && ret.y < Floor.height
            ? ret
            : nil
    }
    
    func drawHotbar(input: borrowing Input, into target: inout some MutableDrawable) {
        guard let primary = world.primary as? Creature else { return }
        guard let storage = primary.storageItem else { return }
        
        let hotbarWidth = slot.width * storage.capacity - 1 * storage.capacity
        
        if storage.capacity > 0 {
            target.draw(
                Rectangle(width: hotbarWidth + 3, height: slot.height + 2, color: .black),
                x: target.width / 2 - hotbarWidth / 2 - 1,
                y: target.height - slot.height - 3
            )
            
            for i in 0..<storage.capacity {
                target.draw(
                    slot,
                    x: target.width / 2 - hotbarWidth / 2 + slot.width * i - 1 * i,
                    y: target.height - slot.height - 2
                )
            }
        }
        
        for (index, item) in storage.enumerated() {
            target.draw(
                item,
                x: target.width / 2 - hotbarWidth / 2 - 8 + (16 * index) - (1 * index), // wtf
                y: target.height - slot.height - 17
            )
            
            // Very bad hardcoded misuse of input processing
            slot.onClick { self.pressedSlot = index }
                .process(
                    input: input,
                    x: target.width / 2 - hotbarWidth / 2 + slot.width * index - 1 * index,
                    y: target.height - slot.height - 2
                )
            
            slot.onHover { self.hoveredItem = item.description }
                .process(
                    input: input,
                    x: target.width / 2 - hotbarWidth / 2 + slot.width * index - 1 * index,
                    y: target.height - slot.height - 2
                )
        }
        
        if let aimed = world.primaryAiming {
            let text = Text("Using " + aimed.description).pad(.all, by: 1).colorMap(.clear, to: .init(luminosity: 0, alpha: 128))
            
            target.draw(
                text,
                x: target.width / 2 - text.width / 2,
                y: target.height - 28 - 7
            )
        }
        
        if let item = hoveredItem {
            let text = Text(item).pad(.all, by: 1).colorMap(.clear, to: .init(luminosity: 0, alpha: 128))
            
            target.draw(
                text,
                x: target.width / 2 - text.width / 2,
                y: target.height - 28
            )
            
            hoveredItem = nil
        }
        
        target.draw(
            storage,
            x: target.width / 2 - hotbarWidth / 2 - 24,
            y: target.height - slot.height - 17
        )
    }
    
    func drawLog(into target: inout some MutableDrawable) {
        for (i, entry) in world.logEntries.reversed().enumerated() {
            var color = entry.color
            color.a = UInt8(clamping: entry.timeToLive * 8)
            
            target.draw(
                Text(entry.message, color: color)
                    .pad(.all, by: 1)
                    .colorMap(.clear, to: .init(luminosity: 0, alpha: 128)),
                x: 2,
                y: target.height - 12 - slot.height - ((TileFonts.pico.inner.itemHeight + 2) * (i + 1)),
//                y: target.height - 6 - slot.height - ((TileFonts.pico.inner.itemHeight + 2) * (i + 1)),
            )
        }
    }
    
    func drawMap(into target: inout some MutableDrawable) {
        for x in 0..<Floor.width {
            for y in 0..<Floor.height {
                let tile = world.primary.floor[x, y]
                let symbol = Rectangle(width: 2, height: 2, color: tile.mapColor)
                target.draw(
                    symbol,
                    x: target.width - 4 - (Floor.width - x) * symbol.width,
                    y: y * symbol.height + 4
                )
            }
        }
    }
    
    enum State {
        case movement
        case targeting
    }
}

struct Window: Drawable {
    let width: Int
    let height: Int
    
    init(width: Int, height: Int) {
        self.width = width
        self.height = height
    }
    
    subscript(x: Int, y: Int) -> Color {
        Rectangle(width: 16, height: 16, color: .Picotron.brown, fill: false).colorMap(.clear, to: .Picotron.darkBrown)[x, y]
    }
}
