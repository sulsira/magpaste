import Foundation

/// Which screen edge the history panel docks to.
enum PanelEdge: String, Codable, CaseIterable {
    case left
    case right
    case top
    case bottom

    /// Left/right dock a tall sidebar with a column of cards;
    /// top/bottom dock a wide bar with a row of cards.
    var isVertical: Bool {
        self == .left || self == .right
    }
}
