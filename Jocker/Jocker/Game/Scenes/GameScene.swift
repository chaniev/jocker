//
//  GameScene.swift
//  Jocker
//
//  Created by Чаниев Мурад on 25.01.2026.
//

import SpriteKit
import GameplayKit
import UIKit

class GameScene: SKScene {
    private struct RoundRecordKey: Equatable {
        let block: Int
        let round: Int
    }
    
    var playerCount: Int = 4
    var onScoreButtonTapped: (() -> Void)?
    var onTricksButtonTapped: ((_ playerNames: [String], _ maxTricks: Int, _ currentBids: [Int], _ dealerIndex: Int) -> Void)?
    private var pokerTable: PokerTableNode?
    private var players: [PlayerNode] = []
    private var dealButton: GameButton?
    private var tricksButton: GameButton?
    private var scoreButton: GameButton?
    private var turnIndicator: TurnIndicatorNode?
    
    // UI элементы для отображения состояния игры
    private var gameInfoLabel: SKLabelNode?
    
    // Игровые компоненты
    private var deck = Deck()
    private var trickNode: TrickNode!
    private var trumpIndicator: TrumpIndicator!
    private var currentTrump: Suit?
    private var gameState: GameState!
    private var firstDealerIndex: Int = 0
    private(set) var scoreManager: ScoreManager?
    private var hasDealtAtLeastOnce = false
    private var isResolvingTrick = false
    private var lastRecordedRoundKey: RoundRecordKey?
    private let shouldRevealAllPlayersCards = true

    var scoreTableFirstPlayerIndex: Int {
        guard playerCount > 0 else { return 0 }
        return (firstDealerIndex + 1) % playerCount
    }
    
    override func didMove(to view: SKView) {
        self.backgroundColor = GameColors.sceneBackground
        
        setupPokerTable()
        setupPlayers()
        setupDealButton()
        setupTricksButton()
        setupScoreButton()
        setupGameInfoLabel()
        setupGameComponents()
        setupTurnIndicator()
        updateGameInfoLabel()
        updateTurnUI(animated: false)
        
        // Повторный layout на следующем runloop учитывает финальные safe area insets.
        DispatchQueue.main.async { [weak self] in
            self?.refreshLayout()
        }
    }
    
    // MARK: - Покерный стол
    
    private func setupPokerTable() {
        let table = PokerTableNode(sceneSize: self.size)
        table.position = CGPoint(x: self.size.width / 2, y: self.size.height / 2)
        
        self.pokerTable = table
        self.addChild(table)
    }
    
    // MARK: - Touch Handling
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isResolvingTrick else { return }

        for touch in touches {
            let location = touch.location(in: self)
            
            if let button = scoreButton, button.containsTouchPoint(location) {
                button.animateTap()
                return
            }
            
            if let button = dealButton, button.containsTouchPoint(location) {
                button.animateTap()
                return
            }

            if let button = tricksButton, button.containsTouchPoint(location) {
                button.animateTap()
                return
            }
            
            if let selectedCard = selectedHandCard(at: location),
               handleSelectedCardTap(playerIndex: selectedCard.playerIndex, cardNode: selectedCard.cardNode) {
                return
            }
            
            if let playerIndex = playerIndex(at: location) {
                guard gameState.phase == .playing else { return }
                
                if playerIndex == gameState.currentPlayer {
                    if players.indices.contains(playerIndex), players[playerIndex].isLocalPlayer {
                        return
                    }
                    
                    playAutomaticCard(for: playerIndex)
                    return
                }

                return
            }
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }
    
    // MARK: - Настройка игроков
    
    private func setupPlayers() {
        players.forEach { $0.removeFromParent() }
        players.removeAll()
        
        let center = CGPoint(x: self.size.width / 2, y: self.size.height / 2)
        
        guard let table = pokerTable else { return }
        
        let insets = view?.safeAreaInsets ?? .zero
        let minX = insets.left + 170
        let maxX = size.width - insets.right - 170
        let minY = insets.bottom + 145
        let maxY = size.height - insets.top - 195
        
        let avatars = ["👨‍💼", "👩‍💼", "🧔", "👨‍🦰", "👩‍🦱"]
        let verticalOffset = min(table.tableHeight / 2 + 20, (maxY - minY) / 2)
        let topY = min(maxY, center.y + verticalOffset)
        let bottomY = max(minY, center.y - verticalOffset)
        
        let positions = wideSideSeatPositions(
            for: playerCount,
            centerX: center.x,
            minX: minX,
            maxX: maxX,
            topY: topY,
            bottomY: bottomY,
            tableWidth: table.tableWidth
        )
        
        for (index, position) in positions.enumerated() {
            let direction = CGVector(dx: 0, dy: position.y >= center.y ? 1 : -1)
            
            let playerNode = PlayerNode(
                playerNumber: index + 1,
                avatar: avatars[index % avatars.count],
                position: position,
                seatDirection: direction,
                isLocalPlayer: index == 0,
                shouldRevealCards: shouldRevealAllPlayersCards,
                totalPlayers: playerCount
            )
            
            players.append(playerNode)
            self.addChild(playerNode)
        }
    }
    
    private func wideSideSeatPositions(
        for count: Int,
        centerX: CGFloat,
        minX: CGFloat,
        maxX: CGFloat,
        topY: CGFloat,
        bottomY: CGFloat,
        tableWidth: CGFloat
    ) -> [CGPoint] {
        guard count > 0 else { return [] }
        
        let halfSpan = max(80, min(tableWidth * 0.24, (maxX - minX) / 2 - 24))
        let clampedCenterX = min(max(centerX, minX), maxX)
        let clampX: (CGFloat) -> CGFloat = { x in
            min(max(x, minX), maxX)
        }
        
        switch count {
        case 3:
            let topXs = symmetricXPositions(count: 2, centerX: clampedCenterX, halfSpan: halfSpan)
            return [
                CGPoint(x: clampedCenterX, y: bottomY),
                CGPoint(x: clampX(topXs[0]), y: topY),
                CGPoint(x: clampX(topXs[1]), y: topY)
            ]
        case 4:
            let sideXs = symmetricXPositions(count: 2, centerX: clampedCenterX, halfSpan: halfSpan)
            return [
                CGPoint(x: clampX(sideXs[0]), y: bottomY),
                CGPoint(x: clampX(sideXs[0]), y: topY),
                CGPoint(x: clampX(sideXs[1]), y: topY),
                CGPoint(x: clampX(sideXs[1]), y: bottomY)
            ]
        default:
            let bottomCount = (count + 1) / 2
            let topCount = count - bottomCount
            let bottomXs = symmetricXPositions(count: bottomCount, centerX: clampedCenterX, halfSpan: halfSpan)
            let topXs = symmetricXPositions(count: topCount, centerX: clampedCenterX, halfSpan: halfSpan)
            
            return bottomXs.map { CGPoint(x: clampX($0), y: bottomY) } + topXs.map { CGPoint(x: clampX($0), y: topY) }
        }
    }
    
    private func symmetricXPositions(count: Int, centerX: CGFloat, halfSpan: CGFloat) -> [CGFloat] {
        guard count > 0 else { return [] }
        guard count > 1 else { return [centerX] }
        
        let step = (halfSpan * 2) / CGFloat(count - 1)
        return (0..<count).map { index in
            centerX - halfSpan + CGFloat(index) * step
        }
    }
    
    // MARK: - Информация об игре
    
    private func setupGameInfoLabel() {
        let infoLabel = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
        infoLabel.text = "Ожидание раздачи"
        infoLabel.fontSize = 24
        infoLabel.fontColor = GameColors.textPrimary
        infoLabel.horizontalAlignmentMode = .center
        infoLabel.verticalAlignmentMode = .center
        let insets = view?.safeAreaInsets ?? .zero
        infoLabel.position = CGPoint(x: self.size.width / 2, y: self.size.height - insets.top - 34)
        infoLabel.zPosition = 100
        
        self.gameInfoLabel = infoLabel
        self.addChild(infoLabel)
    }
    
    private func updateGameInfoLabel() {
        guard let label = gameInfoLabel else { return }
        
        let blockName: String
        switch gameState.currentBlock {
        case .first:
            blockName = "Блок 1 (1-8 карт)"
        case .second:
            blockName = "Блок 2 (9 карт)"
        case .third:
            blockName = "Блок 3 (8-1 карт)"
        case .fourth:
            blockName = "Блок 4 (9 карт)"
        }
        
        let roundInfo = "Раунд \(gameState.currentRoundInBlock + 1)/\(gameState.totalRoundsInBlock)"
        let cardsInfo = "Карт: \(gameState.currentCardsPerPlayer)"
        let phaseInfo: String
        switch gameState.phase {
        case .notStarted:
            phaseInfo = "Старт"
        case .bidding:
            phaseInfo = "Ставки"
        case .playing:
            phaseInfo = "Игра"
        case .roundEnd:
            phaseInfo = "Конец"
        case .gameEnd:
            phaseInfo = "Финиш"
        }
        
        let currentPlayerIndex = min(max(gameState.currentPlayer, 0), max(0, gameState.players.count - 1))
        let currentPlayerName = gameState.players.indices.contains(currentPlayerIndex) ? gameState.players[currentPlayerIndex].name : "Игрок \(currentPlayerIndex + 1)"
        let turnInfo = "Ход: \(currentPlayerName)"
        
        label.text = "\(blockName)  •  \(roundInfo)  •  \(cardsInfo)  •  \(phaseInfo)  •  \(turnInfo)"
    }
    
    private func setupTurnIndicator() {
        let indicator = TurnIndicatorNode()
        indicator.zPosition = 220
        addChild(indicator)
        self.turnIndicator = indicator
    }
    
    private func updateTurnUI(animated: Bool) {
        guard !players.isEmpty else {
            turnIndicator?.hide()
            return
        }
        
        let activeIndex = min(max(gameState.currentPlayer, 0), players.count - 1)
        for (index, player) in players.enumerated() {
            player.highlight(index == activeIndex)
        }
        
        if gameState.phase == .gameEnd || gameState.phase == .notStarted {
            turnIndicator?.hide()
            return
        }
        
        let activePlayer = players[activeIndex]
        turnIndicator?.setTurnOwnerPosition(activePlayer.position, seatDirection: activePlayer.seatDirection, animated: animated)
        
        if let localPlayer = players.first(where: { $0.isLocalPlayer }) {
            let shouldDim = (gameState.phase == .playing) && (localPlayer.playerNumber - 1 != activeIndex)
            localPlayer.setHandDimmed(shouldDim, animated: animated)
        }
    }
    
    // MARK: - Кнопки
    
    private func setupScoreButton() {
        let buttonWidth: CGFloat = 300
        let buttonHeight: CGFloat = 86
        let insets = view?.safeAreaInsets ?? .zero
        
        let buttonX: CGFloat = insets.left + 34 + buttonWidth / 2
        let buttonY: CGFloat = self.size.height - insets.top - 24 - buttonHeight / 2
        
        let button = GameButton(title: "Очки", size: CGSize(width: buttonWidth, height: buttonHeight))
        button.position = CGPoint(x: buttonX, y: buttonY)
        button.onTap = { [weak self] in
            self?.onScoreButtonTapped?()
        }
        
        self.scoreButton = button
        self.addChild(button)
    }
    
    private func setupTricksButton() {
        let buttonWidth: CGFloat = 300
        let buttonHeight: CGFloat = 86
        let insets = view?.safeAreaInsets ?? .zero
        
        let buttonX: CGFloat = insets.left + 34 + buttonWidth / 2
        let dealButtonY: CGFloat = insets.bottom + 24 + buttonHeight / 2
        let buttonY: CGFloat = dealButtonY + buttonHeight + 16
        
        let button = GameButton(title: "Взятки", size: CGSize(width: buttonWidth, height: buttonHeight))
        button.position = CGPoint(x: buttonX, y: buttonY)
        button.onTap = { [weak self] in
            self?.presentTricksOrder()
        }
        
        self.tricksButton = button
        self.addChild(button)
    }
    
    private func setupDealButton() {
        let buttonWidth: CGFloat = 300
        let buttonHeight: CGFloat = 86
        let insets = view?.safeAreaInsets ?? .zero
        
        let buttonX: CGFloat = insets.left + 34 + buttonWidth / 2
        let buttonY: CGFloat = insets.bottom + 24 + buttonHeight / 2
        
        let button = GameButton(title: "Раздать карты", size: CGSize(width: buttonWidth, height: buttonHeight))
        button.position = CGPoint(x: buttonX, y: buttonY)
        button.onTap = { [weak self] in
            self?.dealCards()
        }
        
        self.dealButton = button
        self.addChild(button)
    }
    
    // MARK: - Игровые компоненты
    
    private func setupGameComponents() {
        gameState = GameState(playerCount: playerCount)
        gameState.startGame()
        firstDealerIndex = gameState.currentDealer
        
        scoreManager = ScoreManager(gameState: gameState)
        
        trickNode = TrickNode()
        trickNode.centerPosition = CGPoint(x: self.size.width / 2, y: self.size.height / 2 + 20)
        trickNode.zPosition = 50
        addChild(trickNode)
        
        let insets = view?.safeAreaInsets ?? .zero
        trumpIndicator = TrumpIndicator()
        trumpIndicator.position = CGPoint(
            x: self.size.width - insets.right - 116,
            y: insets.bottom + 116
        )
        trumpIndicator.zPosition = 100
        addChild(trumpIndicator)
    }
    
    private func refreshLayout() {
        setupPlayers()
        
        let insets = view?.safeAreaInsets ?? .zero
        gameInfoLabel?.position = CGPoint(x: self.size.width / 2, y: self.size.height - insets.top - 34)
        scoreButton?.position = CGPoint(x: insets.left + 34 + 150, y: self.size.height - insets.top - 24 - 43)
        dealButton?.position = CGPoint(x: insets.left + 34 + 150, y: insets.bottom + 24 + 43)
        tricksButton?.position = CGPoint(x: insets.left + 34 + 150, y: insets.bottom + 24 + 43 + 86 + 16)
        
        trickNode?.centerPosition = CGPoint(x: self.size.width / 2, y: self.size.height / 2 + 20)
        trumpIndicator?.position = CGPoint(
            x: self.size.width - insets.right - 116,
            y: insets.bottom + 116
        )
        
        updateTurnUI(animated: false)
    }
    
    // MARK: - Раздача карт (SKAction-based анимация)
    
    private func dealCards() {
        removeAction(forKey: "resolveTrick")
        isResolvingTrick = false

        guard prepareRoundForDealingIfNeeded() else {
            updateGameInfoLabel()
            updateTurnUI(animated: true)
            return
        }
        
        updateGameInfoLabel()
        updateTurnUI(animated: false)
        
        // Сбрасываем колоду и перемешиваем
        deck.reset()
        deck.shuffle()
        
        // Очищаем руки игроков и взятку
        for player in players {
            player.hand.removeAllCards(animated: true)
            player.resetForNewRound()
        }
        trickNode.clearTrick(
            toPosition: trickNode.centerPosition,
            animated: false
        )
        
        let cardsPerPlayer = gameState.currentCardsPerPlayer
        let firstPlayerToDeal = (gameState.currentDealer + 1) % playerCount
        let dealResult = deck.dealCards(
            playerCount: playerCount,
            cardsPerPlayer: cardsPerPlayer,
            startingPlayerIndex: firstPlayerToDeal
        )
        
        // Строим цепочку анимаций через SKAction
        var actions: [SKAction] = []
        
        // 1. Раздаём карты каждому игроку с задержкой
        for offset in 0..<playerCount {
            let playerIndex = (firstPlayerToDeal + offset) % playerCount
            let player = players[playerIndex]
            let cards = dealResult.hands[playerIndex]
            let delay = SKAction.wait(forDuration: Double(offset) * 0.3)
            let deal = SKAction.run { [weak player] in
                player?.hand.addCards(cards, animated: true)
            }
            actions.append(SKAction.sequence([delay, deal]))
        }
        
        // 2. Сортируем карты через 1 секунду после последней раздачи
        let sortDelay = SKAction.wait(forDuration: Double(playerCount) * 0.3 + 1.0)
        let sortAction = SKAction.run { [weak self] in
            self?.players.forEach { $0.hand.sortCardsStandard(animated: true) }
        }
        actions.append(SKAction.sequence([sortDelay, sortAction]))
        
        // 3. Показываем козырь
        let trumpDelay = SKAction.wait(forDuration: Double(playerCount) * 0.3 + 0.5)
        let trumpAction = SKAction.run { [weak self] in
            guard let self = self else { return }
            if let trumpCard = dealResult.trump {
                self.trumpIndicator.setTrumpCard(trumpCard, animated: true)
                if case .regular(let suit, _) = trumpCard {
                    self.currentTrump = suit
                } else {
                    self.currentTrump = nil
                }
            } else {
                self.trumpIndicator.setTrumpCard(nil, animated: true)
                self.currentTrump = nil
            }
        }
        actions.append(SKAction.sequence([trumpDelay, trumpAction]))
        
        // 4. Выделяем текущего игрока
        let highlightDelay = SKAction.wait(forDuration: Double(playerCount) * 0.3 + 2.2)
        let highlightAction = SKAction.run { [weak self] in
            self?.updateTurnUI(animated: true)
        }
        actions.append(SKAction.sequence([highlightDelay, highlightAction]))
        
        // Запускаем все действия параллельно (каждое со своей задержкой)
        run(SKAction.group(actions), withKey: "dealSequence")
        
        hasDealtAtLeastOnce = true
    }
    
    // MARK: - Логика раунда
    
    private func recordCurrentRoundIfNeeded() {
        guard hasDealtAtLeastOnce, let scoreManager = scoreManager else { return }
        guard gameState.phase == .roundEnd || gameState.phase == .gameEnd else { return }

        let roundKey = RoundRecordKey(
            block: gameState.currentBlock.rawValue,
            round: gameState.currentRoundInBlock
        )
        guard lastRecordedRoundKey != roundKey else { return }
        
        let cardsInRound = gameState.currentCardsPerPlayer
        var results: [RoundResult] = []
        results.reserveCapacity(playerCount)
        
        for playerIndex in 0..<playerCount {
            let player = gameState.players[playerIndex]
            let result = RoundResult(
                cardsInRound: cardsInRound,
                bid: player.currentBid,
                tricksTaken: player.tricksTaken,
                isBlind: false
            )
            results.append(result)
        }
        
        scoreManager.recordRoundResults(results)
        
        if gameState.currentRoundInBlock + 1 >= gameState.totalRoundsInBlock {
            _ = scoreManager.finalizeBlock(blockNumber: gameState.currentBlock.rawValue)
        }

        lastRecordedRoundKey = roundKey
    }

    private func prepareRoundForDealingIfNeeded() -> Bool {
        guard gameState.phase != .gameEnd else { return false }
        guard hasDealtAtLeastOnce else { return true }

        recordCurrentRoundIfNeeded()

        let currentRoundKey = RoundRecordKey(
            block: gameState.currentBlock.rawValue,
            round: gameState.currentRoundInBlock
        )
        let isFinalRoundOfFinalBlock =
            currentRoundKey.block >= GameConstants.totalBlocks &&
            gameState.currentRoundInBlock + 1 >= gameState.totalRoundsInBlock

        if isFinalRoundOfFinalBlock, lastRecordedRoundKey == currentRoundKey {
            gameState.markGameEnded()
            return false
        }

        gameState.startNewRound()
        return true
    }
    
    private func registerTrickWin(for playerIndex: Int) {
        guard playerIndex >= 0, playerIndex < playerCount else { return }
        trickNode.clearTrick(
            toPosition: players[playerIndex].position,
            animated: true
        )
        gameState.completeTrick(winner: playerIndex)
        players[playerIndex].incrementTricks()
        completeRoundIfNeeded()
        updateGameInfoLabel()
        updateTurnUI(animated: true)
    }
    
    private func completeRoundIfNeeded() {
        let totalTricks = gameState.players.reduce(0) { $0 + $1.tricksTaken }
        guard totalTricks >= gameState.currentCardsPerPlayer else { return }
        
        gameState.completeRound()
        recordCurrentRoundIfNeeded()
    }
    
    private func handleSelectedCardTap(playerIndex: Int, cardNode: CardNode) -> Bool {
        guard players.indices.contains(playerIndex) else { return false }
        
        let player = players[playerIndex]
        
        // По пользовательскому сценарию ручной выбор карты доступен только у локального игрока.
        guard player.isLocalPlayer else { return false }

        if gameState.phase == .bidding {
            gameState.beginPlayingAfterBids()
        }

        guard gameState.phase == .playing else { return false }
        guard playerIndex == gameState.currentPlayer else { return false }

        let selectedCard = cardNode.card
        guard trickNode.canPlayCard(selectedCard, fromHand: player.hand.cards, trump: currentTrump) else {
            return false
        }

        guard let card = player.hand.removeCardNode(cardNode, animated: true) else { return false }
        playCardOnTable(card, by: playerIndex)
        return true
    }
    
    private func playAutomaticCard(for playerIndex: Int) {
        guard players.indices.contains(playerIndex) else { return }
        let handCards = players[playerIndex].hand.cards
        guard !handCards.isEmpty else {
            gameState.playCard(byPlayer: playerIndex)
            updateGameInfoLabel()
            updateTurnUI(animated: true)
            return
        }

        let card = handCards.first(where: { candidate in
            trickNode.canPlayCard(candidate, fromHand: handCards, trump: currentTrump)
        }) ?? handCards[0]

        _ = players[playerIndex].hand.removeCard(card, animated: true)
        playCardOnTable(card, by: playerIndex)
    }
    
    private func playCardOnTable(_ card: Card, by playerIndex: Int) {
        let targetPosition = trickTargetPosition(for: playerIndex)
        _ = trickNode.playCard(
            card,
            fromPlayer: playerIndex + 1,
            to: targetPosition,
            animated: true
        )
        
        gameState.playCard(byPlayer: playerIndex)

        if resolveTrickIfNeeded() {
            return
        }

        updateGameInfoLabel()
        updateTurnUI(animated: true)
    }

    @discardableResult
    private func resolveTrickIfNeeded() -> Bool {
        guard !isResolvingTrick else { return true }
        guard trickNode.playedCards.count == playerCount else { return false }

        let trickCards = trickNode.playedCards.map { entry in
            (playerIndex: entry.player - 1, card: entry.card)
        }

        guard let winnerIndex = TrickTakingResolver.winnerPlayerIndex(
            playedCards: trickCards,
            trump: currentTrump
        ) else {
            return false
        }

        isResolvingTrick = true

        let wait = SKAction.wait(forDuration: 0.55)
        let resolve = SKAction.run { [weak self] in
            guard let self = self else { return }
            self.registerTrickWin(for: winnerIndex)
            self.isResolvingTrick = false
        }

        run(SKAction.sequence([wait, resolve]), withKey: "resolveTrick")
        return true
    }
    
    private func selectedHandCard(at point: CGPoint) -> (playerIndex: Int, cardNode: CardNode)? {
        if let localPlayerIndex = players.firstIndex(where: { $0.isLocalPlayer }),
           players.indices.contains(localPlayerIndex),
           let localCardNode = selectedCard(in: players[localPlayerIndex].hand, at: point) {
            return (localPlayerIndex, localCardNode)
        }

        for node in nodes(at: point) {
            guard let tappedCardNode = cardNode(from: node) else { continue }
            
            var currentNode: SKNode? = tappedCardNode
            var ownerHand: CardHandNode?
            var ownerPlayer: PlayerNode?
            var guardSteps = 0
            
            while let unwrapped = currentNode, guardSteps < 16 {
                if ownerHand == nil, let handNode = unwrapped as? CardHandNode {
                    ownerHand = handNode
                }
                
                if let playerNode = unwrapped as? PlayerNode {
                    ownerPlayer = playerNode
                    break
                }
                
                currentNode = unwrapped.parent
                guardSteps += 1
            }
            
            guard let playerNode = ownerPlayer,
                  let handNode = ownerHand,
                  playerNode.hand === handNode else {
                continue
            }
            
            return (playerNode.playerNumber - 1, tappedCardNode)
        }
        
        return nil
    }

    private func selectedCard(in hand: CardHandNode, at point: CGPoint) -> CardNode? {
        let tapPadding: CGFloat = 12
        let cardBounds = CGRect(
            x: -CardNode.cardWidth / 2 - tapPadding,
            y: -CardNode.cardHeight / 2 - tapPadding,
            width: CardNode.cardWidth + tapPadding * 2,
            height: CardNode.cardHeight + tapPadding * 2
        )

        let cardsSortedByTop = hand.cardNodes.sorted { lhs, rhs in
            if lhs.zPosition == rhs.zPosition {
                return lhs.position.x > rhs.position.x
            }
            return lhs.zPosition > rhs.zPosition
        }

        for cardNode in cardsSortedByTop {
            let pointInCard = convert(point, to: cardNode)
            if cardBounds.contains(pointInCard) {
                return cardNode
            }
        }

        return nil
    }
    
    private func cardNode(from node: SKNode) -> CardNode? {
        var currentNode: SKNode? = node
        var guardSteps = 0
        
        while let unwrapped = currentNode, guardSteps < 12 {
            if let cardNode = unwrapped as? CardNode {
                return cardNode
            }
            
            currentNode = unwrapped.parent
            guardSteps += 1
        }
        
        return nil
    }
    
    private func trickTargetPosition(for playerIndex: Int) -> CGPoint {
        let center = trickNode.centerPosition
        guard players.indices.contains(playerIndex) else { return center }
        
        let playerPosition = players[playerIndex].position
        let dx = playerPosition.x - center.x
        let dy = playerPosition.y - center.y
        let length = max(1.0, sqrt(dx * dx + dy * dy))
        
        // Лёгкое смещение к стороне игрока, чтобы карта ложилась в центральный слот "по месту хода".
        let normalizedX = dx / length
        let normalizedY = dy / length
        let horizontalRadius: CGFloat = 118
        let verticalRadius: CGFloat = 70
        
        return CGPoint(
            x: center.x + normalizedX * horizontalRadius,
            y: center.y + normalizedY * verticalRadius
        )
    }
    
    private func playerIndex(at point: CGPoint) -> Int? {
        for node in nodes(at: point) {
            var currentNode: SKNode? = node
            var guardSteps = 0
            
            while let unwrapped = currentNode, guardSteps < 12 {
                if let playerNode = unwrapped as? PlayerNode {
                    return playerNode.playerNumber - 1
                }
                
                currentNode = unwrapped.parent
                guardSteps += 1
            }
        }
        
        return nil
    }
    
    func applyOrderedTricks(_ bids: [Int]) {
        guard bids.count == playerCount else { return }
        let maxBid = max(0, gameState.currentCardsPerPlayer)
        
        for (index, rawBid) in bids.enumerated() {
            let bid = min(max(rawBid, 0), maxBid)
            gameState.setBid(bid, forPlayerAt: index)
            players[index].setBid(bid, animated: true)
        }
        
        gameState.beginPlayingAfterBids()
        updateGameInfoLabel()
        updateTurnUI(animated: true)
    }
    
    private func presentTricksOrder() {
        let playerNames = gameState.players.map { $0.name }
        let currentBids = gameState.players.map { $0.currentBid }
        onTricksButtonTapped?(playerNames, gameState.currentCardsPerPlayer, currentBids, gameState.currentDealer)
    }
}
