import SwiftUI

extension View {
    func restoreAccessoryPolicyOnDismiss() -> some View {
        self.onDisappear {
            if NSApp.windows.filter({ $0.isVisible }).isEmpty {
                NSApp.setActivationPolicy(.accessory)
            }
        }
    }
}
