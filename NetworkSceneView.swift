import SwiftUI

struct NetworkSceneView: View {
    @ObservedObject var engine: GameEngine

    private let nodePositions: [NodeID: CGPoint] = [
        .attacker: CGPoint(x: 0.12, y: 0.5),
        .router1: CGPoint(x: 0.35, y: 0.25),
        .router2: CGPoint(x: 0.62, y: 0.75),
        .server: CGPoint(x: 0.88, y: 0.5)
    ]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                edges(in: geo.size)

                ForEach(engine.packets) { packet in
                    Circle()
                        .fill(packet.type.color)
                        .frame(width: 10, height: 10)
                        .shadow(color: packet.type.color.opacity(0.6), radius: 6, x: 0, y: 0)
                        .position(position(for: packet, in: geo.size))
                }

                ForEach(NodeID.allCases, id: \.self) { node in
                    nodeView(for: node)
                        .position(point(for: node, in: geo.size))
                }
            }
        }
    }

    @ViewBuilder
    private func nodeView(for node: NodeID) -> some View {
        let config = engine.configs[node]
        let defense = engine.defenses[node]

        if node == .attacker {
            NodeBadge(
                title: node.label,
                subtitle: "Source",
                tint: Color(red: 0.85, green: 0.2, blue: 0.2),
                isInteractive: false,
                statusText: ""
            ) {}
        } else {
            NodeBadge(
                title: node.label,
                subtitle: config?.name ?? "Defense",
                tint: config?.blocks.color ?? .white,
                isInteractive: true,
                statusText: statusText(for: defense)
            ) {
                engine.activateDefense(node)
            }
            .overlay(activeRing(isActive: defense?.isActive ?? false, color: config?.blocks.color ?? .white))
        }
    }

    private func edges(in size: CGSize) -> some View {
        let points = engine.path.compactMap { nodePositions[$0] }.map { $0.scaled(to: size) }
        return Path { path in
            guard let first = points.first else { return }
            path.move(to: first)
            for point in points.dropFirst() {
                path.addLine(to: point)
            }
        }
        .stroke(Color.white.opacity(0.3), style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round, dash: [8, 6]))
    }

    private func position(for packet: Packet, in size: CGSize) -> CGPoint {
        let startNode = engine.path[packet.segmentIndex]
        let endNode = engine.path[min(packet.segmentIndex + 1, engine.path.count - 1)]
        let start = point(for: startNode, in: size)
        let end = point(for: endNode, in: size)
        return start.interpolate(to: end, t: packet.progress)
    }

    private func point(for node: NodeID, in size: CGSize) -> CGPoint {
        guard let normalized = nodePositions[node] else { return .zero }
        return normalized.scaled(to: size)
    }

    private func statusText(for defense: DefenseState?) -> String {
        guard let defense else { return "" }
        if defense.isActive {
            return "Active \(defense.activeRemaining)s"
        }
        if defense.cooldownRemaining > 0 {
            return "Cooldown \(defense.cooldownRemaining)s"
        }
        return "Ready"
    }

    private func activeRing(isActive: Bool, color: Color) -> some View {
        Circle()
            .stroke(color.opacity(isActive ? 0.8 : 0), lineWidth: 4)
            .scaleEffect(isActive ? 1.18 : 1.0)
            .shadow(color: color.opacity(isActive ? 0.6 : 0), radius: 8)
            .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isActive)
    }
}

private struct NodeBadge: View {
    let title: String
    let subtitle: String
    let tint: Color
    let isInteractive: Bool
    let statusText: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
                if !statusText.isEmpty {
                    Text(statusText)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.black.opacity(0.35)))
                }
            }
            .frame(width: 114, height: 84)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(tint.opacity(0.85), lineWidth: 2)
                    )
                    .overlay(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.3),
                                Color.white.opacity(0.08),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    )
            )
        }
        .buttonStyle(.plain)
        .allowsHitTesting(isInteractive)
    }
}

private extension CGPoint {
    func scaled(to size: CGSize) -> CGPoint {
        CGPoint(x: x * size.width, y: y * size.height)
    }

    func interpolate(to other: CGPoint, t: Double) -> CGPoint {
        let clamped = min(max(t, 0), 1)
        return CGPoint(
            x: x + (other.x - x) * clamped,
            y: y + (other.y - y) * clamped
        )
    }
}
