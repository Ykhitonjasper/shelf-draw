import SwiftUI

struct FailureCard: View {
    let title: String
    let message: String
    var retryTitle = "Try again"
    var retry: () -> Void

    var body: some View {
        ScreenScaffold {
            EmptyStateCard(
                title: title,
                message: message,
                systemImage: "exclamationmark.arrow.triangle.2.circlepath",
                actionTitle: retryTitle,
                action: retry
            )
        }
    }
}

#Preview {
    FailureCard(
        title: "Library didn't open",
        message: "What you saved is still on this phone."
    ) {}
}
