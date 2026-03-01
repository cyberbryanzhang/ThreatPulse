import SwiftUI

struct ContentView: View {
    @StateObject private var engine = GameEngine()
    @State private var isMuted = false

    var body: some View {
        ZStack {
            BackgroundView()

            if engine.state == .idle {
                IntroView(
                    isMuted: isMuted,
                    onToggleMute: {
                        toggleMute()
                    }
                ) {
                    engine.start()
                }
            } else {
                GameView(
                    engine: engine,
                    isMuted: isMuted,
                    onToggleMute: {
                        toggleMute()
                    },
                    onPauseToggle: {
                        SoundPlayer.shared.duck("bgm", to: 0.0, for: 0.3)
                        SoundPlayer.shared.play("click", ext: "mp3", volume: 1.0)
                        if engine.state == .paused {
                            engine.resume()
                        } else if engine.state == .running {
                            engine.pause()
                        }
                    },
                    onStop: {
                        SoundPlayer.shared.duck("bgm", to: 0.0, for: 0.3)
                        SoundPlayer.shared.play("click", ext: "mp3", volume: 1.0)
                        engine.resetToIdle()
                    },
                    onDemoSkip: {
                        SoundPlayer.shared.play("click", ext: "mp3", volume: 1.0)
                        engine.demoSkipWave()
                    }
                )
            }

            if engine.hitFlash {
                Color.red.opacity(0.25)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.2), value: engine.hitFlash)
            }

            if engine.state == .paused {
                Color.black.opacity(0.55)
                    .ignoresSafeArea()

                if let intel = engine.currentIntel {
                    IntelPauseOverlay(
                        event: intel,
                        onContinue: {
                            SoundPlayer.shared.play("click", ext: "mp3", volume: 1.0)
                            engine.acknowledgeIntel()
                        }
                    )
                } else if let scenario = engine.currentScenario {
                    ScenarioOverlay(
                        scenario: scenario,
                        onChooseA: {
                            SoundPlayer.shared.play("click", ext: "mp3", volume: 1.0)
                            engine.chooseScenario(optionA: true)
                        },
                        onChooseB: {
                            SoundPlayer.shared.play("click", ext: "mp3", volume: 1.0)
                            engine.chooseScenario(optionA: false)
                        }
                    )
                } else {
                    PauseOverlay {
                        SoundPlayer.shared.duck("bgm", to: 0.0, for: 0.3)
                        SoundPlayer.shared.play("click", ext: "mp3", volume: 1.0)
                        engine.resume()
                    } onStop: {
                        SoundPlayer.shared.duck("bgm", to: 0.0, for: 0.3)
                        SoundPlayer.shared.play("click", ext: "mp3", volume: 1.0)
                        engine.resetToIdle()
                    }
                }
            }

            if engine.state == .finished {
                Color.black.opacity(0.55)
                    .ignoresSafeArea()

                EndOverlay(
                    success: engine.serverHealth > 0,
                    score: engine.score,
                    health: engine.serverHealth,
                    takeaway: engine.missionTakeaway,
                    questions: engine.debriefQuestions
                ) {
                    engine.resetToIdle()
                } onReplay: {
                    engine.start()
                }
            }
        }
        .onAppear {
            guard !isMuted else { return }
            SoundPlayer.shared.playLoop("start", ext: "mp3", volume: 0.35)
        }
        .onChange(of: engine.state) { newState in
            guard !isMuted else { return }
            switch newState {
            case .idle:
                SoundPlayer.shared.stop("bgm", ext: "mp3")
                SoundPlayer.shared.playLoop("start", ext: "mp3", volume: 0.35)
            case .running, .finished:
                SoundPlayer.shared.stop("start", ext: "mp3")
                SoundPlayer.shared.playLoop("bgm", ext: "mp3", volume: 0.25)
            case .paused:
                SoundPlayer.shared.stop("start", ext: "mp3")
                SoundPlayer.shared.playLoop("bgm", ext: "mp3", volume: 0.25)
            }
        }
    }

    private func toggleMute() {
        isMuted.toggle()
        SoundPlayer.shared.setMuted(isMuted)
        if !isMuted {
            if engine.state == .idle {
                SoundPlayer.shared.playLoop("start", ext: "mp3", volume: 0.35)
            } else {
                SoundPlayer.shared.playLoop("bgm", ext: "mp3", volume: 0.25)
            }
        }
    }
}

private struct IntroView: View {
    let isMuted: Bool
    let onToggleMute: () -> Void
    let onStart: () -> Void
    @State private var showCredits = false
    @State private var selectedLevel = 1

    var body: some View {
        ZStack {
            VStack(spacing: 20) {
                Text("This app is currently for Apple Swift Student Challenge 2026 only.")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)

                EmptyView()

                Text("ThreatPulse")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Text("Created by Bryan Zhang")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.85))

                Text("A 3-minute interactive game to learn core cyber defense ideas.")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                VStack(alignment: .leading, spacing: 10) {
                    IntroBullet(text: "Select a level, then survive for 180 seconds.")
                    IntroBullet(text: "Tap a router node to activate a matching defense.")
                    IntroBullet(text: "Watch traffic move left to right across the network path.")
                    IntroBullet(text: "Decision points teach tradeoffs and consequences.")
                    IntroBullet(text: "Keep server health above zero until time runs out.")
                }
                .padding(.horizontal, 24)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Select Level")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    HStack(spacing: 10) {
                        LevelCard(
                            title: "Level 1",
                            subtitle: "Flood at the Edge",
                            isSelected: selectedLevel == 1,
                            isLocked: false
                        ) {
                            selectedLevel = 1
                        }
                        LevelCard(
                            title: "Level 2",
                            subtitle: "Coming Soon",
                            isSelected: false,
                            isLocked: true
                        ) {}
                    }
                }
                .padding(.horizontal, 24)

                Button(action: {
                    SoundPlayer.shared.duck("start", to: 0.0, for: 0.4)
                    SoundPlayer.shared.duck("bgm", to: 0.0, for: 0.4)
                    SoundPlayer.shared.play("click", ext: "mp3", volume: 1.0)
                    showCredits = true
                }) {
                    Text("Start Simulation")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.black)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 12)
                        .background(Capsule().fill(Color.white))
                }
            }
        .padding(30)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .stroke(Color.white.opacity(0.25), lineWidth: 1)
                )
                .overlay(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.35),
                            Color.white.opacity(0.12),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                )
        )
        .padding(.horizontal, 20)

            VStack {
                HStack {
                    Spacer()
                    Button(action: onToggleMute) {
                        Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                                            .stroke(Color.white.opacity(0.28), lineWidth: 1)
                                    )
                                    .overlay(
                                        LinearGradient(
                                            colors: [
                                                Color.white.opacity(0.35),
                                                Color.white.opacity(0.08),
                                                Color.clear
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                    )
                            )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                Spacer()
            }

            if showCredits {
                Color.black.opacity(0.6)
                    .ignoresSafeArea()

                CreditsOverlay {
                    SoundPlayer.shared.duck("start", to: 0.0, for: 0.4)
                    SoundPlayer.shared.play("click", ext: "mp3", volume: 1.0)
                    SoundPlayer.shared.stop("start", ext: "mp3")
                    showCredits = false
                    onStart()
                } onCancel: {
                    SoundPlayer.shared.play("click", ext: "mp3", volume: 1.0)
                    showCredits = false
                }
            }

        }
    }
}

private struct CreditsOverlay: View {
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Text("Acknowledgments")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            VStack(alignment: .leading, spacing: 8) {
                Text("Audio sources (Pixabay License):")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))
                Text("• \"Aboard A Aurora (Game Menu Pulse)\" — whvle")
                Text("• \"Tela Inicio\" — calango_fx_official")
                Text("• \"Click buttons UI menu sounds effects button 6\" — skyscraper_seven")
                Text("—")
                Text("Core design, gameplay logic, and implementation: Bryan Zhang.")
                Text("OpenAI Codex assistance: Liquid Glass styling and secondary UI layout refinements.")
                Text("Most of this project was independently created by Bryan Zhang.")
            }
            .font(.system(size: 12, weight: .medium, design: .rounded))
            .foregroundColor(.white.opacity(0.8))
            .frame(maxWidth: .infinity, alignment: .leading)

            Text("I have read the acknowledgments and will proceed.")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.85))
                .multilineTextAlignment(.center)

            HStack(spacing: 12) {
                Button("Cancel", action: onCancel)
                    .buttonStyle(SecondaryButtonStyle())
                Button("Continue", action: onConfirm)
                    .buttonStyle(PrimaryButtonStyle())
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(Color.white.opacity(0.25), lineWidth: 1)
                )
                .overlay(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.35),
                            Color.white.opacity(0.12),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 22))
                )
        )
        .padding(.horizontal, 24)
    }
}

private struct GameView: View {
    @ObservedObject var engine: GameEngine
    let isMuted: Bool
    let onToggleMute: () -> Void
    let onPauseToggle: () -> Void
    let onStop: () -> Void
    let onDemoSkip: () -> Void
    @State private var legendInfo: LegendInfo?
    @State private var showDemoSkipConfirm = false
    @State private var hideDemoSkipNoticeThisRun = false

    var body: some View {
        ZStack {
            VStack(spacing: 14) {
                TopBar(engine: engine)
                    .padding(.horizontal, 16)

                WavePanel(
                    engine: engine,
                    isMuted: isMuted,
                    onToggleMute: onToggleMute,
                    onPauseToggle: onPauseToggle,
                    onStop: onStop,
                    onDemoSkip: {
                        if hideDemoSkipNoticeThisRun {
                            onDemoSkip()
                        } else {
                            showDemoSkipConfirm = true
                        }
                    }
                )
                .padding(.horizontal, 16)

                if let comboName = engine.comboName, engine.comboRemaining > 0 {
                    ComboBanner(name: comboName, remaining: engine.comboRemaining)
                        .padding(.horizontal, 16)
                }

                NetworkSceneView(engine: engine)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.horizontal, 12)

                LegendView { type in
                    legendInfo = info(for: type)
                }
                .padding(.horizontal, 16)

                RulesView()
                    .padding(.horizontal, 16)

                InsightBar(text: engine.lastInsight)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
            }

            if let info = legendInfo {
                Color.black.opacity(0.35)
                    .ignoresSafeArea()

                VStack(spacing: 12) {
                    Text(info.title)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text(info.body)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.85))
                        .multilineTextAlignment(.center)

                    Button("Got it") {
                        legendInfo = nil
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
                .padding(18)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(Color.white.opacity(0.25), lineWidth: 1)
                        )
                        .overlay(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.35),
                                    Color.white.opacity(0.12),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                        )
                )
                .padding(.horizontal, 28)
            }

            if showDemoSkipConfirm {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()

                DemoSkipOverlay(
                    dontShowAgain: $hideDemoSkipNoticeThisRun,
                    onCancel: {
                        showDemoSkipConfirm = false
                    },
                    onConfirm: {
                        showDemoSkipConfirm = false
                        onDemoSkip()
                    }
                )
            }

        }
        .padding(.top, 16)
        .onAppear {
            if !SoundPlayer.shared.isMuted {
                SoundPlayer.shared.playLoop("bgm", ext: "mp3", volume: 0.25)
            }
        }
        .onDisappear {
            SoundPlayer.shared.stop("bgm", ext: "mp3")
        }
        .onChange(of: engine.state) { newState in
            if newState == .idle {
                hideDemoSkipNoticeThisRun = false
                showDemoSkipConfirm = false
            }
        }
        .onChange(of: engine.timeRemaining) { newValue in
            if engine.state == .running && newValue == GameEngine.totalTime {
                hideDemoSkipNoticeThisRun = false
                showDemoSkipConfirm = false
            }
        }
    }

    private func info(for type: AttackType) -> LegendInfo {
        switch type {
        case .ddos:
            return LegendInfo(
                title: "DDoS",
                body: "A traffic flood that overwhelms bandwidth or servers. Filtering at the edge reduces the impact."
            )
        case .malware:
            return LegendInfo(
                title: "Malware",
                body: "Malicious code that moves through systems. Threat scanning helps detect and contain it."
            )
        case .phishing:
            return LegendInfo(
                title: "Phishing",
                body: "Deceptive messages that trick users into giving access. Training reduces success rates."
            )
        }
    }
}

private struct DemoSkipOverlay: View {
    @Binding var dontShowAgain: Bool
    let onCancel: () -> Void
    let onConfirm: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Text("Demo Skip")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Text("This skip is only for demo pacing. Final gameplay should run with normal progression.")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.85))
                .multilineTextAlignment(.center)

            Button(action: { dontShowAgain.toggle() }) {
                HStack(spacing: 8) {
                    Image(systemName: dontShowAgain ? "checkmark.square.fill" : "square")
                        .foregroundColor(.white)
                    Text("Don't show again in this run")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                }
            }
            .buttonStyle(.plain)

            HStack(spacing: 10) {
                Button("Cancel", action: onCancel)
                    .buttonStyle(SecondaryButtonStyle())
                Button("Use Demo Skip", action: onConfirm)
                    .buttonStyle(PrimaryButtonStyle())
            }
        }
        .padding(18)
        .frame(maxWidth: 420)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.25), lineWidth: 1)
                )
        )
        .padding(.horizontal, 18)
    }
}

private struct ControlButtonsRow: View {
    let isMuted: Bool
    let isPaused: Bool
    let isEnabled: Bool
    let onMute: () -> Void
    let onPauseToggle: () -> Void
    let onStop: () -> Void
    let onDemoSkip: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            ControlButton(
                systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill",
                enabled: true,
                action: onMute
            )
            ControlButton(
                systemName: isPaused ? "play.fill" : "pause.fill",
                enabled: isEnabled,
                action: onPauseToggle
            )
            ControlButton(
                systemName: "stop.fill",
                enabled: isEnabled,
                action: onStop
            )
            ControlButton(
                systemName: "forward.end.fill",
                enabled: isEnabled,
                action: onDemoSkip
            )
        }
    }
}

private struct ControlButton: View {
    let systemName: String
    let enabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white.opacity(enabled ? 1 : 0.4))
                .frame(width: 32, height: 32)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(Color.white.opacity(0.28), lineWidth: 1)
                        )
                        .overlay(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.35),
                                    Color.white.opacity(0.08),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        )
                )
        }
        .disabled(!enabled)
    }
}

private struct PauseOverlay: View {
    let onResume: () -> Void
    let onStop: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Text("Simulation Paused")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text("Real-world threats continue, so staying alert matters. Use this pause to plan your next move.")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.85))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 10)

            HStack(spacing: 12) {
                Button("Resume", action: onResume)
                    .buttonStyle(PrimaryButtonStyle())
                Button("Stop", action: onStop)
                    .buttonStyle(SecondaryButtonStyle())
            }
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(Color.white.opacity(0.25), lineWidth: 1)
                )
                .overlay(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.35),
                            Color.white.opacity(0.12),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 22))
                )
        )
        .padding(.horizontal, 24)
    }
}

private struct ScenarioOverlay: View {
    let scenario: ScenarioEvent
    let onChooseA: () -> Void
    let onChooseB: () -> Void

    var body: some View {
        GeometryReader { geo in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    Text("Command Decision")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text(scenario.title)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.95))

                    Text(scenario.prompt)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.85))
                        .multilineTextAlignment(.center)

                    ScenarioChoiceCard(choice: scenario.optionA)
                    ScenarioChoiceCard(choice: scenario.optionB)

                    ViewThatFits {
                        HStack(spacing: 10) {
                            Button(scenario.optionA.title, action: onChooseA)
                                .buttonStyle(PrimaryButtonStyle())
                            Button(scenario.optionB.title, action: onChooseB)
                                .buttonStyle(SecondaryButtonStyle())
                        }
                        VStack(spacing: 8) {
                            Button(scenario.optionA.title, action: onChooseA)
                                .buttonStyle(PrimaryButtonStyle())
                            Button(scenario.optionB.title, action: onChooseB)
                                .buttonStyle(SecondaryButtonStyle())
                        }
                    }
                }
                .padding(20)
            }
            .frame(maxWidth: min(620, geo.size.width - 24))
            .frame(maxHeight: min(geo.size.height * 0.8, 560))
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(Color.white.opacity(0.25), lineWidth: 1)
                    )
                    .overlay(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.35),
                                Color.white.opacity(0.12),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 22))
                    )
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 12)
            .padding(.vertical, 24)
        }
    }
}

private struct ScenarioChoiceCard: View {
    let choice: ScenarioChoice

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(choice.title)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text(choice.effect)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.75))
                .lineLimit(2)
            Text("Outcome: \(choice.consequence)")
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.95))
            Text("Learning: \(choice.lesson)")
                .font(.system(size: 10, weight: .regular, design: .rounded))
                .foregroundColor(.white.opacity(0.7))
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.08))
        )
    }
}

private struct TopBar: View {
    @ObservedObject var engine: GameEngine

    var body: some View {
        HStack(spacing: 10) {
            StatBadge(title: "Time", value: "\(engine.timeRemaining)s")
            StatBadge(title: "Server", value: "\(engine.serverHealth)%")
            StatBadge(title: "Energy", value: "\(engine.energy)")
        }
    }
}

private struct StatBadge: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.7))
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.white.opacity(0.25), lineWidth: 1)
                )
                .overlay(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.35),
                            Color.white.opacity(0.1),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                )
        )
    }
}

private struct LegendInfo: Identifiable {
    let id = UUID()
    let title: String
    let body: String
}

private struct LegendView: View {
    let onInfo: (AttackType) -> Void

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 12) {
                ForEach(AttackType.allCases, id: \.self) { type in
                    ZStack(alignment: .topTrailing) {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(type.color)
                                .frame(width: 10, height: 10)
                            Text(type.label)
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(
                            Capsule().fill(.ultraThinMaterial)
                        )

                        Button(action: {
                            onInfo(type)
                        }) {
                            Image(systemName: "questionmark.circle.fill")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white.opacity(0.9))
                                .background(
                                    Circle()
                                        .fill(.ultraThinMaterial)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white.opacity(0.25), lineWidth: 1)
                                        )
                                )
                        }
                        .offset(x: 6, y: -6)
                    }
                }
            }
            Text("Network Path: Threat Source -> Edge Router -> Core Router -> App Server")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
    }
}

private struct WavePanel: View {
    @ObservedObject var engine: GameEngine
    let isMuted: Bool
    let onToggleMute: () -> Void
    let onPauseToggle: () -> Void
    let onStop: () -> Void
    let onDemoSkip: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                Text(engine.waveLabel)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))

                Spacer()

                ControlButtonsRow(
                    isMuted: isMuted,
                    isPaused: engine.state == .paused,
                    isEnabled: engine.state != .idle,
                    onMute: onToggleMute,
                    onPauseToggle: onPauseToggle,
                    onStop: onStop,
                    onDemoSkip: onDemoSkip
                )
            }

            Text(engine.waveDetail)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.75))
                .lineLimit(2)

            ProgressView(value: Double(GameEngine.totalTime - engine.timeRemaining), total: Double(GameEngine.totalTime))
                .tint(.white)

            Text("Objective: keep the server online for the full 3 minutes.")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.72))
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                .overlay(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.25),
                            Color.white.opacity(0.08),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                )
        )
    }
}

private struct ComboBanner: View {
    let name: String
    let remaining: Int

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "link.circle.fill")
                .foregroundColor(.white)
            Text("\(name) active (\(remaining)s)")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
            Spacer()
            Text("Layered defense bonus")
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.75))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.white.opacity(0.25), lineWidth: 1)
                )
        )
    }
}

private struct IntelPauseOverlay: View {
    let event: IntelEvent
    let onContinue: () -> Void
    @State private var isExpanded = true

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Threat Intel")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Spacer()
                Button(action: { isExpanded.toggle() }) {
                    Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                        .foregroundColor(.white.opacity(0.9))
                }
                .buttonStyle(.plain)
            }

            Text(event.title)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.95))

            Text(event.recommendedAction)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.95))
                .multilineTextAlignment(.center)

            if isExpanded {
                Text(event.detail)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .transition(.opacity)
            }

            Button("Continue Simulation", action: onContinue)
                .buttonStyle(PrimaryButtonStyle())
        }
        .padding(18)
        .frame(maxWidth: 420)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.25), lineWidth: 1)
                )
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 18)
        .animation(.easeInOut(duration: 0.2), value: isExpanded)
    }
}

// TimeBar merged into WavePanel for a cleaner layout.

private struct RulesView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Defense Rules")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            RuleRow(color: AttackType.ddos.color, text: "Edge Firewall filters DDoS traffic")
            RuleRow(color: AttackType.malware.color, text: "Threat Scan detects malware")
            RuleRow(color: AttackType.phishing.color, text: "User Training reduces phishing risk")
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                .overlay(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.25),
                            Color.white.opacity(0.08),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                )
        )
    }
}

private struct RuleRow: View {
    let color: Color
    let text: String

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(text)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.85))
        }
    }
}

private struct InsightBar: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 13, weight: .medium, design: .rounded))
            .foregroundColor(.white)
            .multilineTextAlignment(.center)
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    .overlay(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.25),
                                Color.white.opacity(0.08),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    )
            )
    }
}

private struct IntroBullet: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Circle()
                .fill(Color.white)
                .frame(width: 6, height: 6)
                .padding(.top, 6)
            Text(text)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.85))
        }
    }
}

private struct LevelCard: View {
    let title: String
    let subtitle: String
    let isSelected: Bool
    let isLocked: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Text(title)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
                if isLocked {
                    Text("Locked")
                        .font(.system(size: 9, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.65))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected ? Color.white.opacity(0.2) : Color.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(
                                isSelected ? Color.white.opacity(0.55) : Color.white.opacity(0.2),
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(isLocked)
        .opacity(isLocked ? 0.7 : 1)
    }
}

private struct EndOverlay: View {
    let success: Bool
    let score: Int
    let health: Int
    let takeaway: String
    let questions: [QuizQuestion]
    let onExit: () -> Void
    let onReplay: () -> Void
    @State private var answers: [UUID: Bool] = [:]
    @State private var quizIndex: Int = 0

    var body: some View {
        GeometryReader { geo in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    Text(success ? "Server Stabilized" : "Service Disrupted")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text(success ? "You kept critical services online." : "Traffic exceeded the defenses.")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)

                    VStack(spacing: 6) {
                        EndStat(title: "Command Score", value: "\(score)")
                        EndStat(title: "Service Uptime", value: "\(health)%")
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Mission Takeaway")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text(takeaway)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.85))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    if let question = currentQuestion() {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Debrief Quiz")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(.white)

                            Text("Question \(quizIndex + 1) of \(questions.count)")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.72))

                            QuizQuestionCard(
                                question: question,
                                selected: answers[question.id],
                                onSelectA: {
                                    answers[question.id] = true
                                },
                                onSelectB: {
                                    answers[question.id] = false
                                }
                            )

                            if questions.count > 1 {
                                HStack(spacing: 8) {
                                    Button("Previous") {
                                        quizIndex = max(0, quizIndex - 1)
                                    }
                                    .buttonStyle(SecondaryButtonStyle())
                                    .disabled(quizIndex == 0)

                                    Button("Next") {
                                        quizIndex = min(questions.count - 1, quizIndex + 1)
                                    }
                                    .buttonStyle(SecondaryButtonStyle())
                                    .disabled(quizIndex >= questions.count - 1)
                                }
                            }

                            EndStat(
                                title: "Learning Score",
                                value: "\(correctAnswerCount()) / \(questions.count)"
                            )
                        }
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Key Principles")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text("- Filter volumetric traffic at the edge.")
                        Text("- Inspect lateral movement inside the network.")
                        Text("- Train users to reduce phishing impact.")
                    }
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
                    .frame(maxWidth: .infinity, alignment: .leading)

                    HStack(spacing: 12) {
                        Button("Back to Start", action: {
                            SoundPlayer.shared.duck("start", to: 0.0, for: 0.4)
                            SoundPlayer.shared.duck("bgm", to: 0.0, for: 0.4)
                            SoundPlayer.shared.play("click", ext: "mp3", volume: 1.0)
                            onExit()
                        })
                        .buttonStyle(PrimaryButtonStyle())
                        Button("Play Again", action: {
                            SoundPlayer.shared.duck("start", to: 0.0, for: 0.4)
                            SoundPlayer.shared.duck("bgm", to: 0.0, for: 0.4)
                            SoundPlayer.shared.play("click", ext: "mp3", volume: 1.0)
                            onReplay()
                        })
                        .buttonStyle(SecondaryButtonStyle())
                    }
                }
                .padding(20)
            }
            .frame(maxWidth: min(650, geo.size.width - 24))
            .frame(maxHeight: min(geo.size.height * 0.9, 720))
            .background(
                RoundedRectangle(cornerRadius: 26)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 26)
                            .stroke(Color.white.opacity(0.25), lineWidth: 1)
                    )
                    .overlay(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.35),
                                Color.white.opacity(0.12),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 26))
                    )
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 12)
            .padding(.vertical, 16)
        }
    }

    private func correctAnswerCount() -> Int {
        questions.reduce(0) { partial, question in
            guard let selected = answers[question.id] else { return partial }
            return partial + (selected == question.correctIsA ? 1 : 0)
        }
    }

    private func currentQuestion() -> QuizQuestion? {
        guard !questions.isEmpty else { return nil }
        let safeIndex = min(max(quizIndex, 0), questions.count - 1)
        return questions[safeIndex]
    }
}

private struct QuizQuestionCard: View {
    let question: QuizQuestion
    let selected: Bool?
    let onSelectA: () -> Void
    let onSelectB: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(question.prompt)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.9))

            HStack(spacing: 8) {
                quizChoiceButton(question.optionA, isSelected: selected == true, action: onSelectA)
                quizChoiceButton(question.optionB, isSelected: selected == false, action: onSelectB)
            }

            if let selected {
                let isCorrect = selected == question.correctIsA
                Text((isCorrect ? "Correct: " : "Review: ") + question.explanation)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(isCorrect ? .green.opacity(0.95) : .yellow.opacity(0.95))
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.08))
        )
    }

    private func quizChoiceButton(_ title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(isSelected ? Color.white.opacity(0.2) : Color.white.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(Color.white.opacity(isSelected ? 0.45 : 0.2), lineWidth: 1)
                        )
                )
        }
        .buttonStyle(.plain)
    }
}

private struct EndStat: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.white.opacity(0.75))
            Spacer()
            Text(value)
                .foregroundColor(.white)
        }
        .font(.system(size: 13, weight: .semibold, design: .rounded))
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
        )
    }
}

private struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .bold, design: .rounded))
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.35), lineWidth: 1)
                    )
                    .overlay(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.45),
                                Color.white.opacity(0.12),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .clipShape(Capsule())
                    )
            )
            .shadow(color: Color.white.opacity(0.15), radius: 10, x: 0, y: 6)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}

private struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .bold, design: .rounded))
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.25), lineWidth: 1)
                    )
                    .overlay(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.25),
                                Color.white.opacity(0.05),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .clipShape(Capsule())
                    )
            )
            .shadow(color: Color.white.opacity(0.08), radius: 8, x: 0, y: 4)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}

private struct BackgroundView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.12, blue: 0.2),
                    Color(red: 0.1, green: 0.25, blue: 0.3),
                    Color(red: 0.2, green: 0.15, blue: 0.25)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            GeometryReader { geo in
                Path { path in
                    let columns = 8
                    let rows = 10
                    let columnWidth = geo.size.width / CGFloat(columns)
                    let rowHeight = geo.size.height / CGFloat(rows)

                    for col in 0...columns {
                        let x = CGFloat(col) * columnWidth
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: geo.size.height))
                    }

                    for row in 0...rows {
                        let y = CGFloat(row) * rowHeight
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: geo.size.width, y: y))
                    }
                }
                .stroke(Color.white.opacity(0.04), lineWidth: 1)
            }
        }
    }
}
