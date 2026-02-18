import SwiftUI

struct EditorSheetView: View {
    @ObservedObject var controller: AppStateControllerIOS

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().overlay(Color.white.opacity(0.08))
            content
        }
        .background(
            LinearGradient(
                colors: [Color(red: 0.08, green: 0.085, blue: 0.095), Color(red: 0.07, green: 0.072, blue: 0.083)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .presentationDragIndicator(.visible)
        .presentationDetents([.fraction(0.46), .large])
    }

    private var header: some View {
        HStack(spacing: 10) {
            Text("Notchy")
                .font(NotchyTypographyIOS.display(size: 22, weight: .medium))
                .foregroundStyle(Color.white)

            Spacer()

            Picker("Tab", selection: Binding(
                get: { controller.state.editor.selectedTab },
                set: { controller.setEditorTab($0) }
            )) {
                Text("Script").tag(EditorTabIOS.script)
                Text("Settings").tag(EditorTabIOS.settings)
                Text("Changelogs").tag(EditorTabIOS.changelogs)
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 360)
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 10)
    }

    @ViewBuilder
    private var content: some View {
        ZStack(alignment: .topLeading) {
            tabContent(.script) { ScriptTabView(controller: controller) }
            tabContent(.settings) { SettingsTabView(controller: controller) }
            tabContent(.changelogs) { ChangelogTabView() }
        }
        .animation(nil, value: controller.state.editor.selectedTab)
    }

    private func tabContent<Content: View>(_ tab: EditorTabIOS, @ViewBuilder content: () -> Content) -> some View {
        let isSelected = controller.state.editor.selectedTab == tab
        return content()
            .opacity(isSelected ? 1 : 0)
            .allowsHitTesting(isSelected)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
