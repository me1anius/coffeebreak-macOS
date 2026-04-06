import SwiftUI

/// The main popover view containing the progress ring, timer display,
/// session info, pomodoro indicators, and control buttons.
struct TimerView: View {
    @ObservedObject var viewModel: TimerViewModel
    @State private var isEditingName: Bool = false
    @State private var isHoveringLabel: Bool = false
    @State private var selectedLabel: String = ""
    @State private var showOnboarding: Bool = !UserDefaults.standard.bool(forKey: StorageKeys.hasSeenOnboarding)

    var body: some View {
        ZStack {
            // Frosted glass background
            VisualEffectView(material: .popover, blendingMode: .behindWindow)
                .ignoresSafeArea()

            if viewModel.showSettings {
                SettingsView(viewModel: viewModel)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            } else {
                timerContent
                    .transition(.move(edge: .leading).combined(with: .opacity))
            }
        }
        .frame(width: AppSizing.popoverWidth, height: AppSizing.popoverHeight)
        .overlay {
            if showOnboarding {
                OnboardingView(isPresented: $showOnboarding)
                    .frame(width: AppSizing.popoverWidth, height: AppSizing.popoverHeight)
                    .transition(.opacity)
            }
        }
    }

    // MARK: - Timer Content

    private var timerContent: some View {
        VStack(spacing: 16) {
            // Settings gear button — right-aligned at top
            HStack {
                Spacer()
                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                        viewModel.showSettings = true
                    }
                }) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(SubtleButtonStyle())
            }
            .padding(.trailing, 12)

            // Progress ring with time inside
            ZStack {
                ProgressRing(
                    progress: viewModel.progress,
                    gradientColors: AppColors.gradientForSession(!viewModel.sessionType.isBreak),
                    lineWidth: AppSizing.ringLineWidth,
                    size: AppSizing.ringSize,
                    isBreak: viewModel.sessionType.isBreak
                )

                // Large countdown text
                Text(viewModel.formattedTime)
                    .font(.system(size: 36, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.3), value: viewModel.formattedTime)
            }

            // Session label + optional name
            sessionLabel

            // Pomodoro count indicators
            pomodoroIndicators

            Spacer(minLength: 0)

            // Control buttons
            controlButtons
                .padding(.bottom, 20)
        }
        .padding(.top, 4)
    }

    // MARK: - Session Label

    /// Shows the session type. Pencil appears on hover to name the session.
    private var sessionLabel: some View {
        VStack(spacing: 4) {
            Text(viewModel.sessionType.rawValue)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)

            if isEditingName {
                HStack(spacing: 4) {
                    // Native menu picker for saved labels
                    if !viewModel.recentLabels.isEmpty {
                        Menu {
                            ForEach(viewModel.recentLabels, id: \.self) { label in
                                Button(label) {
                                    viewModel.sessionName = label
                                    isEditingName = false
                                }
                            }
                        } label: {
                            Image(systemName: "chevron.down")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.secondary)
                                .frame(width: 18, height: 18)
                                .background(Circle().fill(Color.primary.opacity(0.06)))
                        }
                        .menuStyle(.borderlessButton)
                        .menuIndicator(.hidden)
                        .frame(width: 18)
                    }

                    TextField("e.g. Past Paper Review", text: $viewModel.sessionName)
                        .textFieldStyle(.plain)
                        .font(.system(size: 11, weight: .regular, design: .rounded))
                        .multilineTextAlignment(.center)
                        .frame(width: 140)
                        .padding(.vertical, 3)
                        .padding(.horizontal, 8)
                        .background(
                            Capsule().fill(Color.primary.opacity(0.06))
                        )
                        .onSubmit {
                            isEditingName = false
                        }

                    Button(action: {
                        viewModel.sessionName = ""
                        isEditingName = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
            } else if !viewModel.sessionName.isEmpty {
                Text(viewModel.sessionName)
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                    .overlay(alignment: .trailing) {
                        Button(action: { isEditingName = true }) {
                            Image(systemName: "pencil")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .opacity(isHoveringLabel ? 1 : 0)
                        .offset(x: 18)
                    }
                .transition(.opacity)
            } else {
                // Empty state — pencil only visible on hover
                Button(action: { isEditingName = true }) {
                    Image(systemName: "pencil")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                        .frame(height: 16)
                }
                .buttonStyle(.plain)
                .opacity(isHoveringLabel ? 1 : 0)
                .transition(.opacity)
            }
        }
        .frame(minHeight: 20)
        .padding(.horizontal, 24)
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHoveringLabel = hovering
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isEditingName)
        .animation(.easeInOut(duration: 0.2), value: viewModel.sessionName.isEmpty)
    }

    // MARK: - Pomodoro Indicators

    /// Small pill dots showing completed vs remaining pomodoros in the cycle.
    private var pomodoroIndicators: some View {
        HStack(spacing: 6) {
            ForEach(0..<viewModel.pomodorosBeforeLongBreak, id: \.self) { index in
                Capsule()
                    .fill(index < viewModel.completedPomodoros
                          ? AppColors.workEnd
                          : Color.primary.opacity(0.15))
                    .frame(width: index < viewModel.completedPomodoros ? 16 : 8, height: 6)
                    .animation(.spring(response: 0.35, dampingFraction: 0.7), value: viewModel.completedPomodoros)
            }
        }
    }

    // MARK: - Control Buttons

    private var controlButtons: some View {
        HStack(spacing: 20) {
            // Reset button
            Button(action: {
                viewModel.reset()
            }) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(width: AppSizing.buttonSize, height: AppSizing.buttonSize)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(SpringButtonStyle())

            // Play / Pause button (larger, primary)
            Button(action: {
                viewModel.startPause()
            }) {
                Image(systemName: viewModel.timerState == .running ? "pause.fill" : "play.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .frame(width: AppSizing.buttonSize * 1.3, height: AppSizing.buttonSize * 1.3)
                    .background(
                        LinearGradient(
                            colors: AppColors.gradientForSession(!viewModel.sessionType.isBreak),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(Circle())
                    .foregroundStyle(.white)
                    .shadow(color: AppColors.workStart.opacity(0.35), radius: 8, y: 3)
            }
            .buttonStyle(SpringButtonStyle())
            .animation(.easeInOut(duration: 0.2), value: viewModel.timerState == .running)

            // Skip button
            Button(action: {
                viewModel.skipSession()
            }) {
                Image(systemName: "forward.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(width: AppSizing.buttonSize, height: AppSizing.buttonSize)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(SpringButtonStyle())
        }
    }
}

// MARK: - Button Styles

/// A button style with a spring scale animation on press.
struct SpringButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.88 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

/// A subtle button style for secondary actions like the gear icon.
struct SubtleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(6)
            .background(
                Circle()
                    .fill(configuration.isPressed ? Color.primary.opacity(0.08) : Color.clear)
            )
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - NSVisualEffectView Wrapper

/// Bridges AppKit's NSVisualEffectView into SwiftUI for the native frosted glass look.
struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

