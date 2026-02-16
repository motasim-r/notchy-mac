import Foundation

enum ScrollEngine {
    static let throttleFps: Double = 45

    static func nextOffset(current: Double, speedPxPerSec: Double, deltaSec: Double, maxOffset: Double) -> (offset: Double, reachedEnd: Bool) {
        let next = min(current + speedPxPerSec * max(0, deltaSec), maxOffset)
        let reachedEnd = maxOffset > 0 && next >= maxOffset
        return (next, reachedEnd)
    }
}
