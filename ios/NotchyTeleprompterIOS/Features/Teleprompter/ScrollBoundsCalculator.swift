import CoreGraphics

enum ScrollBoundsCalculator {
    static func maxOffset(contentHeight: CGFloat, viewportHeight: CGFloat) -> CGFloat {
        max(0, contentHeight - viewportHeight)
    }
}
