import SwiftUI

/// A reusable circular progress ring with a gradient stroke.
/// The ring animates smoothly as `progress` changes.
struct ProgressRing: View {
    let progress: Double
    let gradientColors: [Color]
    let lineWidth: CGFloat
    let size: CGFloat

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
                .trim(from: 0, to: CGFloat(min(progress, 1.0)))
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: gradientColors),
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                // Start from 12 o'clock position
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progress)

            // Glow effect on the leading edge
            Circle()
                .trim(from: 0, to: CGFloat(min(progress, 1.0)))
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: gradientColors),
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth * 0.6, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .blur(radius: 6)
                .opacity(0.4)
                .animation(.easeInOut(duration: 0.5), value: progress)
        }
        .frame(width: size, height: size)
    }
}

