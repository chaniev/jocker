//
//  BotBidSelectionService.swift
//  Jocker
//
//  Created by Codex on 06.03.2026.
//

import Foundation

struct BotBidSelectionService {
    private struct BidCandidate {
        let bid: Int
        let projectedScore: Int
        let distanceToExpected: Int
    }

    private let policy: BotRuntimePolicy.Bidding.BidSelection
    private let handStrengthModel: BotHandStrengthModel

    init(
        policy: BotRuntimePolicy.Bidding.BidSelection,
        handStrengthModel: BotHandStrengthModel
    ) {
        self.policy = policy
        self.handStrengthModel = handStrengthModel
    }

    func makeBid(
        hand: [Card],
        cardsInRound: Int,
        trump: Suit?,
        forbiddenBid: Int?,
        matchContext: BotMatchContext? = nil
    ) -> Int {
        let maxBid = max(0, cardsInRound)
        let expectedTricks = handStrengthModel.biddingExpectedTricks(
            hand: hand,
            cardsInRound: maxBid,
            trump: trump
        )

        let candidates = (0...maxBid).map { bid in
            BidCandidate(
                bid: bid,
                projectedScore: ScoreCalculator.calculateRoundScore(
                    cardsInRound: maxBid,
                    bid: bid,
                    tricksTaken: expectedTricks,
                    isBlind: false
                ),
                distanceToExpected: abs(bid - expectedTricks)
            )
        }
        guard let unconstrainedBest = bestProjectedBid(in: candidates) else { return 0 }

        let legalCandidates = candidates.filter { candidate in
            if let forbiddenBid {
                return candidate.bid != forbiddenBid
            }
            return true
        }
        guard !legalCandidates.isEmpty else {
            return unconstrainedBest.bid
        }

        let forbiddenTouchesOptimum = forbiddenBid == unconstrainedBest.bid
        var bestCandidate = legalCandidates[0]
        var bestUtility = bidUtility(
            candidate: bestCandidate,
            unconstrainedBest: unconstrainedBest,
            expectedTricks: expectedTricks,
            forbiddenTouchesOptimum: forbiddenTouchesOptimum,
            matchContext: matchContext
        )

        for candidate in legalCandidates.dropFirst() {
            let candidateUtility = bidUtility(
                candidate: candidate,
                unconstrainedBest: unconstrainedBest,
                expectedTricks: expectedTricks,
                forbiddenTouchesOptimum: forbiddenTouchesOptimum,
                matchContext: matchContext
            )
            if candidateUtility > bestUtility + policy.utilityTieTolerance {
                bestUtility = candidateUtility
                bestCandidate = candidate
                continue
            }
            if abs(candidateUtility - bestUtility) <= policy.utilityTieTolerance {
                if candidate.projectedScore > bestCandidate.projectedScore {
                    bestCandidate = candidate
                    continue
                }
                if candidate.projectedScore == bestCandidate.projectedScore {
                    let candidateDistanceToOptimum = abs(candidate.bid - unconstrainedBest.bid)
                    let bestDistanceToOptimum = abs(bestCandidate.bid - unconstrainedBest.bid)
                    if candidateDistanceToOptimum < bestDistanceToOptimum {
                        bestCandidate = candidate
                        continue
                    }
                    if candidateDistanceToOptimum == bestDistanceToOptimum &&
                        candidate.distanceToExpected < bestCandidate.distanceToExpected {
                        bestCandidate = candidate
                    }
                }
            }
        }

        return bestCandidate.bid
    }

    private func bestProjectedBid(in candidates: [BidCandidate]) -> BidCandidate? {
        guard let first = candidates.first else { return nil }
        var best = first
        for candidate in candidates.dropFirst() {
            if candidate.projectedScore > best.projectedScore {
                best = candidate
            } else if candidate.projectedScore == best.projectedScore &&
                candidate.distanceToExpected < best.distanceToExpected {
                best = candidate
            }
        }
        return best
    }

    private func bidUtility(
        candidate: BidCandidate,
        unconstrainedBest: BidCandidate,
        expectedTricks: Int,
        forbiddenTouchesOptimum: Bool,
        matchContext: BotMatchContext?
    ) -> Double {
        let projectedGap = Double(max(0, unconstrainedBest.projectedScore - candidate.projectedScore))
        let distanceToOptimum = abs(candidate.bid - unconstrainedBest.bid)
        let distanceToExpected = abs(candidate.bid - expectedTricks)

        let blockProgress = matchContext?.blockProgressFraction ?? 0.0
        let optimalityPenaltyWeight = forbiddenTouchesOptimum
            ? (policy.optimalityPenaltyBase + policy.optimalityPenaltyProgress * blockProgress)
            : (policy.optimalityPenaltyBaseNoForbidden +
                policy.optimalityPenaltyProgressNoForbidden * blockProgress)
        let expectedPenaltyWeight = policy.expectedPenaltyBase + policy.expectedPenaltyProgress * blockProgress
        let scoreGapPenaltyWeight = forbiddenTouchesOptimum
            ? policy.scoreGapPenaltyForbidden
            : policy.scoreGapPenaltyNoForbidden

        return Double(candidate.projectedScore) -
            projectedGap * scoreGapPenaltyWeight -
            Double(distanceToOptimum) * optimalityPenaltyWeight -
            Double(distanceToExpected) * expectedPenaltyWeight
    }
}
