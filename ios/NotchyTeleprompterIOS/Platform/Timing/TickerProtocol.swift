import Foundation

protocol TickerProtocol: AnyObject {
    var onTick: ((CFTimeInterval) -> Void)? { get set }
    func start()
    func stop()
}
