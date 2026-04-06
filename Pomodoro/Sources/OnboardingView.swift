import SwiftUI

struct OnboardingView: View {
    @Binding var isPresented: Bool
    @State private var currentStep = 0

    var body: some View {
        ZStack {
            VisualEffectView(material: .popover, blendingMode: .behindWindow)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                Group {
                    switch currentStep {
                    case 0: welcomeStep
                    case 1: phaseStep
                    case 2: namingStep
                    case 3: controlsStep
                    case 4: settingsStep
                    default: EmptyView()
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                .id(currentStep)

                Spacer()

                // Progress dots
                HStack(spacing: 5) {
                    ForEach(0..<5, id: \.self) { i in
                        Circle()
                            .fill(i == currentStep ? AppColors.workStart : Color.primary.opacity(0.15))
                            .frame(width: i == currentStep ? 7 : 5, height: i == currentStep ? 7 : 5)
                            .animation(.spring(response: 0.3), value: currentStep)
                    }
                }
                .padding(.bottom, 14)

                // Buttons
                HStack(spacing: 16) {
                    if currentStep < 4 {
                        Button("Skip") { finish() }
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                            .buttonStyle(.plain)
                    }

                    Button(action: advance) {
                        Text(currentStep < 4 ? "Next" : "Get Started")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 22)
                            .padding(.vertical, 8)
                            .background(
                                Capsule().fill(
                                    LinearGradient(
                                        colors: [AppColors.workStart, AppColors.workEnd],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                            )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.bottom, 24)
            }
            .padding(.horizontal, 24)
        }
    }

    // MARK: - Welcome

    private var welcomeStep: some View {
        VStack(spacing: 16) {
            Image(systemName: "cup.and.saucer.fill")
                .font(.system(size: 38, weight: .medium))
                .foregroundStyle(
                    LinearGradient(
                        colors: [AppColors.workStart, AppColors.workEnd],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 70, height: 70)
                .background(Circle().fill(Color.primary.opacity(0.05)))

            Text("Welcome to Coffee Break")
                .font(.system(size: 17, weight: .bold, design: .rounded))

            Text("A focus timer that lives in\nyour menu bar.")
                .font(.system(size: 12, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
        }
    }

    // MARK: - Start Phase

    private var phaseStep: some View {
        VStack(spacing: 16) {
            // Mini play button
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: AppColors.gradientForSession(true),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                    .shadow(color: AppColors.workStart.opacity(0.3), radius: 8, y: 3)

                Image(systemName: "play.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
            }

            Text("Start a Focus Phase")
                .font(.system(size: 17, weight: .bold, design: .rounded))

            Text("Tap play to begin. The timer appears\nin your menu bar while you work.")
                .font(.system(size: 12, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
        }
    }

    // MARK: - Naming

    private var namingStep: some View {
        VStack(spacing: 16) {
            // Mock-up of naming + saved labels
            VStack(spacing: 10) {
                // Text field mock
                HStack(spacing: 6) {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.secondary)
                        .frame(width: 16, height: 16)
                        .background(Circle().fill(Color.primary.opacity(0.06)))

                    Text("Deep Work")
                        .font(.system(size: 11, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.primary.opacity(0.06)))

                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary.opacity(0.5))
                }
                .padding(.horizontal, 12)

                // Dropdown mock
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(["Study Session", "Code Review", "Reading"], id: \.self) { label in
                        HStack {
                            Text(label)
                                .font(.system(size: 10, design: .rounded))
                            Spacer()
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)

                        if label != "Reading" {
                            Divider().padding(.horizontal, 8)
                        }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color.primary.opacity(0.04))
                )
                .padding(.horizontal, 20)
            }
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.primary.opacity(0.03))
            )

            Text("Name Your Phase")
                .font(.system(size: 17, weight: .bold, design: .rounded))

            Text("Hover below the timer to name your\nwork. Pick from saved labels or\ntype your own.")
                .font(.system(size: 12, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
        }
    }

    // MARK: - Controls

    private var controlsStep: some View {
        VStack(spacing: 16) {
            // Mini control buttons
            HStack(spacing: 16) {
                miniButton(icon: "arrow.counterclockwise", size: 36, isPrimary: false)
                miniButton(icon: "pause.fill", size: 46, isPrimary: true)
                miniButton(icon: "forward.fill", size: 36, isPrimary: false)
            }

            Text("Controls")
                .font(.system(size: 17, weight: .bold, design: .rounded))

            Text("Reset, pause, or skip to the next\nphase. Set keyboard shortcuts\nin Settings.")
                .font(.system(size: 12, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
        }
    }

    // MARK: - Settings

    private var settingsStep: some View {
        VStack(spacing: 16) {
            // Mini settings preview
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Saved Labels")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                    Spacer()
                }

                HStack(spacing: 6) {
                    miniSettingsField("New label...")
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(AppColors.workStart)
                }

                ForEach(["Study Session", "Code Review"], id: \.self) { label in
                    HStack {
                        Text(label)
                            .font(.system(size: 10, design: .rounded))
                        Spacer()
                        Image(systemName: "xmark")
                            .font(.system(size: 7, weight: .bold))
                            .foregroundStyle(.secondary.opacity(0.5))
                    }
                    .padding(.vertical, 2)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.primary.opacity(0.03))
            )

            Text("Make It Yours")
                .font(.system(size: 17, weight: .bold, design: .rounded))

            Text("Customise durations, sounds, and\nkeyboard shortcuts. Add saved\nlabels for quick access.")
                .font(.system(size: 12, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
        }
    }

    // MARK: - Helpers

    private func miniButton(icon: String, size: CGFloat, isPrimary: Bool) -> some View {
        Image(systemName: icon)
            .font(.system(size: size * 0.35, weight: .semibold))
            .frame(width: size, height: size)
            .background(
                isPrimary
                    ? AnyShapeStyle(LinearGradient(
                        colors: AppColors.gradientForSession(true),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    : AnyShapeStyle(.ultraThinMaterial)
            )
            .clipShape(Circle())
            .foregroundStyle(isPrimary ? .white : .secondary)
    }

    private func miniSettingsField(_ placeholder: String) -> some View {
        Text(placeholder)
            .font(.system(size: 9, design: .rounded))
            .foregroundStyle(.tertiary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(Color.primary.opacity(0.04))
            )
    }

    // MARK: - Actions

    private func advance() {
        if currentStep < 4 {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                currentStep += 1
            }
        } else {
            finish()
        }
    }

    private func finish() {
        UserDefaults.standard.set(true, forKey: StorageKeys.hasSeenOnboarding)
        withAnimation(.easeOut(duration: 0.2)) {
            isPresented = false
        }
    }
}
