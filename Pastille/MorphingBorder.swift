import SwiftUI

/// Bordure en pointillés vermillon — légère, pas d'animation GPU.
/// Cohérente avec le logo et le site web Pastille.
struct MorphingBorder: View {
    var isHovering: Bool = false

    private let vermillon = Color(red: 0.906, green: 0.298, blue: 0.235)
    private let vermillonClair = Color(red: 0.95, green: 0.45, blue: 0.38)

    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .stroke(
                LinearGradient(
                    colors: [vermillonClair, vermillon],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                style: StrokeStyle(
                    lineWidth: isHovering ? 3.5 : 2.5,
                    lineCap: .round,
                    dash: [10, 7]
                )
            )
            .shadow(color: vermillon.opacity(isHovering ? 0.4 : 0.2), radius: isHovering ? 8 : 4)
    }
}
