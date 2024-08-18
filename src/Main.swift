
import Assets

let interface = UnsafeTGAPointer(UI_TGA).grid(itemWidth: 16, itemHeight: 16)

let cursor = interface[0, 0]
let cursorPressed = interface[1, 0]
let pause = interface[2, 0]
let slot = interface.inner.slice(x: 0, y: 16, width: 22, height: 22)

struct Main: Game {
    var world = World()
    
    // Called at a stable 60hz before frame.
    mutating func update(input: borrowing Input) {
        world.update()
        
        if input.leftClick { world.log("You click the screen") }
    }
    
    // Called every frame, refresh rate dependent.
    mutating func frame(input: borrowing Input, target: inout some MutableDrawable) {
        target.clear(with: .init(luminosity: 48))
        
        // Draw world and entities offset by the camera
        target.withOverlay(
            x: world.primary.x + target.width / 2,
            y: world.primary.y + target.height / 2
        ) { overlay in
            for x in 0..<Floor.width {
                for y in 0..<Floor.height {
                    let tile = world.floor[x, y]
                    overlay.draw(tile, x: x * tile.width, y: y * tile.height)
                }
            }
            
            if let floor = world.primary.floor {
                for entity in floor.entities {
                    overlay.draw(entity, x: entity.x - entity.width / 2, y: entity.y - entity.height / 2)
                }
            }
        }
        
        // UI
        target.draw(pause, x: 0, y: 0)
        drawHotbar(into: &target)
        drawLog(into: &target)
        
        if let mouse = input.mouse {
            target.draw(mouse.left ? cursorPressed : cursor, x: mouse.x - 1, y: mouse.y - 1)
        }
    }
    
    func drawHotbar(into target: inout some MutableDrawable) {
        let hotbarWidth = slot.width * 10 - 10
        
        for i in 0...9 {
            target.draw(
                slot,
                x: target.width / 2 - hotbarWidth / 2 + slot.width * i - 1 * i,
                y: target.height - slot.height - 2
            )
        }
    }
    
    func drawLog(into target: inout some MutableDrawable) {
        for (i, entry) in world.logEntries.reversed().enumerated() {
            var color = entry.color
            color.a = UInt8(clamping: entry.timeToLive * 8)
            
            target.text(
                entry.message,
                x: 2,
                y: target.height - 2 - slot.height - ((TileFonts.pico.inner.itemHeight + 1) * (i + 1)),
                color: color
            )
        }
    }
}
