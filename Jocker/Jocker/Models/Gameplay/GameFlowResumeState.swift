import Foundation

struct GameFlowResumeState: Codable {
    enum Stage: String, Codable {
        case readyToDeal, blind, deal, trump, bidding, playing, joker, roundEnd, terminal
    }
    var stage: Stage = .readyToDeal
    var order: [Int] = []
    var step: Int = 0
    var bids: [Int] = []
    var blindSelections: [Bool] = []
    var answered: [Bool] = []
    var remainingHands: [[CardSnapshot]] = []
    var chooser: Int = 0
}
