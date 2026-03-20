import SwiftUI

/// Bordure animée "morphing" avec gradient angulaire tournant et halo lumineux.
/// Style cohérent avec Chuchotte (blob AngularGradient) et Écran Total (wave glow).
struct MorphingBorder: View {
    var isHovering: Bool = false

    private let vermillon = Color(red: 0.906, green: 0.298, blue: 0.235)
    private let vermillonClair = Color(red: 0.95, green: 0.45, blue: 0.38)
    private let vermillonFonce = Color(red: 0.75, green: 0.22, blue: 0.17)

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let breathe = 1.0 + sin(t * 1.5) * 0.004

            ZStack {
                // Couche 1 : Halo lumineux diffus
                RoundedRectangle(cornerRadius: 15)
                    .stroke(
                        AngularGradient(
                            colors: [
                                vermillon.opacity(0.5),
                                vermillonClair.opacity(0.25),
                                vermillonFonce.opacity(0.5),
                                vermillonClair.opacity(0.25),
                                vermillon.opacity(0.5)
                            ],
                            center: .center,
                            angle: .degrees(t * 25)
                        ),
                        lineWidth: isHovering ? 10 : 7
                    )
                    .blur(radius: isHovering ? 14 : 10)
                    .scaleEffect(breathe)

                // Couche 2 : Bordure principale avec gradient angulaire tournant
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        AngularGradient(
                            colors: [
                                vermillon,
                                vermillonClair,
                                vermillon,
                                vermillonFonce,
                                vermillon
                            ],
                            center: .center,
                            angle: .degrees(t * 40)
                        ),
                        lineWidth: isHovering ? 4.5 : 3.5
                    )
                    .scaleEffect(breathe * 0.999)

                // Couche 3 : Reflet intérieur subtil
                RoundedRectangle(cornerRadius: 11)
                    .stroke(
                        AngularGradient(
                            colors: [
                                vermillonClair.opacity(0.3),
                                Color.white.opacity(0.15),
                                vermillonClair.opacity(0.3),
                                Color.white.opacity(0.1),
                                vermillonClair.opacity(0.3)
                            ],
                            center: .center,
                            angle: .degrees(-t * 18)
                        ),
                        lineWidth: 1.5
                    )
                    .blendMode(.plusLighter)
            }
        }
    }
}
