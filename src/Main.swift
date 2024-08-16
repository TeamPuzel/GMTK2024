
import Assets

let sheet = UnsafeTGAPointer(SHEET_TGA)
    .grid(itemWidth: 16, itemHeight: 16)

let stairs = sheet[2, 0].scaled(x: 2)

struct Main: Game {
    mutating func frame(input: borrowing Input, target: inout some MutableDrawable) {
        target.clear(with: .Pico.darkBlue)
        
        target.text("Hello, world!", x: 2, y: 2, color: .Pico.white)
        target.draw(stairs, x: 2, y: 10)
        
        target.draw(Images.Interface.cursor, x: input.mouse!.x - 1, y: input.mouse!.y - 1)
    }
}
