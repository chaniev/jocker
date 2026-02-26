# BOT AI Test Scenarios (Draft)

## Цель

Черновик детерминированных регрессионных сценариев для сравнения `baseline vs candidate`
при изменениях игрового AI бота.

Документ покрывает минимальные группы из `BOT_AI_IMPROVEMENT_PLAN.md`:
- `BLIND-*`
- `PREMIUM-*`
- `JOKER-*`
- `PHASE-*`

## Как использовать

1. Зафиксировать `baseline` (ветка/коммит, seed, команды).
2. Прогнать сценарии вручную или через тестовый harness.
3. Для каждого кейса записать:
   - фактическое решение baseline,
   - фактическое решение candidate,
   - совпадение/расхождение с ожидаемым поведением,
   - комментарий (если расхождение допустимо).

## Шаблон записи кейса

```text
ID: BLIND-001
Category: BLIND
Priority: High
Goal: ...

Setup:
- playerCount:
- block:
- cardsInRound:
- dealerIndex:
- currentPlayerIndex:
- scores:
- trump:
- bid/tricks:
- hand:
- current trick state:
- allowed blind bids (if applicable):

Expected behavior:
- ...
- ...

Observed (baseline):
- ...

Observed (candidate):
- ...
```

## Reproducibility (baseline template)

- Date: `2026-02-22`
- Baseline commit: `<fill>`
- Candidate commit: `<fill>`
- Seed set (match-level): `[101, 202, 303, 404, 505]` (example)
- Player config: `4 players`, all bots, `hard`
- Commands:
  - `make bt-hard-fullgame-balanced`
  - `make bt-hard-fullgame-battle`
  - `make bt-hard-final`

## Metrics Table Template

| Metric | Baseline | Candidate | Delta | Notes |
|---|---:|---:|---:|---|
| winRate |  |  |  |  |
| averageScoreDiff |  |  |  |  |
| averageUnderbidLoss |  |  |  |  |
| averagePremiumAssistLoss |  |  |  |  |
| averagePremiumPenaltyTargetLoss |  |  |  |  |
| premiumCaptureRate |  |  |  |  |
| blindSuccessRate |  |  |  |  |
| jokerWishWinRate |  |  |  |  |
| earlyJokerSpendRate |  |  |  |  |
| penaltyTargetRate |  |  |  |  |
| leftNeighborPremiumAssistRate |  |  |  |  |
| bidAccuracyRate |  |  |  |  |
| overbidRate |  |  |  |  |

## Concrete Serialized Drafts (v0)

Ниже JSON-like заготовки для первых детерминированных кейсов. Формат можно позже
привести к точному schema для тестового harness.

### Case Draft: BLIND-001

```json
{
  "id": "BLIND-001",
  "stateType": "preDealBlindBid",
  "inputs": {
    "playerIndex": 1,
    "dealerIndex": 0,
    "cardsInRound": 9,
    "allowedBlindBids": [0,1,2,3,4,5,6,7,8,9],
    "canChooseBlind": true,
    "totalScores": [1200, 950, 620, 600]
  },
  "expected": {
    "blindBid": null,
    "reason": "safe-gap protection over catch-up risk"
  }
}
```

### Case Draft: BLIND-002

```json
{
  "id": "BLIND-002",
  "stateType": "preDealBlindBid",
  "inputs": {
    "playerIndex": 1,
    "dealerIndex": 0,
    "cardsInRound": 9,
    "allowedBlindBids": [0,1,2,3,4,5,6,7,8,9],
    "canChooseBlind": true,
    "totalScores": [1250, 950, 800, 780]
  },
  "expected": {
    "blindBid": "non-null",
    "mode": "catch-up"
  }
}
```

### Case Draft: BLIND-003

```json
{
  "id": "BLIND-003",
  "stateType": "preDealBlindBid-compare",
  "inputs": {
    "cardsInRound": 4,
    "allowedBlindBids": [0,1,2,3,4],
    "canChooseBlind": true,
    "totalScores": [1210, 1000, 980, 960],
    "cases": [
      { "label": "nonDealer", "playerIndex": 1, "dealerIndex": 0 },
      { "label": "dealer", "playerIndex": 1, "dealerIndex": 1 }
    ]
  },
  "expected": {
    "nonDealerBlindBid": "non-null",
    "dealerBlindBid": null
  }
}
```

### Case Draft: JOKER-001

```json
{
  "id": "JOKER-001",
  "stateType": "runtimeTurnDecision",
  "inputs": {
    "handCards": ["JOKER", "H-7"],
    "trick": [
      { "playerIndex": 0, "card": "C-A", "jokerPlayStyle": "faceUp", "jokerLeadDeclaration": null }
    ],
    "trump": "S",
    "bid": 0,
    "tricksTaken": 0,
    "cardsInRound": 5,
    "playerCount": 4,
    "isBlind": true
  },
  "expected": {
    "preferredCard": "H-7",
    "reason": "avoid low-value early joker spend in blind dump mode"
  }
}
```

### Case Draft: PHASE-001

```json
{
  "id": "PHASE-001",
  "stateType": "cardThreatProbe-compare",
  "inputs": {
    "card": "H-A",
    "decision": { "style": "faceUp", "leadDeclaration": null },
    "trump": "H",
    "trick": [],
    "cardsInRound": 8,
    "phaseVariants": [
      { "label": "early", "cardsRemainingInHandBeforeMove": 8 },
      { "label": "late", "cardsRemainingInHandBeforeMove": 1 }
    ]
  },
  "expected": {
    "relationship": "threat(early) > threat(late)"
  }
}
```

### Case Draft: JOKER-002

```json
{
  "id": "JOKER-002",
  "stateType": "runtimeTurnDecision",
  "inputs": {
    "handCards": ["JOKER", "S-A", "S-7", "H-K"],
    "trick": [],
    "trump": "S",
    "bid": 1,
    "tricksTaken": 0,
    "cardsInRound": 4,
    "playerCount": 4,
    "isBlind": false
  },
  "expected": {
    "notAlways": "lead joker + wish",
    "preferredPattern": "decision depends on chase/dump and trump context",
    "acceptedLeadJokerDeclarations": ["wish", "above(S)", "takes(non-trump)"]
  }
}
```

### Case Draft: JOKER-003

```json
{
  "id": "JOKER-003",
  "stateType": "rankingUtility-compare",
  "inputs": {
    "moveVariants": [
      { "label": "aboveTrump", "move": { "card": "JOKER", "decision": { "style": "faceUp", "leadDeclaration": "above(S)" } } },
      { "label": "aboveNonTrump", "move": { "card": "JOKER", "decision": { "style": "faceUp", "leadDeclaration": "above(H)" } } }
    ],
    "shared": {
      "trick": [],
      "trump": "S",
      "projectedScore": 30,
      "immediateWinProbability": 0.95,
      "threat": 100,
      "shouldChaseTrick": true,
      "tricksNeededToMatchBid": 1,
      "tricksRemainingIncludingCurrent": 4,
      "chasePressure": 0.25
    }
  },
  "expected": {
    "relationship": "utility(aboveTrump) > utility(aboveNonTrump)",
    "reason": "stage-5 fallback joker declaration utility should prefer stronger control in chase"
  }
}
```

### Case Draft: JOKER-004

```json
{
  "id": "JOKER-004",
  "stateType": "runtimeTurnDecision-compare",
  "inputs": {
    "sharedTemplate": {
      "handCards": ["JOKER", "C-6", "D-7", "H-8"],
      "trick": [],
      "trump": "S",
      "tricksTaken": 0,
      "cardsInRound": 8,
      "playerCount": 4
    },
    "variants": [
      { "label": "controlChase", "bid": 1 },
      { "label": "allInChase", "bid": 4 }
    ]
  },
  "expected": {
    "relationship": "lead-joker declaration may flip from above(trump) to wish as chase urgency increases to all-in",
    "diagnostic": "diagnostic draft only: runtime probe retired from automated pack; use ranking/evaluator strict + neighboring runtime strict guardrails"
  }
}
```

### Case Draft: JOKER-005

```json
{
  "id": "JOKER-005",
  "stateType": "forcedLeadJokerDeclaration",
  "inputs": {
    "legalCards": ["JOKER"],
    "handCards": ["JOKER", "C-6", "D-7", "H-8"],
    "trick": [],
    "trump": "S",
    "cardsInRound": 8,
    "playerCount": 4,
    "variants": [
      { "label": "dump", "targetBid": 0, "currentTricks": 0 },
      { "label": "earlyChase", "targetBid": 1, "currentTricks": 0 }
    ]
  },
  "expected": {
    "dump": "takes(non-trump)",
    "earlyChase": "above(trump)",
    "reason": "Stage-5 MVP should use `takes` as controlled-loss lead in dump and avoid it for early chase control"
  }
}
```

### Case Draft: JOKER-006

```json
{
  "id": "JOKER-006",
  "stateType": "runtimeTurnDecision-strict",
  "inputs": {
    "handCards": ["JOKER", "S-A", "S-K", "S-Q"],
    "trick": [],
    "trump": "S",
    "bid": 0,
    "tricksTaken": 2,
    "cardsInRound": 8,
    "playerCount": 4
  },
  "expected": {
    "relationship": "runtime chooses lead-joker + takes(non-trump) in early overbid dump when non-joker leads are risky trump wins"
  }
}
```

### Case Draft: JOKER-007

```json
{
  "id": "JOKER-007",
  "stateType": "rankingUtility-compare",
  "inputs": {
    "shared": {
      "trick": [],
      "trump": "S",
      "projectedScore": 30,
      "immediateWinProbability": 0.95,
      "threat": 100,
      "shouldChaseTrick": true,
      "tricksNeededToMatchBid": 1,
      "tricksRemainingIncludingCurrent": 4,
      "chasePressure": 0.25
    },
    "moveVariants": [
      { "label": "wish", "move": { "card": "JOKER", "decision": { "style": "faceUp", "leadDeclaration": "wish" } } },
      { "label": "aboveTrump", "move": { "card": "JOKER", "decision": { "style": "faceUp", "leadDeclaration": "above(S)" } } }
    ],
    "reserveVariants": [
      { "label": "lowReserve", "leadControlReserveAfterMove": 0.0 },
      { "label": "highReserve", "leadControlReserveAfterMove": 1.0 }
    ]
  },
  "expected": {
    "relationship": "advantage(aboveTrump over wish) should be stronger under lowReserve than highReserve",
    "reason": "low remaining control after lead-joker should increase immediate-control preference in early chase"
  }
}
```

### Case Draft: JOKER-008

```json
{
  "id": "JOKER-008",
  "stateType": "runtimeTurnDecision-compare-strict",
  "inputs": {
    "sharedTemplate": {
      "trick": [],
      "trump": "S",
      "bid": 3,
      "tricksTaken": 0,
      "cardsInRound": 8,
      "playerCount": 4
    },
    "variants": [
      {
        "label": "lowControlReserveAfterLeadJoker",
        "handCards": ["JOKER", "C-6", "D-7", "H-8"]
      },
      {
        "label": "higherControlReserveAfterLeadJoker",
        "handCards": ["JOKER", "S-8", "S-9", "S-10"]
      }
    ]
  },
  "expected": {
    "relationship": "runtime lead-joker declaration differs by remaining control reserve after lead-joker in early high-pressure chase (low-reserve branch keeps stronger immediate-control declaration)"
  }
}
```

### Case Draft: JOKER-009

```json
{
  "id": "JOKER-009",
  "stateType": "runtimeTurnDecision-assert-diagnostic",
  "inputs": {
    "sharedTemplate": {
      "handCards": ["JOKER", "C-6", "D-7", "H-8"],
      "trick": [],
      "trump": "S",
      "tricksTaken": 0,
      "cardsInRound": 8,
      "playerCount": 4
    },
    "variants": [
      { "label": "earlyChase", "bid": 1 },
      { "label": "allInChase", "bid": 4 }
    ]
  },
  "expected": {
    "earlyChaseDecision": { "card": "JOKER", "leadDeclaration": "above(S)" },
    "allInChaseDecision": { "card": "JOKER", "leadDeclaration": "wish" },
    "reason": "diagnostic runtime shape for urgency-driven declaration shift; strict automated variant retired after instability across later architectural changes"
  }
}
```

### Case Draft: JOKER-010

```json
{
  "id": "JOKER-010",
  "stateType": "rankingUtility-compare",
  "inputs": {
    "shared": {
      "trick": [],
      "trump": "S",
      "cardsInRound": 8,
      "tricksRemainingIncludingCurrent": 4
    },
    "subcases": [
      {
        "label": "dumpOwnPremiumProtection",
        "shouldChaseTrick": false,
        "moves": ["wish", "takes(non-trump)"],
        "expectation": "ownPremiumContext increases utility advantage of takes(non-trump) over wish"
      },
      {
        "label": "chaseAntiPremiumPressure",
        "shouldChaseTrick": true,
        "moves": ["wish", "above(trump)"],
        "expectation": "antiPremiumPressure context increases utility advantage of above(trump) over wish"
      }
    ]
  },
  "expected": {
    "reason": "Stage-5 premium-aware declaration scoring should react to block premium/penalty context"
  }
}
```

### Case Draft: JOKER-011

```json
{
  "id": "JOKER-011",
  "stateType": "runtimeTurnDecision-compare-strict",
  "inputs": {
    "sharedTemplate": {
      "handCards": ["JOKER", "C-6", "D-7", "H-8"],
      "trick": [],
      "trump": "S",
      "bid": 4,
      "tricksTaken": 0,
      "cardsInRound": 8,
      "playerCount": 4
    },
    "variants": [
      {
        "label": "neutralContext",
        "matchContextPremium": {
          "leftNeighborIsPremiumCandidateSoFar": false,
          "isPenaltyTargetRiskSoFar": false,
          "premiumCandidatesThreateningPenaltyCount": 0,
          "opponentPremiumCandidatesSoFarCount": 0
        }
      },
      {
        "label": "antiPremiumPressureContext",
        "matchContextPremium": {
          "leftNeighborIsPremiumCandidateSoFar": true,
          "isPenaltyTargetRiskSoFar": true,
          "premiumCandidatesThreateningPenaltyCount": 1,
          "opponentPremiumCandidatesSoFarCount": 2
        }
      }
    ]
  },
  "expected": {
    "relationship": "runtime lead-joker declaration flips from wish to above(trump) under anti-premium pressure in all-in chase"
  }
}
```

### Case Draft: JOKER-012

```json
{
  "id": "JOKER-012",
  "stateType": "rankingUtility-compare",
  "inputs": {
    "shared": {
      "trick": [],
      "cardsInRound": 8,
      "tricksRemainingIncludingCurrent": 4
    },
    "subcases": [
      {
        "label": "chaseAbovePreferredSuit",
        "shouldChaseTrick": true,
        "trump": "C",
        "preferredControlSuitAfterMove": "S",
        "preferredControlSuitStrengthAfterMove": 1.0,
        "expectation": "above(S) > above(H)"
      },
      {
        "label": "dumpTakesPreferredSuitPenalty",
        "shouldChaseTrick": false,
        "trump": "C",
        "preferredControlSuitAfterMove": "S",
        "preferredControlSuitStrengthAfterMove": 1.0,
        "expectation": "takes(S) < takes(H)"
      }
    ]
  },
  "expected": {
    "reason": "Stage-5 suit-control-aware declaration scoring should react to post-joker preferred control suit"
  }
}
```

### Case Draft: JOKER-013

```json
{
  "id": "JOKER-013",
  "stateType": "runtimeTurnDecision-compare-strict",
  "inputs": {
    "sharedTemplate": {
      "trick": [],
      "trump": "C",
      "bid": 3,
      "tricksTaken": 0,
      "cardsInRound": 8,
      "playerCount": 4
    },
    "variants": [
      {
        "label": "spadePreferredControlAfterJoker",
        "handCards": ["JOKER", "S-10", "S-9", "H-6"]
      },
      {
        "label": "heartPreferredControlAfterJoker",
        "handCards": ["JOKER", "H-10", "H-9", "S-6"]
      }
    ]
  },
  "expected": {
    "relationship": "runtime lead-joker declaration shifts from above(S) to above(H) by preferred post-joker control suit under early high-pressure chase"
  }
}
```

### Case Draft: JOKER-014

```json
{
  "id": "JOKER-014",
  "stateType": "runtimeTurnDecision-assert",
  "inputs": {
    "handCards": ["JOKER", "S-A", "S-K", "S-Q"],
    "trick": [],
    "trump": "S",
    "bid": 0,
    "tricksTaken": 1,
    "cardsInRound": 8,
    "playerCount": 4,
    "matchContext": {
      "block": 4,
      "roundIndexInBlock": 7,
      "totalRoundsInBlock": 8,
      "totalScores": [100, 100, 100, 100],
      "playerIndex": 0,
      "dealerIndex": 2,
      "premium": {
        "completedRoundsInBlock": 7,
        "remainingRoundsInBlock": 1,
        "isPremiumCandidateSoFar": true,
        "isZeroPremiumRelevantInBlock": false,
        "isZeroPremiumCandidateSoFar": false,
        "leftNeighborIsPremiumCandidateSoFar": false,
        "isPenaltyTargetRiskSoFar": false,
        "premiumCandidatesThreateningPenaltyCount": 0,
        "opponentPremiumCandidatesSoFarCount": 0
      }
    }
  },
  "expected": {
    "card": "JOKER",
    "leadDeclaration": "takes(non-trump)",
    "reason": "early overbid dump with own-premium protection should prefer controlled-loss lead-joker over risky trump leads"
  }
}
```

### Case Draft: JOKER-015

```json
{
  "id": "JOKER-015",
  "stateType": "forcedLeadJokerDeclaration-assert",
  "inputs": {
    "legalCards": ["JOKER"],
    "sharedTemplate": {
      "trick": [],
      "trump": "C",
      "targetBid": 1,
      "currentTricks": 0,
      "cardsInRound": 8,
      "playerCount": 4
    },
    "variants": [
      {
        "label": "spadeControlDominates",
        "handCards": ["JOKER", "S-K", "S-Q", "H-6"],
        "expectedLeadDeclaration": "above(S)"
      },
      {
        "label": "heartControlDominates",
        "handCards": ["JOKER", "H-K", "H-Q", "S-6"],
        "expectedLeadDeclaration": "above(H)"
      }
    ]
  },
  "expected": {
    "reason": "Evaluator should use preferred post-joker control suit signal when selecting `above(<suit>)` in early chase"
  }
}
```

### Case Draft: PHASE-002

```json
{
  "id": "PHASE-002",
  "stateType": "runtimeTurnDecision-compare",
  "inputs": {
    "sharedTemplate": {
      "trick": [],
      "trump": "S",
      "bid": 0,
      "tricksTaken": 0,
      "playerCount": 4,
      "handCards": ["S-10", "H-A"]
    },
    "variants": [
      { "label": "earlyPhaseProbe", "cardsInRound": 2 },
      { "label": "latePhaseProbe", "cardsInRound": 8 }
    ]
  },
  "expected": {
    "relationship": "candidate decision may differ by phase context",
    "diagnostic": "if equal under current tuning, treat as retuning target instead of hard failure"
  }
}
```

### Case Draft: PREMIUM-003

```json
{
  "id": "PREMIUM-003",
  "stateType": "runtimeTurnDecision-compare",
  "inputs": {
    "sharedTemplate": {
      "handCards": ["C-A", "D-K"],
      "trick": [
        { "playerIndex": 1, "card": "H-Q", "jokerPlayStyle": "faceUp", "jokerLeadDeclaration": null }
      ],
      "trump": "S",
      "bid": 0,
      "tricksTaken": 0,
      "cardsInRound": 8,
      "playerCount": 4
    },
    "variants": [
      {
        "label": "neutralContext",
        "matchContext": {
          "block": 4,
          "roundIndexInBlock": 7,
          "totalRoundsInBlock": 8,
          "totalScores": [100, 100, 100, 100],
          "playerIndex": 0,
          "dealerIndex": 2,
          "premium": null
        }
      },
      {
        "label": "ownPremiumCandidateLateBlock",
        "matchContext": {
          "block": 4,
          "roundIndexInBlock": 7,
          "totalRoundsInBlock": 8,
          "totalScores": [100, 100, 100, 100],
          "playerIndex": 0,
          "dealerIndex": 2,
          "premium": {
            "completedRoundsInBlock": 7,
            "remainingRoundsInBlock": 1,
            "isPremiumCandidateSoFar": true,
            "isZeroPremiumRelevantInBlock": false,
            "isZeroPremiumCandidateSoFar": false
          }
        }
      }
    ]
  },
  "expected": {
    "relationship": "candidate decision may differ due to premiumPreserveUtility",
    "diagnostic": "if equal under current tuning, treat as retuning target instead of hard failure"
  }
}
```

### Case Draft: PREMIUM-004

```json
{
  "id": "PREMIUM-004",
  "stateType": "rankingUtility-compare",
  "inputs": {
    "mode": "dump",
    "sameMoveMetrics": {
      "projectedScore": 10,
      "immediateWinProbability": 0.30,
      "threat": 5
    },
    "utilityContextShared": {
      "shouldChaseTrick": false,
      "tricksNeededToMatchBid": 0,
      "tricksRemainingIncludingCurrent": 2,
      "premium": {
        "completedRoundsInBlock": 7,
        "remainingRoundsInBlock": 1,
        "isPremiumCandidateSoFar": true,
        "isZeroPremiumRelevantInBlock": false,
        "isZeroPremiumCandidateSoFar": false
      }
    },
    "variants": [
      { "label": "exactBidBeforeMove", "trickDeltaToBidBeforeMove": 0 },
      { "label": "alreadyOverbidBroken", "trickDeltaToBidBeforeMove": 1 }
    ]
  },
  "expected": {
    "relationship": "utility(exactBidBeforeMove) > utility(alreadyOverbidBroken)",
    "reason": "premiumPreserveUtility should de-emphasize protection after exact bid is already broken"
  }
}
```

### Case Draft: PREMIUM-005

```json
{
  "id": "PREMIUM-005",
  "stateType": "rankingUtility-compare",
  "inputs": {
    "mode": "dump",
    "sameMoveMetrics": {
      "projectedScore": 140,
      "immediateWinProbability": 0.25,
      "threat": 5
    },
    "utilityContextShared": {
      "shouldChaseTrick": false,
      "tricksNeededToMatchBid": 0,
      "tricksRemainingIncludingCurrent": 2,
      "trickDeltaToBidBeforeMove": 1,
      "premium": {
        "completedRoundsInBlock": 7,
        "remainingRoundsInBlock": 1,
        "isPremiumCandidateSoFar": false,
        "isZeroPremiumRelevantInBlock": false,
        "isZeroPremiumCandidateSoFar": false
      }
    },
    "variants": [
      {
        "label": "noPenaltyRisk",
        "penaltyRisk": {
          "isPenaltyTargetRiskSoFar": false,
          "premiumCandidatesThreateningPenaltyCount": 0
        }
      },
      {
        "label": "penaltyTargetRisk",
        "penaltyRisk": {
          "isPenaltyTargetRiskSoFar": true,
          "premiumCandidatesThreateningPenaltyCount": 1
        }
      }
    ]
  },
  "expected": {
    "relationship": "utility(penaltyTargetRisk) < utility(noPenaltyRisk)",
    "reason": "penaltyAvoidUtility should devalue high-positive lines when bot is likely penalty target"
  }
}
```

### Case Draft: PREMIUM-006

```json
{
  "id": "PREMIUM-006",
  "stateType": "runtimeTurnDecision-compare",
  "inputs": {
    "sharedTemplate": {
      "handCards": ["C-A", "C-7"],
      "trick": [
        { "playerIndex": 1, "card": "C-Q", "jokerPlayStyle": "faceUp", "jokerLeadDeclaration": null }
      ],
      "trump": "H",
      "bid": 0,
      "tricksTaken": 1,
      "cardsInRound": 8,
      "playerCount": 4
    },
    "variants": [
      {
        "label": "neutralPenaltyRisk",
        "matchContext": {
          "block": 4,
          "roundIndexInBlock": 7,
          "totalRoundsInBlock": 8,
          "totalScores": [100, 100, 100, 100],
          "playerIndex": 0,
          "dealerIndex": 2,
          "premium": {
            "completedRoundsInBlock": 7,
            "remainingRoundsInBlock": 1,
            "isPremiumCandidateSoFar": false,
            "isZeroPremiumRelevantInBlock": false,
            "isZeroPremiumCandidateSoFar": false,
            "isPenaltyTargetRiskSoFar": false,
            "premiumCandidatesThreateningPenaltyCount": 0
          }
        }
      },
      {
        "label": "penaltyTargetRisk",
        "matchContext": {
          "block": 4,
          "roundIndexInBlock": 7,
          "totalRoundsInBlock": 8,
          "totalScores": [100, 100, 100, 100],
          "playerIndex": 0,
          "dealerIndex": 2,
          "premium": {
            "completedRoundsInBlock": 7,
            "remainingRoundsInBlock": 1,
            "isPremiumCandidateSoFar": false,
            "isZeroPremiumRelevantInBlock": false,
            "isZeroPremiumCandidateSoFar": false,
            "isPenaltyTargetRiskSoFar": true,
            "premiumCandidatesThreateningPenaltyCount": 1
          }
        }
      }
    ]
  },
  "expected": {
    "relationship": "candidate decision may differ due to penaltyAvoidUtility / anti-premium pressure",
    "diagnostic": "if equal under current tuning, treat as retuning target instead of hard failure"
  }
}
```

### Case Draft: PREMIUM-007

```json
{
  "id": "PREMIUM-007",
  "stateType": "rankingUtility-compare",
  "inputs": {
    "mode": "dump",
    "sameMoveMetrics": {
      "projectedScore": 40,
      "immediateWinProbability": 0.20,
      "threat": 5
    },
    "variants": [
      {
        "label": "nonLeftPremiumCandidateOnly",
        "premium": {
          "isPremiumCandidateSoFar": false,
          "isZeroPremiumCandidateSoFar": false,
          "leftNeighborIsPremiumCandidateSoFar": false,
          "opponentPremiumCandidatesSoFarCount": 1
        }
      },
      {
        "label": "leftNeighborPriorityPlusAnotherCandidate",
        "premium": {
          "isPremiumCandidateSoFar": false,
          "isZeroPremiumCandidateSoFar": false,
          "leftNeighborIsPremiumCandidateSoFar": true,
          "opponentPremiumCandidatesSoFarCount": 2
        }
      }
    ]
  },
  "expected": {
    "relationship": "utility(leftNeighborPriorityPlusAnotherCandidate) < utility(nonLeftPremiumCandidateOnly)",
    "reason": "anti-premium pressure should prioritize left-neighbor premium path over generic opponent premium pressure"
  }
}
```

### Case Draft: PREMIUM-008

```json
{
  "id": "PREMIUM-008",
  "stateType": "runtimeTurnDecision-compare",
  "inputs": {
    "sharedTemplate": {
      "handCards": ["C-A", "C-7"],
      "trick": [
        { "playerIndex": 1, "card": "C-Q", "jokerPlayStyle": "faceUp", "jokerLeadDeclaration": null }
      ],
      "trump": "H",
      "bid": 0,
      "tricksTaken": 1,
      "cardsInRound": 8,
      "playerCount": 4
    },
    "variants": [
      {
        "label": "neutralAntiPremium",
        "matchContext": {
          "block": 4,
          "roundIndexInBlock": 7,
          "totalRoundsInBlock": 8,
          "totalScores": [100, 100, 100, 100],
          "playerIndex": 0,
          "dealerIndex": 2,
          "premium": {
            "completedRoundsInBlock": 7,
            "remainingRoundsInBlock": 1,
            "isPremiumCandidateSoFar": false,
            "isZeroPremiumRelevantInBlock": false,
            "isZeroPremiumCandidateSoFar": false,
            "leftNeighborIsPremiumCandidateSoFar": false,
            "isPenaltyTargetRiskSoFar": false,
            "premiumCandidatesThreateningPenaltyCount": 0,
            "opponentPremiumCandidatesSoFarCount": 0
          }
        }
      },
      {
        "label": "leftNeighborPremiumCandidate",
        "matchContext": {
          "block": 4,
          "roundIndexInBlock": 7,
          "totalRoundsInBlock": 8,
          "totalScores": [100, 100, 100, 100],
          "playerIndex": 0,
          "dealerIndex": 2,
          "premium": {
            "completedRoundsInBlock": 7,
            "remainingRoundsInBlock": 1,
            "isPremiumCandidateSoFar": false,
            "isZeroPremiumRelevantInBlock": false,
            "isZeroPremiumCandidateSoFar": false,
            "leftNeighborIsPremiumCandidateSoFar": true,
            "isPenaltyTargetRiskSoFar": false,
            "premiumCandidatesThreateningPenaltyCount": 0,
            "opponentPremiumCandidatesSoFarCount": 1
          }
        }
      }
    ]
  },
  "expected": {
    "relationship": "candidate decision may differ due to premiumDenyUtility (left-neighbor priority)",
    "diagnostic": "if equal under current tuning, treat as retuning target instead of hard failure"
  }
}
```

### Case Draft: PREMIUM-009

```json
{
  "id": "PREMIUM-009",
  "stateType": "runtimeTurnDecision-assert",
  "inputs": {
    "handCards": ["C-A", "C-7"],
    "trick": [
      { "playerIndex": 1, "card": "C-Q", "jokerPlayStyle": "faceUp", "jokerLeadDeclaration": null },
      { "playerIndex": 2, "card": "C-K", "jokerPlayStyle": "faceUp", "jokerLeadDeclaration": null },
      { "playerIndex": 3, "card": "C-J", "jokerPlayStyle": "faceUp", "jokerLeadDeclaration": null }
    ],
    "trump": "H",
    "bid": 0,
    "tricksTaken": 1,
    "cardsInRound": 8,
    "playerCount": 4,
    "variants": [
      {
        "label": "neutral",
        "matchContext": {
          "block": 4,
          "roundIndexInBlock": 7,
          "totalRoundsInBlock": 8,
          "totalScores": [100, 100, 100, 100],
          "playerIndex": 0,
          "dealerIndex": 2,
          "premium": {
            "completedRoundsInBlock": 7,
            "remainingRoundsInBlock": 1,
            "isPremiumCandidateSoFar": false,
            "isZeroPremiumRelevantInBlock": false,
            "isZeroPremiumCandidateSoFar": false,
            "leftNeighborIsPremiumCandidateSoFar": false,
            "isPenaltyTargetRiskSoFar": false,
            "premiumCandidatesThreateningPenaltyCount": 0,
            "opponentPremiumCandidatesSoFarCount": 0
          }
        }
      },
      {
        "label": "strongAntiPremium",
        "matchContext": {
          "block": 4,
          "roundIndexInBlock": 7,
          "totalRoundsInBlock": 8,
          "totalScores": [100, 100, 100, 100],
          "playerIndex": 0,
          "dealerIndex": 2,
          "premium": {
            "completedRoundsInBlock": 7,
            "remainingRoundsInBlock": 1,
            "isPremiumCandidateSoFar": false,
            "isZeroPremiumRelevantInBlock": false,
            "isZeroPremiumCandidateSoFar": false,
            "leftNeighborIsPremiumCandidateSoFar": true,
            "isPenaltyTargetRiskSoFar": false,
            "premiumCandidatesThreateningPenaltyCount": 0,
            "opponentPremiumCandidatesSoFarCount": 4
          }
        }
      }
    ]
  },
  "expected": {
    "neutralDecision": "C-7",
    "strongAntiPremiumDecision": "C-A",
    "reason": "maximized 4c anti-premium pressure should outweigh neutral dump preference on last seat"
  }
}
```

### Case Draft: BLIND-004

```json
{
  "id": "BLIND-004",
  "stateType": "rankingUtility-compare",
  "inputs": {
    "mode": "chase",
    "isBlindRound": true,
    "sameMoveMetrics": {
      "projectedScore": 10,
      "immediateWinProbability": 0.85,
      "threat": 6
    },
    "move": "regular winning non-joker",
    "variants": [
      {
        "label": "disciplinedObservedLeftNeighbor",
        "matchContext": {
          "block": 4,
          "roundIndexInBlock": 7,
          "opponents": {
            "leftNeighbor": {
              "observedRounds": 4,
              "blindBidRate": 0.50,
              "exactBidRate": 0.75,
              "overbidRate": 0.10,
              "underbidRate": 0.15,
              "averageBidAggression": 0.72
            }
          }
        }
      },
      {
        "label": "erraticObservedLeftNeighbor",
        "matchContext": {
          "block": 4,
          "roundIndexInBlock": 7,
          "opponents": {
            "leftNeighbor": {
              "observedRounds": 4,
              "blindBidRate": 0.0,
              "exactBidRate": 0.20,
              "overbidRate": 0.45,
              "underbidRate": 0.35,
              "averageBidAggression": 0.35
            }
          }
        }
      },
      {
        "label": "noEvidenceObservedLeftNeighbor",
        "matchContext": {
          "block": 4,
          "roundIndexInBlock": 7,
          "opponents": {
            "leftNeighbor": {
              "observedRounds": 0
            }
          }
        }
      }
    ]
  },
  "expected": {
    "relationship": "utility(disciplinedObservedLeftNeighbor) > utility(erraticObservedLeftNeighbor)",
    "neutralityGuardrail": "utility(noEvidenceObservedLeftNeighbor) ~= utility(noOpponentsContext)",
    "reason": "Stage-6b blind-chase reward scaling should react to opponent style only when evidence exists"
  }
}
```

### Case Draft: PREMIUM-010

```json
{
  "id": "PREMIUM-010",
  "stateType": "rankingUtility-compare",
  "inputs": {
    "mode": "dump",
    "targetSignal": "premiumDenyUtility (left-neighbor premium candidate)",
    "sameMoveMetrics": {
      "projectedScore": 40,
      "immediateWinProbability": 0.20,
      "threat": 5
    },
    "variants": [
      {
        "label": "disciplinedObservedLeftNeighbor",
        "premium": {
          "leftNeighborIsPremiumCandidateSoFar": true,
          "opponentPremiumCandidatesSoFarCount": 1
        },
        "opponents": { "leftNeighbor": { "observedRounds": 4, "exactBidRate": 0.75, "overbidRate": 0.10, "underbidRate": 0.15, "blindBidRate": 0.50, "averageBidAggression": 0.72 } }
      },
      {
        "label": "erraticObservedLeftNeighbor",
        "premium": {
          "leftNeighborIsPremiumCandidateSoFar": true,
          "opponentPremiumCandidatesSoFarCount": 1
        },
        "opponents": { "leftNeighbor": { "observedRounds": 4, "exactBidRate": 0.20, "overbidRate": 0.45, "underbidRate": 0.35, "blindBidRate": 0.0, "averageBidAggression": 0.35 } }
      },
      {
        "label": "noEvidenceObservedLeftNeighbor",
        "premium": {
          "leftNeighborIsPremiumCandidateSoFar": true,
          "opponentPremiumCandidatesSoFarCount": 1
        },
        "opponents": { "leftNeighbor": { "observedRounds": 0 } }
      }
    ]
  },
  "expected": {
    "relationship": "utility(disciplinedObservedLeftNeighbor) < utility(erraticObservedLeftNeighbor)",
    "neutralityGuardrail": "utility(noEvidenceObservedLeftNeighbor) ~= utility(noOpponentsContext)",
    "reason": "Stage-6b premiumDeny calibration should strengthen anti-premium pressure only under observed evidence"
  }
}
```

### Case Draft: PREMIUM-011

```json
{
  "id": "PREMIUM-011",
  "stateType": "rankingUtility-compare",
  "inputs": {
    "mode": "dump",
    "targetSignal": "penaltyAvoidUtility (penaltyTargetRisk)",
    "sameMoveMetrics": {
      "projectedScore": 140,
      "immediateWinProbability": 0.25,
      "threat": 5
    },
    "premium": {
      "isPenaltyTargetRiskSoFar": true,
      "premiumCandidatesThreateningPenaltyCount": 1
    },
    "variants": [
      {
        "label": "disciplinedObservedLeftNeighbor",
        "opponents": { "leftNeighbor": { "observedRounds": 4, "exactBidRate": 0.75, "overbidRate": 0.10, "underbidRate": 0.15, "blindBidRate": 0.50, "averageBidAggression": 0.72 } }
      },
      {
        "label": "erraticObservedLeftNeighbor",
        "opponents": { "leftNeighbor": { "observedRounds": 4, "exactBidRate": 0.20, "overbidRate": 0.45, "underbidRate": 0.35, "blindBidRate": 0.0, "averageBidAggression": 0.35 } }
      },
      {
        "label": "noEvidenceObservedLeftNeighbor",
        "opponents": { "leftNeighbor": { "observedRounds": 0 } }
      }
    ]
  },
  "expected": {
    "relationship": "utility(disciplinedObservedLeftNeighbor) < utility(erraticObservedLeftNeighbor)",
    "neutralityGuardrail": "utility(noEvidenceObservedLeftNeighbor) ~= utility(noOpponentsContext)",
    "reason": "Stage-6b penaltyAvoid calibration should only increase caution when opponent evidence is present"
  }
}
```

### Case Draft: PHASE-003

```json
{
  "id": "PHASE-003",
  "stateType": "rankingUtility-compare",
  "inputs": {
    "mode": "chase",
    "targetSignal": "matchCatchUpUtility (late-block score deficit)",
    "sameMoveMetrics": {
      "projectedScore": 10,
      "immediateWinProbability": 0.86,
      "threat": 40
    },
    "matchContextBase": {
      "block": 4,
      "roundIndexInBlock": 7,
      "totalScores": [80, 160, 150, 140]
    },
    "variants": [
      {
        "label": "disciplinedObservedLeftNeighbor",
        "opponents": { "leftNeighbor": { "observedRounds": 4, "exactBidRate": 0.75, "overbidRate": 0.10, "underbidRate": 0.15, "blindBidRate": 0.50, "averageBidAggression": 0.72 } }
      },
      {
        "label": "erraticObservedLeftNeighbor",
        "opponents": { "leftNeighbor": { "observedRounds": 4, "exactBidRate": 0.20, "overbidRate": 0.45, "underbidRate": 0.35, "blindBidRate": 0.0, "averageBidAggression": 0.35 } }
      },
      {
        "label": "noEvidenceObservedLeftNeighbor",
        "opponents": { "leftNeighbor": { "observedRounds": 0 } }
      }
    ]
  },
  "expected": {
    "relationship": "utility(disciplinedObservedLeftNeighbor) > utility(noOpponentsContext) > utility(erraticObservedLeftNeighbor)",
    "neutralityGuardrail": "utility(noEvidenceObservedLeftNeighbor) ~= utility(noOpponentsContext)",
    "reason": "Stage-6b catch-up urgency should be slightly stronger against disciplined/contested opponents late in block"
  }
}
```

### Case Draft: JOKER-016

```json
{
  "id": "JOKER-016",
  "stateType": "rankingUtility-compare",
  "inputs": {
    "shared": {
      "trick": [],
      "trump": "S",
      "cardsInRound": 8,
      "roundIndexInBlock": 7,
      "block": 4
    },
    "subcases": [
      {
        "label": "leadJokerAntiPremiumChase",
        "shouldChaseTrick": true,
        "isBlindRound": false,
        "moves": ["wish", "above(trump)"],
        "premiumContext": {
          "leftNeighborIsPremiumCandidateSoFar": true,
          "isPenaltyTargetRiskSoFar": true,
          "premiumCandidatesThreateningPenaltyCount": 1,
          "opponentPremiumCandidatesSoFarCount": 2
        },
        "expectation": "disciplined observed left neighbor increases anti-premium advantage of above(trump) over wish"
      },
      {
        "label": "leadJokerAntiPremiumDump",
        "shouldChaseTrick": false,
        "moves": ["takes(non-trump)"],
        "premiumContext": {
          "leftNeighborIsPremiumCandidateSoFar": true,
          "isPenaltyTargetRiskSoFar": false,
          "opponentPremiumCandidatesSoFarCount": 1
        },
        "expectation": "disciplined observed left neighbor increases utility of takes(non-trump) controlled-loss lead"
      }
    ],
    "opponentVariants": [
      { "label": "disciplinedObservedLeftNeighbor", "leftNeighbor": { "observedRounds": 4, "exactBidRate": 0.75, "overbidRate": 0.10, "underbidRate": 0.15, "blindBidRate": 0.50, "averageBidAggression": 0.72 } },
      { "label": "erraticObservedLeftNeighbor", "leftNeighbor": { "observedRounds": 4, "exactBidRate": 0.20, "overbidRate": 0.45, "underbidRate": 0.35, "blindBidRate": 0.0, "averageBidAggression": 0.35 } },
      { "label": "noEvidenceObservedLeftNeighbor", "leftNeighbor": { "observedRounds": 0 } }
    ]
  },
  "expected": {
    "relationship": "disciplined > erratic effect magnitude in both subcases",
    "neutralityGuardrail": "noEvidence ~= noOpponentsContext",
    "reason": "Stage-6b joker declaration anti-premium tuning must stay evidence-gated and monotonic"
  }
}
```

## BLIND Scenarios

### BLIND-001 (Leader should avoid unnecessary blind)

- Priority: `High`
- Goal: проверить, что лидер с безопасным отрывом не берёт лишний риск blind в 4-м блоке.

Setup (target):
- `block = fourth`
- `cardsInRound = 8..9`
- текущий игрок лидирует или идёт вторым, но имеет безопасный отрыв от ближайшего соперника
- доступен широкий диапазон blind-ставок

Expected behavior:
- бот выбирает открытую ставку (`nil` для pre-deal blind decision)
- при сравнении с альтернативами blind не выглядит "дефолтным" выбором

### BLIND-002 (Catch-up blind for trailing player)

- Priority: `High`
- Goal: отстающий игрок чаще выбирает blind в догоняющем сценарии.

Setup (target):
- `block = fourth`
- `cardsInRound = 7..9`
- отставание от лидера >= catch-up threshold
- безопасного отрыва от следующего соперника нет

Expected behavior:
- бот выбирает blind-ставку
- размер blind-ставки не минимальный, но не авральный при умеренном отставании

### BLIND-003 (Dealer is more conservative)

- Priority: `Medium`
- Goal: в одинаковом score-сценарии дилер реже идёт в blind, чем недилер.

Setup (target):
- две симметричные конфигурации, отличается только `dealerIndex`

Expected behavior:
- `non-dealer` чаще выбирает blind
- `dealer` чаще выбирает open bid или меньший blind

## PREMIUM Scenarios

### PREMIUM-001 (Avoid assisting premium leader)

- Priority: `High`
- Goal: бот не должен дарить лишнюю взятку игроку, который близок к премии.

Setup (target):
- известный блоковый контекст: один соперник близок к премии
- у бота есть выбор между безопасным сбросом и рисковым ходом, повышающим шанс взятки соперника

Expected behavior:
- бот выбирает линию, уменьшающую вероятность премии соперника

### PREMIUM-002 (Protect own premium line)

- Priority: `High`
- Goal: бот сохраняет ресурс/темп для собственной премии, если это выгодно по блоку.

Setup (target):
- бот претендует на премию в текущем блоке
- есть выбор между краткосрочным round-score gain и сохранением премиального положения

Expected behavior:
- бот не делает "дешёвый" краткосрочный ход, если он ухудшает шансы на премию

## JOKER Scenarios

### JOKER-001 (Blind round: avoid low-value early joker spend)

- Priority: `High`
- Goal: в blind-раунде бот не тратит джокер рано без необходимости.

Setup (target):
- `isBlind = true`
- ранняя взятка (не последняя)
- есть альтернатива без джокера с сопоставимым utility

Expected behavior:
- джокер сохраняется, если нет сильного выигрыша по вероятности/очкам

### JOKER-002 (Contextual choice between wish / above / takes)

- Priority: `High`
- Goal: проверить контекстный выбор объявления джокера.

Setup (target):
- бот ходит первым джокером
- сценарии с разным режимом (`chase`, `dump`, blind/non-blind, trump/no-trump)

Expected behavior:
- `wish` не выбирается автоматически во всех chase-ситуациях
- `takes/above` выбираются при контекстной выгоде

## PHASE Scenarios

### PHASE-001 (Early-phase threat preservation)

- Priority: `Medium`
- Goal: в ранней фазе раздачи бот реже сжигает сильные карты без давления.

Setup (target):
- первая/вторая взятка
- у бота есть выбор между сильной и средней картой с близким immediate outcome

Expected behavior:
- чаще сохраняется более ценная карта (джокер/старший козырь/старший ранг)

### PHASE-002 (Late-phase conversion)

- Priority: `Medium`
- Goal: в поздней фазе бот конвертирует ресурс в точный добор/сброс, а не "держит до конца".

Setup (target):
- последние 1-2 взятки
- известен разрыв до/после заказа (`targetBid - currentTricks`)

Expected behavior:
- поведение отличается от ранней фазы в аналогичной позиции по картам
- при `chase` повышается приоритет гарантированного взятия
- при `dump` повышается приоритет гарантированного проигрыша взятки

## JOKER Regression Pack (v1, Stage 5 Retuning Prep)

Ниже собран текущий пакет `JOKER-*` кейсов для ретюнинга `Этапа 5`.
Текущая версия пакета зафиксирована как `strict-first`: активных automated `probe`-тестов нет; нестабильные runtime-диагностики оставлены в каталоге как draft-only сценарии.

| ID | Layer | Status | Focus |
|----|-------|--------|-------|
| `JOKER-001` | scenario-draft | `draft` | blind: не тратить джокер рано без необходимости |
| `JOKER-002` | scenario-draft | `draft` | общий контекстный выбор `wish/above/takes` |
| `JOKER-003` | ranking utility | `strict` | `above(trump)` vs `above(non-trump)` в `chase` |
| `JOKER-004` | runtime/evaluator/ranking | `strict` (ranking/evaluator) + runtime-diagnostic draft | flip `above -> wish` по срочности добора |
| `JOKER-005` | evaluator/ranking | `strict` | `takes(non-trump)` в `dump`, `above(trump)` в `chase` |
| `JOKER-006` | runtime strategy | `strict` | `takes(non-trump)` в раннем `overbid dump` с опасной trump-рукой |
| `JOKER-007` | ranking utility | `strict` | `remaining control reserve` (low/high) |
| `JOKER-008` | runtime strategy | `strict` | declaration shift по `control reserve` |
| `JOKER-009` | runtime strategy | `diagnostic draft` (strict retired) | weak-hand all-in chase: `above(trump)` -> `wish` |
| `JOKER-010` | ranking utility | `strict` | premium-aware declaration scoring (`own premium` / anti-premium) |
| `JOKER-011` | runtime strategy | `strict` | anti-premium pressure в all-in chase (`wish -> above`) |
| `JOKER-012` | ranking utility | `strict` | preferred post-joker control suit (`above`/`takes`) |
| `JOKER-013` | runtime strategy | `strict` | runtime shift `above(S)` vs `above(H)` по preferred suit |
| `JOKER-014` | runtime strategy | `strict` | early overbid dump + own premium -> `takes(non-trump)` |
| `JOKER-015` | evaluator | `strict` | `above(preferredSuit)` для suit-dominant post-joker hands |

### Stage 5 Retuning Priorities (JOKER Pack)

- `P1`: перепроверить, что `JOKER-006`, `JOKER-008`, `JOKER-011`, `JOKER-013` и `JOKER-014` сохраняются после ретюнинга (guardrails).
- `P1`: поддерживать `JOKER-004` как strict lower-layer invariant (ranking/evaluator); runtime urgency flip пока считать диагностикой, а не blocking strict assert.
- `P2`: оценить, стоит ли добавить ещё один strict runtime-case для reserve-aware логики (`JOKER-008b`) с точным expected high-reserve declaration (не только relation assert).
- `P2`: расширить `JOKER-002` в поднабор точных serialized runtime asserts после retuning.

### Harness Commands (JOKER Pack)

- Список текущего набора (`strict` по умолчанию):
  - `scripts/run_joker_regression_pack.sh --list`
  - `make joker-pack-list`
- Прогон `strict` guardrails:
  - `scripts/run_joker_regression_pack.sh`
  - `make joker-pack`
- Прогон `strict + probe` (retuning session; сейчас `probe_count=0`, флаг зарезервирован):
  - `scripts/run_joker_regression_pack.sh --include-probes`
  - `make joker-pack-all`
- Артефакты сохраняются в `.derivedData/joker-regression-runs/<timestamp>/` (`summary.txt`, `selected-tests.txt`, `xcodebuild.log`, `TestResults.xcresult`).

## Stage 6b Opponent-Aware Ranking Guardrails (Draft Mapping)

Ниже зафиксирован текущий mapping Stage 6b (ranking-level) сценариев к unit-тестам.
Это отдельный guardrail-контур и он пока намеренно не смешивается с `JOKER` pack (Stage 5).

| ID | Area | Layer | Status | Current Automated Mapping |
|----|------|-------|--------|---------------------------|
| `BLIND-004` | blind chase | ranking utility | `strict` | `BotTurnCandidateRankingServiceTests`: `testMoveUtility_whenBlindChasing_andDisciplinedObservedLeftNeighbor_increasesBlindContestUtility`, `...andOpponentModelHasNoEvidence_keepsBlindContestUtilityUnchanged` |
| `PREMIUM-010` | premium deny | ranking utility | `strict` | `BotTurnCandidateRankingServiceTests`: `testMoveUtility_whenLeftNeighborPremiumCandidate_andDisciplinedLeftNeighborObserved_strengthensDenyPressure`, `testMoveUtility_whenOpponentModelHasNoEvidence_keepsDenyPressureUnchanged` |
| `PREMIUM-011` | penalty avoid | ranking utility | `strict` | `BotTurnCandidateRankingServiceTests`: `testMoveUtility_whenPenaltyTargetRisk_andDisciplinedObservedOpponent_strengthensPenaltyAvoidAdjustment`, `testMoveUtility_whenPenaltyTargetRisk_andOpponentModelHasNoEvidence_keepsPenaltyAvoidAdjustmentUnchanged` |
| `PHASE-003` | late-block catch-up | ranking utility | `strict` | `BotTurnCandidateRankingServiceTests`: `testMoveUtility_withLateBlockScoreDeficit_andDisciplinedObservedLeftNeighbor_increasesCatchUpUtility`, `...andOpponentModelHasNoEvidence_keepsCatchUpUtilityUnchanged` |
| `JOKER-016` | lead-joker anti-premium | ranking utility | `strict` | `BotTurnCandidateRankingServiceTests`: chase (`...DisciplinedObservedLeftNeighbor_strengthensAntiPremiumShift`, `...NoEvidence_keepsShiftUnchanged`) + dump (`...DumpingAntiPremiumContext_andDisciplined...`, `...DumpingAntiPremiumContext_andOpponentModelHasNoEvidence...`) |

### Harness Commands (Stage 6b Ranking Guardrails)

- Отдельный Stage 6b pack (ranking-level opponent-aware guardrails):
  - `scripts/run_stage6b_ranking_guardrails.sh --list`
  - `scripts/run_stage6b_ranking_guardrails.sh`
  - `make stage6b-pack-list`
  - `make stage6b-pack`
- Расширенный режим (`ranking + flow-plumbing` для cross-service opponent-model guardrails):
  - `scripts/run_stage6b_ranking_guardrails.sh --include-flow-plumbing`
  - `make stage6b-pack-all`
- Текущий состав `stage6b-pack-all` (cross-service optional subset):
  - `FLOW-OPP-001/002`: `GameScenePlayingFlowTests` (построение `BotOpponentModel` из observed rounds / zero-evidence start)
  - `EVAL-OPP-001`: `BotTurnCandidateEvaluatorServiceTests` (`no-evidence -> neutral` в anti-premium lead-joker all-in chase)
  - `EVAL-OPP-002`: `BotTurnCandidateEvaluatorServiceTests` (`disciplined vs erratic` style-shift в moderate premium-deny dump scenario, last-seat club dump choice)
  - `STRAT-OPP-001`: `BotTurnStrategyServiceTests` (`no-evidence -> neutral` в runtime anti-premium lead-joker all-in chase)
  - `STRAT-OPP-002`: `BotTurnStrategyServiceTests` (runtime `disciplined vs erratic` style-shift в moderate premium-deny dump scenario)
- Артефакты сохраняются в `.derivedData/stage6b-ranking-runs/<timestamp>/` (`summary.txt`, `selected-tests.txt`, `xcodebuild.log`, `TestResults.xcresult`).
- Fallback-команда (если нужен точечный локальный прогон всего класса вместо pack):
  - `xcodebuild -quiet -project Jocker/Jocker.xcodeproj -scheme Jocker -destination 'id=4F592A52-148C-4540-BB72-590B8C44BD43' -derivedDataPath .derivedData CODE_SIGNING_ALLOWED=NO test-without-building -only-testing:JockerTests/BotTurnCandidateRankingServiceTests`
- Для локальных прогонов использовать `iPhone 15 (17.2)` destination, пока `iPhone 15 Pro (17.2)` может зависать после `Testing started` в текущем окружении.

## Next Fill-In Tasks

- Добавить точные сериализованные состояния для первых 8 кейсов.
- Привязать каждый кейс к автоматическому тесту или harness-команде (JOKER pack CLI/Makefile entrypoints добавлены; осталось расширить mapping для draft-кейсов).
- Выделенный `Stage 6b` pack/harness добавлен (`scripts/run_stage6b_ranking_guardrails.sh`, `make stage6b-pack*`); расширенный режим `--include-flow-plumbing` / `make stage6b-pack-all` теперь покрывает cross-service opponent-model guardrails (flow plumbing + evaluator/strategy `no-evidence` neutrality + style-shift guardrails).
- Зафиксировать финальный seed-набор baseline для этапа 0.
