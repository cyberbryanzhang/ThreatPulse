import SwiftUI

enum AttackType: CaseIterable {
    case ddos
    case malware
    case phishing

    var label: String {
        switch self {
        case .ddos: return "DDoS"
        case .malware: return "Malware"
        case .phishing: return "Phishing"
        }
    }

    var color: Color {
        switch self {
        case .ddos: return Color(red: 0.95, green: 0.35, blue: 0.2)
        case .malware: return Color(red: 0.2, green: 0.92, blue: 0.95)
        case .phishing: return Color(red: 0.95, green: 0.8, blue: 0.3)
        }
    }

    var damage: Int {
        switch self {
        case .ddos: return 5
        case .malware: return 7
        case .phishing: return 3
        }
    }
}

enum NodeID: CaseIterable {
    case attacker
    case router1
    case router2
    case server

    var label: String {
        switch self {
        case .attacker: return "Threat Source"
        case .router1: return "Edge Router"
        case .router2: return "Core Router"
        case .server: return "App Server"
        }
    }
}

struct Packet: Identifiable {
    let id: UUID
    let type: AttackType
    var segmentIndex: Int
    var progress: Double
    var speed: Double

    init(type: AttackType, speed: Double) {
        self.id = UUID()
        self.type = type
        self.segmentIndex = 0
        self.progress = 0
        self.speed = speed
    }
}

struct DefenseConfig {
    let name: String
    let detail: String
    let blocks: AttackType
    let duration: Int
    let cooldown: Int
    let cost: Int
}

struct DefenseState {
    var isActive: Bool
    var activeRemaining: Int
    var cooldownRemaining: Int
}

struct ScenarioChoice {
    let title: String
    let effect: String
    let consequence: String
    let lesson: String
    let healthDelta: Int
    let energyDelta: Int
    let scoreDelta: Int
}

struct ScenarioEvent: Identifiable {
    let id = UUID()
    let triggerTime: Int
    let title: String
    let prompt: String
    let optionA: ScenarioChoice
    let optionB: ScenarioChoice
}

struct IntelEvent: Identifiable {
    let id = UUID()
    let triggerTime: Int
    let title: String
    let detail: String
    let recommendedAction: String
}

struct QuizQuestion: Identifiable {
    let id = UUID()
    let prompt: String
    let optionA: String
    let optionB: String
    let correctIsA: Bool
    let explanation: String
}
