import Foundation

protocol StateStoreProtocol {
    func load() -> TeleprompterState?
    func save(_ state: TeleprompterState) throws
    @discardableResult
    func update(_ mutation: (inout TeleprompterState) -> Void) throws -> TeleprompterState
}
