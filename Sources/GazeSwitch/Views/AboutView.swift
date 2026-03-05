import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
    }

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "eye")
                .font(.system(size: 48))
                .foregroundStyle(.tint)

            Text("GazeSwitch")
                .font(.title)
                .bold()

            Text("Version \(version)")
                .font(.caption)
                .foregroundColor(.secondary)

            Text("An open-source gaze-tracking utility for macOS.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)

            Divider()

            VStack(spacing: 8) {
                linkButton("GitHub", systemImage: "chevron.left.forwardslash.chevron.right", url: "https://github.com/vetlehf/gazeswitch")
                linkButton("Buy Me a Coffee", systemImage: "cup.and.saucer.fill", url: "https://buymeacoffee.com/vetfin")
            }

            Divider()

            Text("MIT License")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(24)
        .frame(width: 280)
        .restoreAccessoryPolicyOnDismiss()
    }

    private func linkButton(_ title: String, systemImage: String, url: String) -> some View {
        Button {
            if let url = URL(string: url) {
                NSWorkspace.shared.open(url)
            }
        } label: {
            HStack {
                Image(systemName: systemImage)
                    .frame(width: 20)
                Text(title)
                Spacer()
                Image(systemName: "arrow.up.right.square")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .buttonStyle(.plain)
    }
}
