import SwiftUI

// MARK: - ErrorSheet
struct ErrorSheet: View {
    let error: AppError
    var onRetry: (() -> Void)? = nil
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle").font(.largeTitle).foregroundStyle(.orange)
            Text(error.localizedDescription).multilineTextAlignment(.center)
            if case .permissionDenied = error {
                Button("Open Settings") { if let u = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(u) } }
            }
            if let r = onRetry { Button("Retry", action: r) }
        }.padding().presentationDetents([.medium])
    }
}
