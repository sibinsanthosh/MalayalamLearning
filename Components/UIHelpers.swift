import SwiftUI

// Small helper to scale sizes proportionally based on a reference width (iPhone 8/11 width ~375)
func scaled(_ base: CGFloat) -> CGFloat {
    let reference: CGFloat = 375.0
    let screenW = UIScreen.main.bounds.width
    // Limit scale to a reasonable range so things don't become huge on very large iPads
    let scale = min(max(screenW / reference, 1.0), 2.0)
    return base * scale
}

/// Maximum content width for iPad screens where a column layout is preferred.
/// Use with `.frame(maxWidth: iPadContentMaxWidth)` inside a centred HStack.
let iPadContentMaxWidth: CGFloat = 700

/// Maximum content width for game screens on iPad where a narrower column
/// keeps interactive elements (buttons, grids) at a comfortable size.
let iPadGameContentMaxWidth: CGFloat = 640
