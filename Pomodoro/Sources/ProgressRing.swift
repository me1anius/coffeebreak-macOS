import SwiftUI

/// A circular progress ring with a gradient stroke.
/// The ring animates smoothly as `progress` changes.
struct ProgressRing: View {
    let progress: Double
    let gradientColors: [Color]
    let lineWidth: CGFloat
    let size: CGFloat
    let isBreak: Bool

    private var clampedProgress: CGFloat {
        CGFloat(min(progress, 1.0))
    }

    private var gradient: AngularGradient {
        AngularGradient(
            gradient: Gradient(stops: [
                .init(color: gradientColors[0], location: 0.0),
                .init(color: gradientColors[1], location: 0.5),
                .init(color: gradientColors[0], location: 1.0)
            ]),
            center: .center,
            startAngle: .degrees(-90),
            endAngle: .degrees(270)
        )
    }

    var body: some View {
        ZStack {
            // Background track
            Circle()
                .stroke(
                    Color.primary.opacity(0.08),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )

            // Foreground progress arc
            Circle()
                .trim(from: 0, to: clampedProgress)
                .stroke(gradient, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))

            // Glow effect on the leading edge
            Circle()
                .trim(from: 0, to: clampedProgress)
                .stroke(gradient, style: StrokeStyle(lineWidth: lineWidth * 0.6, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .blur(radius: 6)
                .opacity(0.4)
        }
        .frame(width: size, height: size)
        .animation(.easeInOut(duration: 0.5), value: progress)
        .transaction { transaction in
            if transaction.disablesAnimations {
                transaction.animation = nil
            }
        }
    }
}
