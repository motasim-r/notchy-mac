import Foundation
import Sparkle

@MainActor
final class SparkleUpdaterService: NSObject, SPUUpdaterDelegate {
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
        if shouldSurface(error: error) {
            onErrorMessage?(error.localizedDescription)
        }
    }

    func updater(_ updater: SPUUpdater, didAbortWithError error: Error) {
        onCheckingStateChange?(false)
        if shouldSurface(error: error) {
            onErrorMessage?(error.localizedDescription)
        }
    }

    func updater(_ updater: SPUUpdater, didFinishUpdateCycleFor updateCheck: SPUUpdateCheck, error: Error?) {
        onCheckingStateChange?(false)
        guard let error else {
            return
        }
        if shouldSurface(error: error) {
            onErrorMessage?(error.localizedDescription)
        }
    }

    private func shouldSurface(error: Error) -> Bool {
        let nsError = error as NSError
        return nsError.domain != SUSparkleErrorDomain || nsError.code != SUNoUpdateError
    }
}
