import SwiftUI
import UIKit

enum NotchyTypographyIOS {
    private static let seasonSerifRegular = "SeasonSerif-Regular-TRIAL"
    private static let seasonSerifMedium = "SeasonSerif-Medium-TRIAL"
    private static let seasonSerifBold = "SeasonSerif-Bold-TRIAL"
    private static let seasonSansRegular = "SeasonSans-Regular-TRIAL"
    private static let seasonSansMedium = "SeasonSans-Medium-TRIAL"
    private static let seasonSansBold = "SeasonSans-Bold-TRIAL"

    static func display(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let name: String
        switch weight {
        case .bold, .heavy, .semibold:
            name = seasonSerifBold
        case .medium:
            name = seasonSerifMedium
        default:
            name = seasonSerifRegular
        }

        if UIFont(name: name, size: size) != nil {
            return .custom(name, size: size)
        }

        return .system(size: size, weight: weight, design: .serif)
    }

    static func ui(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let name: String
        switch weight {
        case .bold, .heavy, .semibold:
            name = seasonSansBold
        case .medium:
            name = seasonSansMedium
        default:
            name = seasonSansRegular
        }

        if UIFont(name: name, size: size) != nil {
            return .custom(name, size: size)
        }

        return .system(size: size, weight: weight, design: .default)
    }
}
