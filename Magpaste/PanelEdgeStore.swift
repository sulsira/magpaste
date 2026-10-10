import Foundation

enum PanelEdgeStore {
    private static let key = "Magpaste.panelEdge"

    static func load() -> PanelEdge {
        guard let raw = UserDefaults.standard.string(forKey: key),
              let edge = PanelEdge(rawValue: raw) else { return .bottom }
        return edge
    }

    static func save(_ edge: PanelEdge) {
        UserDefaults.standard.set(edge.rawValue, forKey: key)
    }
}
