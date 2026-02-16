import Foundation

protocol StateStoreProtocol {
    func load() -> TeleprompterStateIOS?
    func save(_ state: TeleprompterStateIOS) throws
    @discardableResult
    func update(_ mutation: (inout TeleprompterStateIOS) -> Void) throws -> TeleprompterStateIOS
}
