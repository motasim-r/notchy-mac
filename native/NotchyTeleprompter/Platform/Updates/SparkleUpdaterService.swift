import Foundation
import Sparkle

@MainActor
final class SparkleUpdaterService: NSObject, @preconcurrency SPUUpdaterDelegate {
    var onUpdateAvailabilityChange: ((Bool, String?) -> Void)?
    var onCheckingStateChange: ((Bool) -> Void)?
    var onErrorMessage: ((String?) -> Void)?

    private lazy var updaterController: SPUStandardUpdaterController = {
        SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: self,
            userDriverDelegate: nil
        )
    }()

    private var probeTimer: Timer?
    private var started = false

    func start() {
        guard !started else {
            return
        }

        started = true
        _ = updaterController

        DispatchQueue.main.asyncAfter(deadline: .now() + 6) { [weak self] in
            guard let self else { return }
            self.probeForUpdatesInBackground()
        }

        probeTimer = Timer.scheduledTimer(withTimeInterval: 60 * 60 * 4, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.probeForUpdatesInBackground()
            }
        }
    }

    func teardown() {
        probeTimer?.invalidate()
        probeTimer = nil
    }

    func checkForUpdates() {
        onCheckingStateChange?(true)
        onErrorMessage?(nil)
        updaterController.checkForUpdates(nil)
    }

    private func probeForUpdatesInBackground() {
        let updater = updaterController.updater
        guard updater.canCheckForUpdates else {
            return
        }
        updater.checkForUpdateInformation()
    }

    func updater(_ updater: SPUUpdater, didFindValidUpdate item: SUAppcastItem) {
        onUpdateAvailabilityChange?(true, item.displayVersionString)
    }

    func updaterDidNotFindUpdate(_ updater: SPUUpdater) {
        onUpdateAvailabilityChange?(false, nil)
    }

    func updaterDidNotFindUpdate(_ updater: SPUUpdater, error: Error) {
        onUpdateAvailabilityChange?(false, nil)
        onErrorMessage?(nil)
    }

    func updater(_ updater: SPUUpdater, didAbortWithError error: Error) {
        onCheckingStateChange?(false)
        onErrorMessage?(error.localizedDescription)
    }

    func updater(_ updater: SPUUpdater, didFinishUpdateCycleFor updateCheck: SPUUpdateCheck, error: Error?) {
        onCheckingStateChange?(false)
        if let error {
            onErrorMessage?(error.localizedDescription)
        }
    }
}
