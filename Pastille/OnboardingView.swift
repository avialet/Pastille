import SwiftUI

struct OnboardingView: View {
    let onDismiss: () -> Void

    private let vermillon = Color(red: 0.906, green: 0.298, blue: 0.235)
    private let vermillonFonce = Color(red: 0.753, green: 0.224, blue: 0.169)

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "rectangle.dashed")
                .font(.system(size: 48))
                .foregroundStyle(
                    LinearGradient(
                        colors: [vermillon, vermillonFonce],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text("Enregistrement d'écran requis")
                .font(.headline)
                .multilineTextAlignment(.center)

            Text("Pour capturer une zone de votre écran et la transformer en vignette flottante, Pastille nécessite la permission d'enregistrement d'écran.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer()

            HStack(spacing: 12) {
                Button("Plus tard") {
                    onDismiss()
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)

                Button(action: {
                    PermissionManager.openSystemPreferences()
                    onDismiss()
                }) {
                    Text("Ouvrir les Réglages")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(
                            LinearGradient(
                                colors: [vermillon, vermillonFonce],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }

            Spacer().frame(height: 10)
        }
        .padding(30)
        .frame(width: 420, height: 300)
    }
}
