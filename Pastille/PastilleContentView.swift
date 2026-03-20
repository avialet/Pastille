import SwiftUI

struct PastilleContentView: View {
    @ObservedObject var captureLoop: CaptureLoopManager
    let onClose: () -> Void
    let onResizeDrag: (ResizeDragPhase, NSPoint) -> Void

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

            // Bouton fermer au survol (en haut à droite)
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

            // Poignée de redimensionnement (en bas à droite)
            if isHovering {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        ResizeHandle(onDrag: onResizeDrag)
                            .frame(width: 28, height: 28)
                    }
                }
                .transition(.opacity)
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

// MARK: - Poignée de resize homothétique

struct ResizeHandle: View {
    let onDrag: (ResizeDragPhase, NSPoint) -> Void
    @State private var dragStarted = false

    private let vermillon = Color(red: 0.906, green: 0.298, blue: 0.235)

    var body: some View {
        ZStack {
            Path { path in
                path.move(to: CGPoint(x: 20, y: 8))
                path.addLine(to: CGPoint(x: 8, y: 20))
                path.move(to: CGPoint(x: 20, y: 13))
                path.addLine(to: CGPoint(x: 13, y: 20))
                path.move(to: CGPoint(x: 20, y: 18))
                path.addLine(to: CGPoint(x: 18, y: 20))
            }
            .stroke(vermillon.opacity(0.8), lineWidth: 1.5)
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 2)
                .onChanged { _ in
                    if !dragStarted {
                        dragStarted = true
                        onDrag(.began, .zero)
                    }
                    onDrag(.changed, .zero)
                }
                .onEnded { _ in
                    dragStarted = false
                    onDrag(.ended, .zero)
                }
        )
        .onHover { hovering in
            if hovering {
                NSCursor.crosshair.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}
