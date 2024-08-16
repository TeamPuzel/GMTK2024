
import Assets

let interface = UnsafeTGAPointer(UI_TGA)
    .grid(itemWidth: 16, itemHeight: 16)

let cursor = interface[0, 0]
let cursorPressed = interface[1, 0]

let characterSheet = UnsafeTGAPointer(SHEET_TGA)
    .grid(itemWidth: 32, itemHeight: 32)

let lua = characterSheet[0, 0]

let tileSheet = UnsafeTGAPointer(SHEET_TGA)
    .grid(itemWidth: 32, itemHeight: 32)

struct Main: Game {
    mutating func frame(input: borrowing Input, target: inout some MutableDrawable) {
        target.clear(with: .init(luminosity: 64))
        
        target.draw(UnsafeTGAPointer(SHEET_TGA).slice(x: 0, y: 32, width: 16 * 4, height: 16 * 4), x: 0, y: 16 * 4)
        
        target.text("Hello, GMTK!", x: 2, y: 2, color: .Pico.white)
        target.draw(lua, x: 2, y: 10)
        
        target.draw(input.mouse!.left ? cursorPressed : cursor, x: input.mouse!.x - 1, y: input.mouse!.y - 1)
    }
}
