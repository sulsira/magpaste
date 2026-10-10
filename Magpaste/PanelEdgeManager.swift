import SwiftUI

final class PanelEdgeManager: ObservableObject {
    static let shared = PanelEdgeManager()

    @Published var edge: PanelEdge = PanelEdgeStore.load() {
        didSet { PanelEdgeStore.save(edge) }
    }

    private init() {}
}
