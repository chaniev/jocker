import Foundation

/// Frozen v1 payload. Change the decoder/migrator, never rewrite a released fixture.
enum GameSessionSchemaFixtures {
    static let version1 = #"""
{
  "schemaVersion": 1,
  "scoringVersion": 1,
  "matchID": "00000000-0000-0000-0000-000000000001",
  "revision": 1,
  "slot": "threePlayers",
  "controls": [
    "human",
    "bot",
    "bot"
  ],
  "difficulties": [
    "hard",
    "hard",
    "hard"
  ],
  "firstDealer": 0,
  "state": {
    "players": [
      {
        "name": "Игрок 1",
        "bid": 0,
        "tricks": 0,
        "blind": false,
        "locked": false
      },
      {
        "name": "Игрок 2",
        "bid": 0,
        "tricks": 0,
        "blind": false,
        "locked": false
      },
      {
        "name": "Игрок 3",
        "bid": 0,
        "tricks": 0,
        "blind": false,
        "locked": false
      }
    ],
    "block": 1,
    "round": 0,
    "dealer": 0,
    "currentPlayer": 1,
    "phase": "bidding"
  },
  "scores": {
    "completedBlocks": [],
    "currentRounds": [
      [],
      [],
      []
    ]
  },
  "roundService": {
    "hasDealt": false
  },
  "history": {
    "histories": [],
    "pending": []
  },
  "flow": {
    "stage": "readyToDeal",
    "order": [],
    "step": 0,
    "bids": [],
    "blindSelections": [],
    "answered": [],
    "remainingHands": [],
    "chooser": 0
  },
  "hands": [
    [],
    [],
    []
  ],
  "deck": [
    {
      "suit": "diamonds",
      "rank": 6
    },
    {
      "suit": "diamonds",
      "rank": 7
    },
    {
      "suit": "diamonds",
      "rank": 8
    },
    {
      "suit": "diamonds",
      "rank": 9
    },
    {
      "suit": "diamonds",
      "rank": 10
    },
    {
      "suit": "diamonds",
      "rank": 11
    },
    {
      "suit": "diamonds",
      "rank": 12
    },
    {
      "suit": "diamonds",
      "rank": 13
    },
    {
      "suit": "diamonds",
      "rank": 14
    },
    {
      "suit": "hearts",
      "rank": 6
    },
    {
      "suit": "hearts",
      "rank": 7
    },
    {
      "suit": "hearts",
      "rank": 8
    },
    {
      "suit": "hearts",
      "rank": 9
    },
    {
      "suit": "hearts",
      "rank": 10
    },
    {
      "suit": "hearts",
      "rank": 11
    },
    {
      "suit": "hearts",
      "rank": 12
    },
    {
      "suit": "hearts",
      "rank": 13
    },
    {
      "suit": "hearts",
      "rank": 14
    },
    {
      "suit": "spades",
      "rank": 7
    },
    {
      "suit": "spades",
      "rank": 8
    },
    {
      "suit": "spades",
      "rank": 9
    },
    {
      "suit": "spades",
      "rank": 10
    },
    {
      "suit": "spades",
      "rank": 11
    },
    {
      "suit": "spades",
      "rank": 12
    },
    {
      "suit": "spades",
      "rank": 13
    },
    {
      "suit": "spades",
      "rank": 14
    },
    {
      "suit": "clubs",
      "rank": 7
    },
    {
      "suit": "clubs",
      "rank": 8
    },
    {
      "suit": "clubs",
      "rank": 9
    },
    {
      "suit": "clubs",
      "rank": 10
    },
    {
      "suit": "clubs",
      "rank": 11
    },
    {
      "suit": "clubs",
      "rank": 12
    },
    {
      "suit": "clubs",
      "rank": 13
    },
    {
      "suit": "clubs",
      "rank": 14
    },
    {},
    {}
  ],
  "trick": [],
  "lastPresentedBlock": 0
}
"""#.data(using: .utf8)!
}
