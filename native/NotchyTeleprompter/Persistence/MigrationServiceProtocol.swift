import Foundation

protocol MigrationServiceProtocol {
    func runIfNeeded(existingState: TeleprompterState?) -> TeleprompterState?
}
