import SwiftUI

struct PastilleContentView: View {
    @ObservedObject var captureLoop: CaptureLoopManager
    let onClose: () -> Void

    @State private var isHovering = false
    @State private var isAppearing = false

    private let vermillon = Color(red: 0.906, green: 0.298, blue: 0.235)

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Image capturée
            Group {
                if let image = captureLoop.currentImage {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Rectangle()
                        .fill(Color.black.opacity(0.5))
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Bordure morphing toujours visible (intensité varie au hover)
            MorphingBorder(isHovering: isHovering)
                .animation(.easeInOut(duration: 0.25), value: isHovering)

            // Bouton fermer au survol
            if isHovering {
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22))
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, vermillon)
                        .shadow(color: .black.opacity(0.5), radius: 4)
                }
                .buttonStyle(.plain)
                .padding(8)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .shadow(color: .black.opacity(0.35), radius: 14, x: 0, y: 5)
        .scaleEffect(isAppearing ? 1.0 : 0.6)
        .opacity(isAppearing ? 1.0 : 0.0)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                isAppearing = true
            }
        }
        .onReceive(
            NotificationCenter.default.publisher(for: .pastilleHoverChanged)
        ) { notification in
            if let hovering = notification.userInfo?["hovering"] as? Bool {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isHovering = hovering
                }
            }
        }
    }
}
