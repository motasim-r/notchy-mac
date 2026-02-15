import Combine

@MainActor
final class EditorSessionState: ObservableObject {
    @Published var selectedTab: EditorTab = .script
}
