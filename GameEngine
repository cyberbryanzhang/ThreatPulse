import SwiftUI

@MainActor
final class GameEngine: NSObject, ObservableObject {
    enum State {
        case idle
        case running
        case paused
        case finished
    }

    static let totalTime: Int = 180

    @Published var state: State = .idle
    @Published var timeRemaining: Int = GameEngine.totalTime
    @Published var serverHealth: Int = 100
    @Published var energy: Int = 80
    @Published var score: Int = 0
    @Published var packets: [Packet] = []
    @Published var defenses: [NodeID: DefenseState] = [:]
    @Published var lastInsight: String = "Tap a node to deploy a defense."
    @Published var hitFlash: Bool = false
    @Published var currentScenario: ScenarioEvent?
    @Published var currentIntel: IntelEvent?
    @Published var comboName: String?
    @Published var comboRemaining: Int = 0

    let path: [NodeID] = [.attacker, .router1, .router2, .server]
    let configs: [NodeID: DefenseConfig]
    private let scenarios: [ScenarioEvent]
    private let intelEvents: [IntelEvent]

    private let framesPerSecond = 30
    private var tickTimer: Timer?
    private var frameCount: Int = 0
    private var spawnCounter: Int = 0
    private var flashFrames: Int = 0
    private let sound = SoundPlayer.shared
    private var triggeredScenarioTimes: Set<Int> = []
    private var defensesActivatedCount = 0
    private var totalBlockedCount = 0
    private var totalBreachCount = 0
    private var totalDamageTaken = 0
    private var blockedByType: [AttackType: Int] = [:]
    private var breachesByType: [AttackType: Int] = [:]
    private var triggeredIntelTimes: Set<Int> = []

    override init() {
        self.configs = GameEngine.makeConfigs()
        self.scenarios = GameEngine.makeScenarios()
        self.intelEvents = GameEngine.makeIntelEvents()
        super.init()
        resetToIdle()
    }

    var waveLabel: String {
        if timeRemaining > 120 {
            return "Wave 1: Flood at the Edge"
        } else if timeRemaining > 60 {
            return "Wave 2: Stealth Intrusion"
        } else {
            return "Wave 3: Phishing Pressure"
        }
    }

    var waveDetail: String {
        if timeRemaining > 120 {
            return "Heavy DDoS traffic incoming. Use Edge Firewall early."
        } else if timeRemaining > 60 {
            return "Malware packets are increasing. Keep Threat Scan ready."
        } else {
            return "Phishing attempts are rising. Activate User Training in time."
        }
    }

    var debriefQuestions: [QuizQuestion] {
        let topType = AttackType.allCases.max { lhs, rhs in
            breachesByType[lhs, default: 0] < breachesByType[rhs, default: 0]
        } ?? .ddos

        let weaknessQuestion: QuizQuestion
        switch topType {
        case .ddos:
            weaknessQuestion = QuizQuestion(
                prompt: "Which defense best reduces DDoS pressure at the start of the path?",
                optionA: "Edge Firewall at Edge Router",
                optionB: "User Training at App Server",
                correctIsA: true,
                explanation: "DDoS is volumetric traffic. Blocking it at the edge protects all downstream nodes."
            )
        case .malware:
            weaknessQuestion = QuizQuestion(
                prompt: "Which node should scan for suspicious malware behavior in transit?",
                optionA: "Threat Scan at Core Router",
                optionB: "Edge Firewall at Edge Router",
                correctIsA: true,
                explanation: "Threat Scan is designed for malware detection and containment inside the network."
            )
        case .phishing:
            weaknessQuestion = QuizQuestion(
                prompt: "What lowers phishing success when attacks target users?",
                optionA: "User Training at App Server",
                optionB: "Edge Firewall at Edge Router",
                correctIsA: true,
                explanation: "Phishing is a human-focused attack, so user awareness is the direct control."
            )
        }

        let comboQuestion = QuizQuestion(
            prompt: "What does the combo effect teach in this simulation?",
            optionA: "Layered defenses work better together than alone",
            optionB: "One defense can handle every attack type",
            correctIsA: true,
            explanation: "Defense in depth is the core lesson: combining controls improves resilience."
        )

        let timingQuestion = QuizQuestion(
            prompt: "When is it usually best to activate defenses in this game?",
            optionA: "After attacks already reach the server",
            optionB: "Before packet waves peak at each node",
            correctIsA: false,
            explanation: "Early activation gives defenses time to block traffic before damage happens."
        )

        let resourceQuestion = QuizQuestion(
            prompt: "Why does energy management matter?",
            optionA: "It controls how often and how many defenses you can deploy",
            optionB: "It only changes the score display",
            correctIsA: true,
            explanation: "Even correct defenses fail if energy is spent too early without planning."
        )

        return [weaknessQuestion, comboQuestion, timingQuestion, resourceQuestion]
    }

    var missionTakeaway: String {
        let ddos = breachesByType[.ddos, default: 0]
        let malware = breachesByType[.malware, default: 0]
        let phishing = breachesByType[.phishing, default: 0]
        let top = max(ddos, malware, phishing)

        if top == 0 {
            return "Great discipline. You maintained layered defense and reduced all major attack paths."
        }
        if top == ddos {
            return "Main weakness: DDoS handling. Activate Edge Firewall earlier to reduce volumetric impact."
        }
        if top == malware {
            return "Main weakness: malware detection timing. Keep Threat Scan ready before mid-wave spikes."
        }
        return "Main weakness: phishing resilience. Prioritize User Training before late-wave social attacks."
    }

    func start() {
        resetForRun()
        state = .running
        tickTimer?.invalidate()
        tickTimer = Timer.scheduledTimer(
            timeInterval: 1.0 / Double(framesPerSecond),
            target: self,
            selector: #selector(handleTick),
            userInfo: nil,
            repeats: true
        )
    }

    func stop() {
        tickTimer?.invalidate()
        tickTimer = nil
    }

    func pause() {
        if state == .running && currentScenario == nil {
            state = .paused
            setInsight("Paused. Real-world threats continue, so staying alert matters.")
        }
    }

    func resume() {
        if state == .paused && currentScenario == nil && currentIntel == nil {
            state = .running
            setInsight("Simulation resumed.")
        }
    }

    func resetToIdle() {
        stop()
        state = .idle
        timeRemaining = GameEngine.totalTime
        serverHealth = 100
        energy = 80
        score = 0
        packets = []
        defenses = GameEngine.makeInitialDefenseStates()
        lastInsight = "Tap a node to deploy a defense."
        frameCount = 0
        spawnCounter = 0
        hitFlash = false
        flashFrames = 0
        currentScenario = nil
        currentIntel = nil
        comboName = nil
        comboRemaining = 0
        triggeredScenarioTimes = []
        triggeredIntelTimes = []
        defensesActivatedCount = 0
        totalBlockedCount = 0
        totalBreachCount = 0
        totalDamageTaken = 0
        blockedByType = [:]
        breachesByType = [:]
    }

    func resetForRun() {
        timeRemaining = GameEngine.totalTime
        serverHealth = 100
        energy = 80
        score = 0
        packets = []
        defenses = GameEngine.makeInitialDefenseStates()
        setInsight("Hold the line for 180 seconds.")
        frameCount = 0
        spawnCounter = 0
        hitFlash = false
        flashFrames = 0
        currentScenario = nil
        currentIntel = nil
        comboName = nil
        comboRemaining = 0
        triggeredScenarioTimes = []
        triggeredIntelTimes = []
        defensesActivatedCount = 0
        totalBlockedCount = 0
        totalBreachCount = 0
        totalDamageTaken = 0
        blockedByType = [:]
        breachesByType = [:]
    }

    func activateDefense(_ node: NodeID) {
        guard state == .running else { return }
        guard let config = configs[node] else { return }
        guard var defense = defenses[node] else { return }

        if defense.isActive {
            setInsight("\(config.name) is already active.")
            return
        }

        if defense.cooldownRemaining > 0 {
            setInsight("\(config.name) is recharging.")
            return
        }

        if energy < config.cost {
            setInsight("Not enough energy to deploy \(config.name).")
            return
        }

        energy -= config.cost
        defense.isActive = true
        defense.activeRemaining = config.duration
        defense.cooldownRemaining = 0
        defenses[node] = defense
        defensesActivatedCount += 1
        triggerComboIfPossible()
        setInsight(config.detail)
        sound.play("deploy")
    }

    func acknowledgeIntel() {
        currentIntel = nil
        if state == .paused {
            state = .running
            setInsight("Intel acknowledged. Simulation resumed.")
        }
    }

    func demoSkipWave() {
        guard state == .running else { return }
        if timeRemaining > 120 {
            timeRemaining = 120
            packets.removeAll()
            energy = min(100, energy + 20)
            setInsight("Demo skip: moved to Wave 2.")
        } else if timeRemaining > 60 {
            timeRemaining = 60
            packets.removeAll()
            energy = min(100, energy + 20)
            setInsight("Demo skip: moved to Wave 3.")
        } else {
            timeRemaining = min(timeRemaining, 12)
            packets.removeAll()
            setInsight("Demo skip: moved near the final seconds.")
        }
    }

    func chooseScenario(optionA: Bool) {
        guard state == .paused, let scenario = currentScenario else { return }
        let choice = optionA ? scenario.optionA : scenario.optionB

        serverHealth = max(0, min(100, serverHealth + choice.healthDelta))
        energy = max(0, min(100, energy + choice.energyDelta))
        score = max(0, score + choice.scoreDelta)

        currentScenario = nil
        state = .running
        setInsight(choice.effect)
    }

    private func tick() {
        guard state == .running else { return }

        frameCount += 1
        spawnCounter += 1

        updatePackets()
        updateFlash()

        if frameCount % framesPerSecond == 0 {
            updateEverySecond()
        }

        spawnPacketsIfNeeded()
        checkEndConditions()
    }

    @objc private func handleTick() {
        tick()
    }

    private func updateEverySecond() {
        timeRemaining = max(0, timeRemaining - 1)
        energy = min(100, energy + 12)
        updateDefenses()
        updateComboState()
        checkScenarioTrigger()
        checkIntelTrigger()
    }

    private func updateDefenses() {
        for node in Array(defenses.keys) {
            guard var defense = defenses[node] else { continue }
        if defense.isActive {
            if defense.activeRemaining > 0 {
                defense.activeRemaining -= 1
            }
                if defense.activeRemaining <= 0 {
                    defense.isActive = false
                    defense.cooldownRemaining = configs[node]?.cooldown ?? 0
                }
            } else if defense.cooldownRemaining > 0 {
                defense.cooldownRemaining -= 1
            }
            defenses[node] = defense
        }
    }

    private func updatePackets() {
        guard !packets.isEmpty else { return }
        var updated: [Packet] = []
        updated.reserveCapacity(packets.count)

        for var packet in packets {
            packet.progress += packet.speed

            if packet.progress >= 1 {
                let nextIndex = packet.segmentIndex + 1
                if nextIndex >= path.count {
                    continue
                }

                let nextNode = path[nextIndex]
                if shouldBlock(packet: packet, at: nextNode) {
                    score += 10
                    totalBlockedCount += 1
                    blockedByType[packet.type, default: 0] += 1
                    setInsight("\(configs[nextNode]?.name ?? "Defense") blocked \(packet.type.label).")
                    sound.play("block")
                    continue
                }

                if nextNode == .server {
                    let damage = computedDamage(for: packet.type)
                    serverHealth = max(0, serverHealth - damage)
                    totalBreachCount += 1
                    totalDamageTaken += damage
                    breachesByType[packet.type, default: 0] += 1
                    setInsight("\(packet.type.label) reached the server. Patch and train users.")
                    sound.play("hit")
                    flashFrames = 6
                    continue
                }

                packet.segmentIndex = nextIndex
                packet.progress = 0
                updated.append(packet)
            } else {
                updated.append(packet)
            }
        }

        packets = updated
    }

    private func updateFlash() {
        if flashFrames > 0 {
            flashFrames -= 1
        }
        hitFlash = flashFrames > 0
    }

    private func shouldBlock(packet: Packet, at node: NodeID) -> Bool {
        guard let config = configs[node], let defense = defenses[node] else { return false }
        return defense.isActive && config.blocks == packet.type
    }

    private func spawnPacketsIfNeeded() {
        guard currentScenario == nil else { return }
        let spawnEvery = spawnIntervalFrames()
        if spawnCounter >= spawnEvery {
            spawnCounter = 0
            packets.append(Packet(type: spawnType(), speed: spawnSpeed()))
        }
    }

    private func spawnIntervalFrames() -> Int {
        if timeRemaining > 120 {
            return 56
        } else if timeRemaining > 60 {
            return 42
        } else {
            return 34
        }
    }

    private func spawnType() -> AttackType {
        let roll = Int.random(in: 0...99)
        if timeRemaining > 120 {
            if roll < 60 { return .ddos }
            if roll < 80 { return .phishing }
            return .malware
        } else if timeRemaining > 60 {
            if roll < 40 { return .ddos }
            if roll < 70 { return .malware }
            return .phishing
        } else {
            if roll < 30 { return .ddos }
            if roll < 65 { return .malware }
            return .phishing
        }
    }

    private func spawnSpeed() -> Double {
        let base: Double
        if timeRemaining > 120 {
            base = 0.008
        } else if timeRemaining > 60 {
            base = 0.0105
        } else {
            base = 0.013
        }
        return base + Double.random(in: 0.0...0.0025)
    }

    private func checkEndConditions() {
        if currentScenario != nil { return }
        if timeRemaining <= 0 || serverHealth <= 0 {
            state = .finished
            stop()
            if serverHealth > 0 {
                setInsight("You stabilized the network. Nice defense timing.")
                sound.play("win")
            } else {
                setInsight("Service was disrupted. Try activating defenses earlier.")
                sound.play("lose")
            }
        }
    }

    private func setInsight(_ message: String) {
        lastInsight = message
    }

    private func computedDamage(for type: AttackType) -> Int {
        var value = type.damage
        if comboName == "Containment Mode" {
            value = max(1, value / 2)
        }
        if comboName == "Awareness Mode" && type == .phishing {
            value = max(1, value - 2)
        }
        return value
    }

    private func checkScenarioTrigger() {
        guard currentScenario == nil else { return }

        for scenario in scenarios where scenario.triggerTime == timeRemaining {
            if triggeredScenarioTimes.contains(scenario.triggerTime) { continue }
            triggeredScenarioTimes.insert(scenario.triggerTime)
            currentScenario = scenario
            state = .paused
            setInsight("Decision point: \(scenario.title)")
            break
        }
    }

    private func checkIntelTrigger() {
        guard state == .running else { return }
        for event in intelEvents where event.triggerTime == timeRemaining {
            if triggeredIntelTimes.contains(event.triggerTime) { continue }
            triggeredIntelTimes.insert(event.triggerTime)
            currentIntel = event
            state = .paused
            setInsight("Threat Intel: \(event.recommendedAction)")
            break
        }
    }

    private func triggerComboIfPossible() {
        guard comboRemaining <= 0 else { return }
        let edgeActive = defenses[.router1]?.isActive ?? false
        let coreActive = defenses[.router2]?.isActive ?? false
        let userActive = defenses[.server]?.isActive ?? false

        if edgeActive && coreActive {
            comboName = "Containment Mode"
            comboRemaining = 10
            setInsight("Combo activated: Containment Mode (incoming damage reduced).")
            return
        }

        if coreActive && userActive {
            comboName = "Awareness Mode"
            comboRemaining = 8
            setInsight("Combo activated: Awareness Mode (phishing impact reduced).")
        }
    }

    private func updateComboState() {
        guard comboRemaining > 0 else { return }
        if comboName == "Awareness Mode" {
            score += 2
        }
        comboRemaining -= 1
        if comboRemaining <= 0 {
            setInsight("Combo ended. Rebuild layered defense to reactivate it.")
            comboName = nil
            comboRemaining = 0
        }
    }

    private static func makeConfigs() -> [NodeID: DefenseConfig] {
        [
            .router1: DefenseConfig(
                name: "Edge Firewall",
                detail: "Edge Firewall active: filter volumetric traffic before it reaches the core.",
                blocks: .ddos,
                duration: 14,
                cooldown: 6,
                cost: 20
            ),
            .router2: DefenseConfig(
                name: "Threat Scan",
                detail: "Threat Scan active: inspect traffic for malware patterns.",
                blocks: .malware,
                duration: 14,
                cooldown: 6,
                cost: 20
            ),
            .server: DefenseConfig(
                name: "User Training",
                detail: "User Training active: reduce phishing impact on the app server.",
                blocks: .phishing,
                duration: 14,
                cooldown: 6,
                cost: 20
            )
        ]
    }

    private static func makeScenarios() -> [ScenarioEvent] {
        [
            ScenarioEvent(
                triggerTime: 150,
                title: "Patch Window",
                prompt: "A weak endpoint is detected at the edge router. Do you patch now or keep all attention on live traffic?",
                optionA: ScenarioChoice(
                    title: "Patch Now",
                    effect: "Fast patch deployed. Stability improved, but you spent energy.",
                    consequence: "+6 Service, -18 Energy, +8 Score",
                    lesson: "Early patching reduces attack surface but consumes response capacity.",
                    healthDelta: 6,
                    energyDelta: -18,
                    scoreDelta: 8
                ),
                optionB: ScenarioChoice(
                    title: "Hold Traffic Focus",
                    effect: "No downtime for patching, but that weak endpoint remains exposed.",
                    consequence: "-6 Service, +10 Energy, +0 Score",
                    lesson: "Deferring patching preserves resources now but increases future risk.",
                    healthDelta: -6,
                    energyDelta: 10,
                    scoreDelta: 0
                )
            ),
            ScenarioEvent(
                triggerTime: 95,
                title: "Suspicious Attachment",
                prompt: "Several employees report a suspicious file. Do you run an immediate awareness push or ignore it for now?",
                optionA: ScenarioChoice(
                    title: "Run Awareness Push",
                    effect: "Phishing resilience improved across users.",
                    consequence: "+4 Service, -12 Energy, +10 Score",
                    lesson: "Human-layer defense can prevent access loss from social attacks.",
                    healthDelta: 4,
                    energyDelta: -12,
                    scoreDelta: 10
                ),
                optionB: ScenarioChoice(
                    title: "Ignore for Now",
                    effect: "More staff may click risky links during this wave.",
                    consequence: "-8 Service, +12 Energy, -2 Score",
                    lesson: "Ignoring early warning signs increases exposure to phishing.",
                    healthDelta: -8,
                    energyDelta: 12,
                    scoreDelta: -2
                )
            ),
            ScenarioEvent(
                triggerTime: 45,
                title: "Final Resource Split",
                prompt: "You can either boost monitoring to catch more threats or reserve power for manual response.",
                optionA: ScenarioChoice(
                    title: "Boost Monitoring",
                    effect: "Detection rate increased in the final minute.",
                    consequence: "+8 Service, -16 Energy, +14 Score",
                    lesson: "Monitoring investment improves visibility when pressure peaks.",
                    healthDelta: 8,
                    energyDelta: -16,
                    scoreDelta: 14
                ),
                optionB: ScenarioChoice(
                    title: "Reserve Power",
                    effect: "You preserved energy but reduced automated coverage.",
                    consequence: "-4 Service, +18 Energy, -2 Score",
                    lesson: "Holding resources can help later, but creates immediate blind spots.",
                    healthDelta: -4,
                    energyDelta: 18,
                    scoreDelta: -2
                )
            )
        ]
    }

    private static func makeInitialDefenseStates() -> [NodeID: DefenseState] {
        [
            .router1: DefenseState(isActive: false, activeRemaining: 0, cooldownRemaining: 0),
            .router2: DefenseState(isActive: false, activeRemaining: 0, cooldownRemaining: 0),
            .server: DefenseState(isActive: false, activeRemaining: 0, cooldownRemaining: 0)
        ]
    }

    private static func makeIntelEvents() -> [IntelEvent] {
        [
            IntelEvent(
                triggerTime: 165,
                title: "Intel #1",
                detail: "Traffic signatures show a volumetric flood pattern at the edge.",
                recommendedAction: "Prioritize Edge Firewall before packet volume spikes."
            ),
            IntelEvent(
                triggerTime: 125,
                title: "Intel #2",
                detail: "A sandbox alert indicates executable payload behavior in lateral traffic.",
                recommendedAction: "Prepare Threat Scan at Core Router to catch malware."
            ),
            IntelEvent(
                triggerTime: 82,
                title: "Intel #3",
                detail: "Credential lure messages are being sent to internal users.",
                recommendedAction: "Use User Training before phishing wave reaches the server."
            ),
            IntelEvent(
                triggerTime: 52,
                title: "Intel #4",
                detail: "Attackers are rotating methods quickly across channels.",
                recommendedAction: "Stack defenses to trigger combo protection."
            )
        ]
    }
}
