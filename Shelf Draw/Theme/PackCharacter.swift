import SwiftUI

enum PackCharacter {
    static let spatialBounce = 0.00
    static let riseDuration = 0.42
    static let cardRadius: CGFloat = 22
    static let surface = "material"
}

enum PackType {
    static func display(_ style: Font.TextStyle = .title2, _ weight: Font.Weight = .bold) -> Font {
        .system(style, design: .rounded, weight: weight)
    }
}
