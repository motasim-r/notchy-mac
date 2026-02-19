import CoreVideo
import Foundation
import QuartzCore

final class DisplayLinkTicker {
    var onTick: ((Double) -> Void)?

    private enum Backend {
        case displayLink
        case fallbackTimer
    }

    private enum FallbackReason {
        case noTicks
        case invalidDeltas
    }

    private var displayLink: CVDisplayLink?
    private var fallbackTimer: DispatchSourceTimer?
    private var lastTimestamp: Double?
    private var backend: Backend?
    private var isRunning = false
    private var displayLinkWatchdog: DispatchWorkItem?
    private var hasReceivedValidDisplayLinkTick = false
    private var consecutiveInvalidDisplayLinkDeltas = 0

    private let noTickWatchdogDelay: TimeInterval = 0.45
    private let nearZeroDeltaThreshold = 1e-6
    private let invalidDeltaFallbackThreshold = 12

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
        backend = nil
        hasReceivedValidDisplayLinkTick = false
        consecutiveInvalidDisplayLinkDeltas = 0

        if let displayLink {
            let result = CVDisplayLinkStart(displayLink)
            if result != kCVReturnSuccess {
                switchToFallback(reason: .noTicks)
            } else {
                backend = .displayLink
                log("display-link started")
                armDisplayLinkWatchdog()
            }
        } else {
            switchToFallback(reason: .noTicks)
        }
    }

    func stop() {
        guard isRunning else {
            return
        }

        isRunning = false
        lastTimestamp = nil
        backend = nil
        hasReceivedValidDisplayLinkTick = false
        consecutiveInvalidDisplayLinkDeltas = 0

        cancelDisplayLinkWatchdog()

        if let displayLink {
            CVDisplayLinkStop(displayLink)
        }

        fallbackTimer?.cancel()
        fallbackTimer = nil

        log("stopped")
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
                ticker.forward(hostTime: outputTime.pointee.hostTime)
                return kCVReturnSuccess
            },
            unmanagedSelf
        )

        displayLink = link
    }

    private func forward(hostTime: UInt64) {
        DispatchQueue.main.async { [weak self] in
            self?.processDisplayLink(hostTime: hostTime)
        }
    }

    private func processDisplayLink(hostTime: UInt64) {
        guard isRunning else {
            return
        }

        guard backend == .displayLink else {
            return
        }

        guard let timestamp = hostTimeToSeconds(hostTime) else {
            consecutiveInvalidDisplayLinkDeltas += 1
            if consecutiveInvalidDisplayLinkDeltas >= invalidDeltaFallbackThreshold {
                switchToFallback(reason: .invalidDeltas)
            }
            return
        }

        if let previous = lastTimestamp {
            let delta = timestamp - previous
            if !delta.isFinite || delta <= nearZeroDeltaThreshold {
                consecutiveInvalidDisplayLinkDeltas += 1
                lastTimestamp = timestamp
                if consecutiveInvalidDisplayLinkDeltas >= invalidDeltaFallbackThreshold {
                    switchToFallback(reason: .invalidDeltas)
                }
                return
            }

            consecutiveInvalidDisplayLinkDeltas = 0
            hasReceivedValidDisplayLinkTick = true
            cancelDisplayLinkWatchdog()
            onTick?(delta)
        }

        lastTimestamp = timestamp
    }

    private func startFallbackTimer() {
        guard fallbackTimer == nil else {
            return
        }

        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now(), repeating: .milliseconds(16))

        var previous = CACurrentMediaTime()
        timer.setEventHandler { [weak self] in
            guard
                let self,
                self.isRunning,
                self.backend == .fallbackTimer
            else {
                return
            }

            let now = CACurrentMediaTime()
            let delta = max(0, now - previous)
            previous = now
            self.onTick?(delta)
        }

        timer.resume()
        fallbackTimer = timer
    }

    private func armDisplayLinkWatchdog() {
        cancelDisplayLinkWatchdog()

        let task = DispatchWorkItem { [weak self] in
            guard let self else { return }
            guard self.isRunning, self.backend == .displayLink, !self.hasReceivedValidDisplayLinkTick else {
                return
            }
            self.switchToFallback(reason: .noTicks)
        }

        displayLinkWatchdog = task
        DispatchQueue.main.asyncAfter(deadline: .now() + noTickWatchdogDelay, execute: task)
    }

    private func cancelDisplayLinkWatchdog() {
        displayLinkWatchdog?.cancel()
        displayLinkWatchdog = nil
    }

    private func switchToFallback(reason: FallbackReason) {
        guard isRunning else {
            return
        }

        guard backend != .fallbackTimer else {
            return
        }

        if let displayLink {
            CVDisplayLinkStop(displayLink)
        }

        cancelDisplayLinkWatchdog()
        backend = .fallbackTimer
        lastTimestamp = nil
        hasReceivedValidDisplayLinkTick = false
        consecutiveInvalidDisplayLinkDeltas = 0

        startFallbackTimer()

        switch reason {
        case .noTicks:
            log("fallback due to no ticks")
        case .invalidDeltas:
            log("fallback due to invalid deltas")
        }
    }

    private func hostTimeToSeconds(_ hostTime: UInt64) -> Double? {
        let frequency = CVGetHostClockFrequency()
        guard frequency.isFinite, frequency > 0 else {
            return nil
        }

        let seconds = Double(hostTime) / frequency
        guard seconds.isFinite else {
            return nil
        }

        return seconds
    }

    private func log(_ message: String) {
        print("[ticker] \(message)")
    }
}
