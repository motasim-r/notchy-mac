import QuartzCore

final class DisplayLinkTickerIOS: TickerProtocol {
    var onTick: ((CFTimeInterval) -> Void)?

    private var displayLink: CADisplayLink?
    private var lastTimestamp: CFTimeInterval?

    func start() {
        guard displayLink == nil else {
            return
        }

        let link = CADisplayLink(target: self, selector: #selector(handleTick(_:)))
        if #available(iOS 15.0, *) {
            link.preferredFrameRateRange = CAFrameRateRange(minimum: 30, maximum: 60, preferred: 60)
        }
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    func stop() {
        displayLink?.invalidate()
        displayLink = nil
        lastTimestamp = nil
    }

    @objc private func handleTick(_ link: CADisplayLink) {
        defer {
            lastTimestamp = link.timestamp
        }

        guard let previous = lastTimestamp else {
            return
        }

        let delta = max(0, link.timestamp - previous)
        onTick?(delta)
    }
}
