import SwiftUI

struct ChangelogTabView: View {
    private let sections: [ChangelogSection] = [
        ChangelogSection(
            title: "V1 iPhone Foundation",
            items: [
                "Built separate iOS workspace under /ios while keeping macOS app untouched.",
                "Implemented full-screen front-camera recorder with notch-style teleprompter overlay.",
                "Added pause/resume recording with one final merged output file.",
                "Enabled save-to-Photos flow with permissions and error handling.",
                "Added script editor and settings tabs in bottom sheet.",
                "Added Season font-driven brand typography for iOS UI."
            ]
        ),
        ChangelogSection(
            title: "Notch UI",
            items: [
                "Top-center notch-style capsule with shoulder cut-in shape.",
                "Manual drag scrolling on overlay with clamped bounds.",
                "Safe text inset to avoid notch/Dynamic Island clipping.",
                "Fixed top anchoring so notch-ui is stitched to the physical top edge at default position.",
                "Added hard notch-shape clipping so text always stays inside the notch-ui.",
                "Polished notch-ui with translucent dark-glass styling, softer border/shadow, and cleaner spacing.",
                "Added a slow top fade effect so text eases out naturally as it leaves the notch.",
                "Switched notch-ui surface back to dark black for stronger readability and notch blending."
            ]
        ),
        ChangelogSection(
            title: "Controls and Recording",
            items: [
                "Bottom floating tray: Play/Pause, speed controls, Record/Pause/Resume/Stop, Script sheet button.",
                "Start recording auto-plays teleprompter for one-tap live flow.",
                "Recording is mirrored in preview and saved unmirrored.",
                "Fixed final saved video orientation by preserving source track transform during segment merge."
            ]
        ),
        ChangelogSection(
            title: "Data and Script Handling",
            items: [
                "Default script now uses real line breaks for clean teleprompter rendering.",
                "Legacy escaped line breaks (\\n) are auto-normalized on load.",
                "Default notch width increased for better breathing room."
            ]
        )
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("Changelogs")
                    .font(NotchyTypographyIOS.display(size: 28, weight: .medium))
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)

                Text("Rule: every future product/UI change must be appended here and in ios/CHANGELOG.md before release.")
                    .font(NotchyTypographyIOS.ui(size: 13, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.76))
                    .padding(.horizontal, 16)

                ForEach(sections) { section in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(section.title)
                            .font(NotchyTypographyIOS.display(size: 21, weight: .medium))
                            .foregroundStyle(Color.white)

                        ForEach(section.items.indices, id: \.self) { index in
                            HStack(alignment: .top, spacing: 8) {
                                Text("•")
                                    .font(NotchyTypographyIOS.ui(size: 13, weight: .bold))
                                    .foregroundStyle(Color.white.opacity(0.84))

                                Text(section.items[index])
                                    .font(NotchyTypographyIOS.ui(size: 13, weight: .regular))
                                    .foregroundStyle(Color.white.opacity(0.84))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.black.opacity(0.22))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal, 16)
                }

                Spacer(minLength: 16)
            }
            .padding(.bottom, 20)
        }
    }
}

private struct ChangelogSection: Identifiable {
    let title: String
    let items: [String]

    var id: String { title }
}
