import Foundation

enum EditorTab: String, CaseIterable, Identifiable {
    case script
    case settings
    case shortcuts
    case changelogs

    var id: String { rawValue }

    var title: String {
        switch self {
        case .script:
            return "Script"
        case .settings:
            return "Settings"
        case .shortcuts:
            return "Shortcuts"
        case .changelogs:
            return "Changelogs"
        }
    }

    var subtitle: String {
        switch self {
        case .script:
            return "Edit and control playback"
        case .settings:
            return "Panel and text tuning"
        case .shortcuts:
            return "Remote and key legend"
        case .changelogs:
            return "V1 to V2 updates"
        }
    }

    var symbolName: String {
        switch self {
        case .script:
            return "doc.text"
        case .settings:
            return "slider.horizontal.3"
        case .shortcuts:
            return "keyboard"
        case .changelogs:
            return "list.bullet.clipboard"
        }
    }
}
