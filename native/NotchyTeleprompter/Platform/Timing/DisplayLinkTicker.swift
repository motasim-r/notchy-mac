import CoreVideo
import Foundation
import QuartzCore

final class DisplayLinkTicker {
    var onTick: ((Double) -> Void)?

    private var displayLink: CVDisplayLink?
    private var fallbackTimer: DispatchSourceTimer?
    private var lastTimestamp: Double?
    private var isRunning = false

    init() {
        setupDisplayLink()
    }

    deinit {
        stop()
    }

    func start() {
        guard !isRunning else {
            return
        }

        isRunning = true
        lastTimestamp = nil

        if let displayLink {
            let result = CVDisplayLinkStart(displayLink)
            if result != kCVReturnSuccess {
                print("[ticker] CVDisplayLink start failed, switching to fallback timer")
                startFallbackTimer()
            }
        } else {
            startFallbackTimer()
        }
    }

    func stop() {
        guard isRunning else {
            return
        }

        isRunning = false
        lastTimestamp = nil

        if let displayLink {
            CVDisplayLinkStop(displayLink)
        }

        fallbackTimer?.cancel()
        fallbackTimer = nil
    }

    private func setupDisplayLink() {
        var link: CVDisplayLink?
        guard CVDisplayLinkCreateWithActiveCGDisplays(&link) == kCVReturnSuccess, let link else {
            displayLink = nil
            return
        }

        let unmanagedSelf = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        CVDisplayLinkSetOutputCallback(
            link,
            { _, _, outputTime, _, _, userInfo in
                guard let userInfo else {
                    return kCVReturnSuccess
                }

                let ticker = Unmanaged<DisplayLinkTicker>.fromOpaque(userInfo).takeUnretainedValue()
                let timestamp = Double(outputTime.pointee.videoTime) / Double(outputTime.pointee.videoTimeScale)
                ticker.forward(timestamp: timestamp)
                return kCVReturnSuccess
            },
            unmanagedSelf
        )

        displayLink = link
    }

    private func forward(timestamp: Double) {
        DispatchQueue.main.async { [weak self] in
            self?.process(timestamp: timestamp)
        }
    }

    private func process(timestamp: Double) {
        guard isRunning else {
            return
        }

        if let previous = lastTimestamp {
            onTick?(max(0, timestamp - previous))
        }

        lastTimestamp = timestamp
    }

    private func startFallbackTimer() {
        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now(), repeating: .milliseconds(16))

        var previous = CACurrentMediaTime()
        timer.setEventHandler { [weak self] in
            let now = CACurrentMediaTime()
            let delta = max(0, now - previous)
            previous = now
            self?.onTick?(delta)
        }

        timer.resume()
        fallbackTimer = timer
    }
}
