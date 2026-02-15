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
    private enum ActionKey {
        static let firstDealerSelection = "GameScene.firstDealerSelection"
        static let botTurn = "GameScene.botTurn"
    }

    private enum LayoutMetrics {
        static let actionButtonSize = CGSize(width: 300, height: 86)
        static let actionButtonHorizontalInset: CGFloat = 34
        static let actionButtonBottomInset: CGFloat = 24
        static let actionButtonSpacing: CGFloat = 16
        static let gameInfoTopInset: CGFloat = 34
        static let trickCenterYOffset: CGFloat = 20
        static let trumpIndicatorInset: CGFloat = 116
    }

    var playerCount: Int = 4
    var playerNames: [String] = []
    var playerControlTypes: [PlayerControlType] = []
    var onScoreButtonTapped: (() -> Void)?
    var onTricksButtonTapped: ((_ playerNames: [String], _ maxTricks: Int, _ currentBids: [Int], _ dealerIndex: Int) -> Void)?
    var onJokerDecisionRequested: ((_ isLeadCard: Bool, _ completion: @escaping (JokerPlayDecision?) -> Void) -> Void)?
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
    private lazy var trickNode: TrickNode = {
        let node = TrickNode()
        node.zPosition = 50
        return node
    }()
    private lazy var trumpIndicator: TrumpIndicator = {
        let indicator = TrumpIndicator()
        indicator.zPosition = 100
        return indicator
    }()
    private var currentTrump: Suit?
    private lazy var gameState: GameState = {
        return GameState(playerCount: playerCount)
    }()
    private var firstDealerIndex: Int = 0
    private(set) lazy var scoreManager: ScoreManager = ScoreManager(gameState: gameState)
    private let coordinator = GameSceneCoordinator()
    private let botBiddingService = BotBiddingService()
    private let botTrumpSelectionService = BotTrumpSelectionService()
    private let shouldRevealAllPlayersCards = true
    private var isSelectingFirstDealer = false
    private var isAwaitingJokerDecision = false
    private var isAwaitingHumanBidChoice = false
    private var isAwaitingHumanBlindChoice = false
    private var isAwaitingHumanTrumpChoice = false
    private var isRunningBiddingFlow = false
    private var isRunningPreDealBlindFlow = false
    private var isRunningTrumpSelectionFlow = false
    private var pendingBids: [Int] = []
    private var pendingBlindSelections: [Bool] = []
    private var firstDealerAnnouncementNode: SKNode?

    private var isInteractionBlocked: Bool {
        return coordinator.isInteractionLocked ||
            isSelectingFirstDealer ||
            isAwaitingJokerDecision ||
            isAwaitingHumanBidChoice ||
            isAwaitingHumanBlindChoice ||
            isAwaitingHumanTrumpChoice ||
            isRunningTrumpSelectionFlow ||
            isRunningPreDealBlindFlow ||
            isRunningBiddingFlow
    }

    var scoreTableFirstPlayerIndex: Int {
        guard playerCount > 0 else { return 0 }
        return (firstDealerIndex + 1) % playerCount
    }

    var scoreTableCurrentBlockIndex: Int {
        return min(max(gameState.currentBlock.rawValue - 1, 0), max(0, GameConstants.totalBlocks - 1))
    }

    var scoreTableCurrentRoundIndex: Int {
        let dealsInCurrentBlock = GameConstants.deals(
            for: gameState.currentBlock,
            playerCount: playerCount
        )
        guard !dealsInCurrentBlock.isEmpty else { return 0 }
        return min(max(gameState.currentRoundInBlock, 0), dealsInCurrentBlock.count - 1)
    }

    var currentPlayerNames: [String] {
        return gameState.players.map { $0.name }
    }

    override func didMove(to view: SKView) {
        self.backgroundColor = GameColors.sceneBackground

        applyConfiguredPlayerNames()
        applyConfiguredPlayerControlTypes()

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
        beginFirstDealerSelectionFlow()

        // Повторный layout на следующем runloop учитывает финальные safe area insets.
        DispatchQueue.main.async { [weak self] in
            self?.refreshLayout()
        }
    }

    private func applyConfiguredPlayerNames() {
        gameState.setPlayerNames(playerNames)
    }

    private func applyConfiguredPlayerControlTypes() {
        if playerControlTypes.count != playerCount {
            playerControlTypes = (0..<playerCount).map { index in
                index == 0 ? .human : .bot
            }
        }

        if !playerControlTypes.contains(.human), !playerControlTypes.isEmpty {
            playerControlTypes[0] = .human
        }
    }

    private func isHumanPlayer(_ index: Int) -> Bool {
        guard playerControlTypes.indices.contains(index) else { return false }
        return playerControlTypes[index] == .human
    }

    private func isBotPlayer(_ index: Int) -> Bool {
        return !isHumanPlayer(index)
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
        guard !isInteractionBlocked else { return }

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
                // В MVP-режиме ставки остальных игроков назначаются автоматически.
                return
            }

            if let selectedCard = selectedHandCard(at: location),
               handleSelectedCardTap(playerIndex: selectedCard.playerIndex, cardNode: selectedCard.cardNode) {
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
            let playerName = gameState.players.indices.contains(index)
                ? gameState.players[index].name
                : "Игрок \(index + 1)"

            let playerNode = PlayerNode(
                playerNumber: index + 1,
                playerName: playerName,
                avatar: avatars[index % avatars.count],
                position: position,
                seatDirection: direction,
                isLocalPlayer: isHumanPlayer(index),
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
        infoLabel.position = gameInfoLabelPosition(insets: safeInsets())
        infoLabel.zPosition = 100

        self.gameInfoLabel = infoLabel
        self.addChild(infoLabel)
    }

    private func updateGameInfoLabel() {
        guard let label = gameInfoLabel else { return }

        let blockName = GameBlockFormatter.shortTitle(
            for: gameState.currentBlock,
            playerCount: playerCount
        )

        let roundInfo = "Раунд \(gameState.currentRoundInBlock + 1)/\(gameState.totalRoundsInBlock)"
        let cardsInfo = "Карт: \(gameState.currentCardsPerPlayer)"
        let phaseInfo = phaseTitle(for: gameState.phase)

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
        let button = makeActionButton(
            title: "Очки",
            position: scoreButtonPosition(insets: safeInsets())
        ) { [weak self] in
            self?.onScoreButtonTapped?()
        }

        self.scoreButton = button
        self.addChild(button)
    }

    private func setupTricksButton() {
        let button = makeActionButton(
            title: "Взятки",
            position: tricksButtonPosition(insets: safeInsets())
        ) { [weak self] in
            self?.presentTricksOrder()
        }

        self.tricksButton = button
        self.addChild(button)
    }

    private func setupDealButton() {
        let button = makeActionButton(
            title: "Раздать карты",
            position: dealButtonPosition(insets: safeInsets())
        ) { [weak self] in
            self?.dealCards()
        }

        self.dealButton = button
        self.addChild(button)
    }

    // MARK: - Игровые компоненты

    private func setupGameComponents() {
        firstDealerIndex = gameState.currentDealer
        _ = scoreManager

        trickNode.centerPosition = trickCenterPosition()
        if trickNode.parent == nil {
            addChild(trickNode)
        }

        trumpIndicator.position = trumpIndicatorPosition(insets: safeInsets())
        if trumpIndicator.parent == nil {
            addChild(trumpIndicator)
        }
    }

    private func beginFirstDealerSelectionFlow() {
        guard !isSelectingFirstDealer else { return }
        isSelectingFirstDealer = true
        showFirstDealerAnnouncement()

        run(
            .sequence([
                .wait(forDuration: 3.0),
                .run { [weak self] in
                    self?.finishFirstDealerSelectionFlow()
                }
            ]),
            withKey: ActionKey.firstDealerSelection
        )
    }

    private func finishFirstDealerSelectionFlow() {
        let selectedDealerIndex = determineFirstDealerIndex()
        firstDealerIndex = selectedDealerIndex
        gameState.startGame(initialDealerIndex: selectedDealerIndex)

        firstDealerAnnouncementNode?.removeFromParent()
        firstDealerAnnouncementNode = nil
        isSelectingFirstDealer = false

        updateGameInfoLabel()
        updateTurnUI(animated: true)
    }

    private func determineFirstDealerIndex() -> Int {
        guard playerCount > 0 else { return 0 }

        deck.reset()
        deck.shuffle()

        // Начинаем выбор с игрока слева относительно первого места (индекс 0).
        let firstPlayerOnLeft = playerCount > 1 ? 1 : 0
        return deck.selectFirstDealer(
            playerCount: playerCount,
            startingPlayerIndex: firstPlayerOnLeft
        )
    }

    private func showFirstDealerAnnouncement() {
        firstDealerAnnouncementNode?.removeFromParent()

        let container = SKNode()
        container.position = CGPoint(x: size.width / 2, y: size.height / 2)
        container.zPosition = 300

        let background = SKShapeNode(rectOf: CGSize(width: 460, height: 118), cornerRadius: 18)
        background.fillColor = GameColors.panelBackground
        background.strokeColor = GameColors.goldTranslucent
        background.lineWidth = 2
        container.addChild(background)

        let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
        label.text = "На раздающего"
        label.fontSize = 44
        label.fontColor = GameColors.textPrimary
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center
        label.position = .zero
        container.addChild(label)

        addChild(container)
        firstDealerAnnouncementNode = container
    }

    private func refreshLayout() {
        setupPlayers()

        let insets = safeInsets()
        gameInfoLabel?.position = gameInfoLabelPosition(insets: insets)
        scoreButton?.position = scoreButtonPosition(insets: insets)
        dealButton?.position = dealButtonPosition(insets: insets)
        tricksButton?.position = tricksButtonPosition(insets: insets)

        trickNode.centerPosition = trickCenterPosition()
        trumpIndicator.position = trumpIndicatorPosition(insets: insets)
        firstDealerAnnouncementNode?.position = CGPoint(x: self.size.width / 2, y: self.size.height / 2)

        updateTurnUI(animated: false)
    }

    private func safeInsets() -> UIEdgeInsets {
        return view?.safeAreaInsets ?? .zero
    }

    private func actionButtonX(insets: UIEdgeInsets) -> CGFloat {
        return insets.left + LayoutMetrics.actionButtonHorizontalInset + LayoutMetrics.actionButtonSize.width / 2
    }

    private func dealButtonPosition(insets: UIEdgeInsets) -> CGPoint {
        return CGPoint(
            x: actionButtonX(insets: insets),
            y: insets.bottom + LayoutMetrics.actionButtonBottomInset + LayoutMetrics.actionButtonSize.height / 2
        )
    }

    private func tricksButtonPosition(insets: UIEdgeInsets) -> CGPoint {
        let dealPosition = dealButtonPosition(insets: insets)
        return CGPoint(
            x: dealPosition.x,
            y: dealPosition.y + LayoutMetrics.actionButtonSize.height + LayoutMetrics.actionButtonSpacing
        )
    }

    private func scoreButtonPosition(insets: UIEdgeInsets) -> CGPoint {
        return CGPoint(
            x: actionButtonX(insets: insets),
            y: size.height - insets.top - LayoutMetrics.actionButtonBottomInset - LayoutMetrics.actionButtonSize.height / 2
        )
    }

    private func gameInfoLabelPosition(insets: UIEdgeInsets) -> CGPoint {
        return CGPoint(
            x: size.width / 2,
            y: size.height - insets.top - LayoutMetrics.gameInfoTopInset
        )
    }

    private func trickCenterPosition() -> CGPoint {
        return CGPoint(x: size.width / 2, y: size.height / 2 + LayoutMetrics.trickCenterYOffset)
    }

    private func trumpIndicatorPosition(insets: UIEdgeInsets) -> CGPoint {
        return CGPoint(
            x: size.width - insets.right - LayoutMetrics.trumpIndicatorInset,
            y: insets.bottom + LayoutMetrics.trumpIndicatorInset
        )
    }

    private func makeActionButton(
        title: String,
        position: CGPoint,
        onTap: @escaping () -> Void
    ) -> GameButton {
        let button = GameButton(title: title, size: LayoutMetrics.actionButtonSize)
        button.position = position
        button.onTap = onTap
        return button
    }

    private func phaseTitle(for phase: GamePhase) -> String {
        switch phase {
        case .notStarted:
            return "Старт"
        case .bidding:
            return "Ставки"
        case .playing:
            return "Игра"
        case .roundEnd:
            return "Конец"
        case .gameEnd:
            return "Финиш"
        }
    }

    private func findAncestor<T: SKNode>(
        from node: SKNode,
        as _: T.Type,
        maxDepth: Int
    ) -> T? {
        var currentNode: SKNode? = node
        var depth = 0

        while let unwrapped = currentNode, depth < maxDepth {
            if let targetNode = unwrapped as? T {
                return targetNode
            }

            currentNode = unwrapped.parent
            depth += 1
        }

        return nil
    }

    // MARK: - Раздача карт (SKAction-based анимация)

    private func dealCards() {
        guard gameState.phase != .notStarted else { return }

        removeAction(forKey: ActionKey.botTurn)
        isAwaitingHumanBidChoice = false
        isAwaitingHumanBlindChoice = false
        isAwaitingHumanTrumpChoice = false
        isRunningBiddingFlow = false
        isRunningPreDealBlindFlow = false
        isRunningTrumpSelectionFlow = false
        pendingBids.removeAll()
        pendingBlindSelections.removeAll()

        coordinator.cancelPendingTrickResolution(on: self)

        guard coordinator.prepareForDealing(
            gameState: gameState,
            scoreManager: scoreManager,
            playerCount: playerCount
        ) else {
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
        currentTrump = nil

        pendingBids = Array(repeating: 0, count: playerCount)
        pendingBlindSelections = Array(repeating: false, count: playerCount)

        if gameState.currentBlock == .fourth {
            startPreDealBlindFlowIfNeeded { [weak self] in
                self?.runDealFlowForCurrentRound()
            }
            return
        }

        runDealFlowForCurrentRound()
    }

    private func runDealFlowForCurrentRound() {
        let cardsPerPlayer = gameState.currentCardsPerPlayer
        let firstPlayerToDeal = (gameState.currentDealer + 1) % playerCount
        let trumpRule = TrumpSelectionRules.rule(
            for: gameState.currentBlock,
            cardsPerPlayer: cardsPerPlayer,
            dealerIndex: gameState.currentDealer,
            playerCount: playerCount
        )

        switch trumpRule.strategy {
        case .automaticTopDeckCard:
            let dealResult = deck.dealCards(
                playerCount: playerCount,
                cardsPerPlayer: cardsPerPlayer,
                startingPlayerIndex: firstPlayerToDeal
            )

            coordinator.runDealAnimation(
                on: self,
                playerCount: playerCount,
                firstPlayerToDeal: firstPlayerToDeal,
                players: players,
                hands: dealResult.hands,
                trumpCard: dealResult.trump,
                trumpIndicator: trumpIndicator,
                onTrumpResolved: { [weak self] trump in
                    self?.currentTrump = trump
                },
                onHighlightTurn: { [weak self] in
                    self?.updateTurnUI(animated: true)
                    self?.startBiddingFlowIfNeeded()
                }
            )
        case .playerOnDealerLeft:
            runPlayerChosenTrumpDealFlow(
                firstPlayerToDeal: firstPlayerToDeal,
                cardsPerPlayer: cardsPerPlayer,
                chooserPlayerIndex: trumpRule.chooserPlayerIndex,
                cardsToDealBeforeChoicePerPlayer: trumpRule.cardsToDealBeforeChoicePerPlayer
            )
        }

        coordinator.markDidDeal()
    }

    private func startPreDealBlindFlowIfNeeded(onCompleted: @escaping () -> Void) {
        guard gameState.phase == .bidding else {
            onCompleted()
            return
        }
        guard gameState.currentBlock == .fourth else {
            onCompleted()
            return
        }

        isRunningPreDealBlindFlow = true
        processPreDealBlindStep(order: biddingOrder(), step: 0, onCompleted: onCompleted)
    }

    private func processPreDealBlindStep(
        order: [Int],
        step: Int,
        onCompleted: @escaping () -> Void
    ) {
        guard gameState.phase == .bidding else {
            isRunningPreDealBlindFlow = false
            onCompleted()
            return
        }

        guard step < order.count else {
            isRunningPreDealBlindFlow = false
            onCompleted()
            return
        }

        let playerIndex = order[step]
        let allowedBlindBids = gameState.allowedBids(forPlayer: playerIndex, bids: pendingBids)
        let canChooseBlind = gameState.canChooseBlindBid(
            forPlayer: playerIndex,
            blindSelections: pendingBlindSelections
        )

        let applySelection: (_ isBlind: Bool, _ bid: Int?) -> Void = { [weak self] isBlind, bid in
            guard let self else { return }
            guard self.gameState.phase == .bidding else { return }

            if isBlind && canChooseBlind {
                let fallbackBlindBid = allowedBlindBids.first ?? 0
                let resolvedBlindBid: Int
                if let bid, allowedBlindBids.contains(bid) {
                    resolvedBlindBid = bid
                } else {
                    resolvedBlindBid = fallbackBlindBid
                }
                self.pendingBlindSelections[playerIndex] = true
                self.pendingBids[playerIndex] = resolvedBlindBid
                self.players[playerIndex].setBid(resolvedBlindBid, isBlind: true, animated: true)
            } else {
                self.pendingBlindSelections[playerIndex] = false
                self.pendingBids[playerIndex] = 0
            }

            self.updateGameInfoLabel()
            self.updateTurnUI(animated: true)

            self.run(
                .sequence([
                    .wait(forDuration: 0.2),
                    .run { [weak self] in
                        self?.processPreDealBlindStep(
                            order: order,
                            step: step + 1,
                            onCompleted: onCompleted
                        )
                    }
                ])
            )
        }

        if !canChooseBlind {
            applySelection(false, nil)
            return
        }

        if isHumanPlayer(playerIndex) {
            requestHumanPreDealBlindChoice(
                forPlayer: playerIndex,
                allowedBlindBids: allowedBlindBids,
                canChooseBlind: canChooseBlind,
                completion: applySelection
            )
            return
        }

        let blindBid = botBiddingService.makePreDealBlindBid(
            playerIndex: playerIndex,
            dealerIndex: gameState.currentDealer,
            cardsInRound: gameState.currentCardsPerPlayer,
            allowedBlindBids: allowedBlindBids,
            canChooseBlind: canChooseBlind,
            totalScores: scoreManager.totalScoresIncludingCurrentBlock
        )
        applySelection(blindBid != nil, blindBid)
    }

    private func runPlayerChosenTrumpDealFlow(
        firstPlayerToDeal: Int,
        cardsPerPlayer: Int,
        chooserPlayerIndex: Int,
        cardsToDealBeforeChoicePerPlayer: Int
    ) {
        let cardsBeforeChoice = min(cardsPerPlayer, max(0, cardsToDealBeforeChoicePerPlayer))
        let initialDeal = deck.dealCards(
            playerCount: playerCount,
            cardsPerPlayer: cardsBeforeChoice,
            startingPlayerIndex: firstPlayerToDeal
        )

        let remainingCardsPerPlayer = max(0, cardsPerPlayer - cardsBeforeChoice)
        let remainingDeal = deck.dealCards(
            playerCount: playerCount,
            cardsPerPlayer: remainingCardsPerPlayer,
            startingPlayerIndex: firstPlayerToDeal
        )

        isRunningTrumpSelectionFlow = true
        trumpIndicator.setAwaitingTrumpSelection(animated: true)

        coordinator.runDealStageAnimation(
            on: self,
            playerCount: playerCount,
            firstPlayerToDeal: firstPlayerToDeal,
            players: players,
            hands: initialDeal.hands
        ) { [weak self] in
            guard let self else { return }
            let chooserHand = initialDeal.hands.indices.contains(chooserPlayerIndex)
                ? initialDeal.hands[chooserPlayerIndex]
                : []

            self.updateTurnUI(animated: true)
            self.requestTrumpChoice(
                forPlayer: chooserPlayerIndex,
                handCards: chooserHand
            ) { [weak self] selectedTrump in
                guard let self else { return }
                self.currentTrump = selectedTrump
                let animateTrumpReveal = !self.isBotPlayer(chooserPlayerIndex)
                self.trumpIndicator.setTrumpSuit(selectedTrump, animated: animateTrumpReveal)

                if remainingCardsPerPlayer == 0 {
                    self.isRunningTrumpSelectionFlow = false
                    self.updateGameInfoLabel()
                    self.updateTurnUI(animated: true)
                    self.startBiddingFlowIfNeeded()
                    return
                }

                self.coordinator.runDealStageAnimation(
                    on: self,
                    playerCount: self.playerCount,
                    firstPlayerToDeal: firstPlayerToDeal,
                    players: self.players,
                    hands: remainingDeal.hands
                ) { [weak self] in
                    guard let self else { return }
                    self.isRunningTrumpSelectionFlow = false
                    self.updateGameInfoLabel()
                    self.updateTurnUI(animated: true)
                    self.startBiddingFlowIfNeeded()
                }
            }
        }
    }

    private func requestTrumpChoice(
        forPlayer playerIndex: Int,
        handCards: [Card],
        completion: @escaping (Suit?) -> Void
    ) {
        let fallbackTrump = botTrumpSelectionService.selectTrump(from: handCards)

        if isBotPlayer(playerIndex) {
            completion(fallbackTrump)
            return
        }

        let playerName = gameState.players.indices.contains(playerIndex)
            ? gameState.players[playerIndex].name
            : "Игрок \(playerIndex + 1)"

        guard let presenter = topPresentedViewController() else {
            completion(fallbackTrump)
            return
        }

        isAwaitingHumanTrumpChoice = true
        let modal = TrumpSelectionViewController(
            playerName: playerName,
            handCards: handCards
        ) { [weak self] selectedSuit in
            self?.isAwaitingHumanTrumpChoice = false
            completion(selectedSuit)
        }
        modal.modalPresentationStyle = .overFullScreen
        modal.modalTransitionStyle = .crossDissolve
        presenter.present(modal, animated: true)
    }

    private func registerTrickWin(for playerIndex: Int) {
        guard playerIndex >= 0, playerIndex < playerCount else { return }
        trickNode.clearTrick(
            toPosition: players[playerIndex].position,
            animated: true
        ) { [weak self] in
            self?.runBotTurnIfNeeded()
        }
        gameState.completeTrick(winner: playerIndex)
        players[playerIndex].incrementTricks()
        coordinator.completeRoundIfNeeded(
            gameState: gameState,
            scoreManager: scoreManager,
            playerCount: playerCount
        )
        updateGameInfoLabel()
        updateTurnUI(animated: true)
    }

    private func handleSelectedCardTap(playerIndex: Int, cardNode: CardNode) -> Bool {
        guard players.indices.contains(playerIndex) else { return false }
        guard isHumanPlayer(playerIndex) else { return false }

        let player = players[playerIndex]

        guard gameState.phase == .playing else { return false }
        guard playerIndex == gameState.currentPlayer else { return false }

        let selectedCard = cardNode.card
        guard trickNode.canPlayCard(selectedCard, fromHand: player.hand.cards, trump: currentTrump) else {
            return false
        }

        if selectedCard.isJoker {
            requestJokerDecisionAndPlay(
                cardNode: cardNode,
                playerIndex: playerIndex
            )
            return true
        }

        guard let card = player.hand.removeCardNode(cardNode, animated: true) else { return false }
        playCardOnTable(card, by: playerIndex)
        return true
    }

    private func playAutomaticCard(for playerIndex: Int) {
        guard players.indices.contains(playerIndex) else { return }
        guard isBotPlayer(playerIndex) else { return }

        guard !players[playerIndex].hand.cards.isEmpty else {
            assertionFailure("Bot turn requested with empty hand at player index \(playerIndex)")
            updateGameInfoLabel()
            updateTurnUI(animated: true)
            return
        }

        let bid = gameState.players.indices.contains(playerIndex)
            ? gameState.players[playerIndex].currentBid
            : nil
        let tricksTaken = gameState.players.indices.contains(playerIndex)
            ? gameState.players[playerIndex].tricksTaken
            : nil

        guard let turnDecision = coordinator.automaticTurnDecision(
            for: playerIndex,
            players: players,
            trickNode: trickNode,
            trump: currentTrump,
            bid: bid,
            tricksTaken: tricksTaken,
            cardsInRound: gameState.currentCardsPerPlayer
        ) else {
            return
        }

        let card = turnDecision.card
        _ = players[playerIndex].hand.removeCard(card, animated: true)
        playCardOnTable(
            card,
            by: playerIndex,
            jokerPlayStyle: turnDecision.jokerDecision.style,
            jokerLeadDeclaration: turnDecision.jokerDecision.leadDeclaration
        )
    }

    private func playCardOnTable(
        _ card: Card,
        by playerIndex: Int,
        jokerPlayStyle: JokerPlayStyle = .faceUp,
        jokerLeadDeclaration: JokerLeadDeclaration? = nil
    ) {
        let targetPosition = trickTargetPosition(for: playerIndex)
        _ = trickNode.playCard(
            card,
            fromPlayer: playerIndex + 1,
            jokerPlayStyle: jokerPlayStyle,
            jokerLeadDeclaration: jokerLeadDeclaration,
            to: targetPosition,
            animated: true
        )

        gameState.playCard(byPlayer: playerIndex)

        if resolveTrickIfNeeded() {
            return
        }

        updateGameInfoLabel()
        updateTurnUI(animated: true)
        runBotTurnIfNeeded()
    }

    @discardableResult
    private func resolveTrickIfNeeded() -> Bool {
        return coordinator.resolveTrickIfNeeded(
            on: self,
            trickNode: trickNode,
            playerCount: playerCount,
            trump: currentTrump
        ) { [weak self] winnerIndex in
            guard let self = self else { return }
            self.registerTrickWin(for: winnerIndex)
        }
    }

    private func selectedHandCard(at point: CGPoint) -> (playerIndex: Int, cardNode: CardNode)? {
        if let localPlayerIndex = players.firstIndex(where: { $0.isLocalPlayer }),
           players.indices.contains(localPlayerIndex),
           let localCardNode = selectedCard(in: players[localPlayerIndex].hand, at: point) {
            return (localPlayerIndex, localCardNode)
        }

        for node in nodes(at: point) {
            guard let tappedCardNode = cardNode(from: node) else { continue }
            guard let ownerPlayer: PlayerNode = findAncestor(from: tappedCardNode, as: PlayerNode.self, maxDepth: 16),
                  let ownerHand: CardHandNode = findAncestor(from: tappedCardNode, as: CardHandNode.self, maxDepth: 16),
                  ownerPlayer.hand === ownerHand else {
                continue
            }

            return (ownerPlayer.playerNumber - 1, tappedCardNode)
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
        return findAncestor(from: node, as: CardNode.self, maxDepth: 12)
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

    func applyOrderedTricks(_ bids: [Int]) {
        guard bids.count == playerCount else { return }
        guard gameState.phase == .bidding else { return }
        pendingBids = bids
        if pendingBlindSelections.count != playerCount {
            pendingBlindSelections = Array(repeating: false, count: playerCount)
        }
        isRunningBiddingFlow = false
        applyBidsToGameStateAndStartPlaying(bids, blindSelections: pendingBlindSelections)
    }

    private func presentTricksOrder() {
        let playerNames = gameState.players.map { $0.name }
        let currentBids = gameState.players.map { $0.currentBid }
        onTricksButtonTapped?(playerNames, gameState.currentCardsPerPlayer, currentBids, gameState.currentDealer)
    }

    private func startBiddingFlowIfNeeded() {
        guard gameState.phase == .bidding else { return }
        guard !isRunningBiddingFlow else { return }

        isRunningBiddingFlow = true
        if gameState.currentBlock != .fourth {
            pendingBids = Array(repeating: 0, count: playerCount)
            pendingBlindSelections = Array(repeating: false, count: playerCount)
        } else {
            if pendingBids.count != playerCount {
                pendingBids = Array(repeating: 0, count: playerCount)
            }
            if pendingBlindSelections.count != playerCount {
                pendingBlindSelections = Array(repeating: false, count: playerCount)
            }
        }

        let order = biddingOrder().filter { playerIndex in
            gameState.currentBlock != .fourth || !pendingBlindSelections[playerIndex]
        }
        processBiddingStep(order: order, step: 0)
    }

    private func processBiddingStep(order: [Int], step: Int) {
        guard gameState.phase == .bidding else {
            isRunningBiddingFlow = false
            pendingBids.removeAll()
            pendingBlindSelections.removeAll()
            return
        }

        guard step < order.count else {
            let bids = pendingBids
            let blindSelections = pendingBlindSelections
            pendingBids.removeAll()
            pendingBlindSelections.removeAll()
            isRunningBiddingFlow = false
            applyBidsToGameStateAndStartPlaying(bids, blindSelections: blindSelections)
            return
        }

        let playerIndex = order[step]
        let allowedBids = gameState.allowedBids(forPlayer: playerIndex, bids: pendingBids)
        let fallbackBid = allowedBids.first ?? 0
        let forbidden = forbiddenDealerBidIfNeeded(
            for: playerIndex,
            bids: pendingBids
        )

        if isHumanPlayer(playerIndex) {
            requestHumanBid(
                forPlayer: playerIndex,
                handCards: players[playerIndex].hand.cards,
                allowedBids: allowedBids
            ) { [weak self] selectedBid in
                guard let self = self else { return }
                guard self.gameState.phase == .bidding else { return }

                let resolvedBid = allowedBids.contains(selectedBid) ? selectedBid : fallbackBid
                self.pendingBids[playerIndex] = resolvedBid
                self.players[playerIndex].setBid(resolvedBid, isBlind: false, animated: true)
                self.updateGameInfoLabel()
                self.updateTurnUI(animated: true)
                self.processBiddingStep(order: order, step: step + 1)
            }
            return
        }

        let candidateBid = botBiddingService.makeBid(
            hand: players[playerIndex].hand.cards,
            cardsInRound: gameState.currentCardsPerPlayer,
            trump: currentTrump,
            forbiddenBid: forbidden
        )
        let bid = allowedBids.contains(candidateBid) ? candidateBid : fallbackBid
        pendingBids[playerIndex] = bid
        players[playerIndex].setBid(bid, isBlind: false, animated: true)
        updateGameInfoLabel()
        updateTurnUI(animated: true)

        run(
            .sequence([
                .wait(forDuration: 0.25),
                .run { [weak self] in
                    self?.processBiddingStep(order: order, step: step + 1)
                }
            ])
        )
    }

    private func requestHumanBid(
        forPlayer playerIndex: Int,
        handCards: [Card],
        allowedBids: [Int],
        completion: @escaping (Int) -> Void
    ) {
        let normalizedAllowedBids = Array(Set(allowedBids)).sorted()
        guard !normalizedAllowedBids.isEmpty else {
            completion(0)
            return
        }

        let playerName = gameState.players.indices.contains(playerIndex)
            ? gameState.players[playerIndex].name
            : "Игрок \(playerIndex + 1)"

        guard let presenter = topPresentedViewController() else {
            completion(normalizedAllowedBids[0])
            return
        }

        isAwaitingHumanBidChoice = true

        let modal = BidSelectionViewController(
            playerName: playerName,
            handCards: handCards,
            allowedBids: normalizedAllowedBids
        ) { [weak self] selectedBid in
            self?.isAwaitingHumanBidChoice = false
            completion(selectedBid)
        }
        modal.modalPresentationStyle = .overFullScreen
        modal.modalTransitionStyle = .crossDissolve
        presenter.present(modal, animated: true)
    }

    private func requestHumanPreDealBlindChoice(
        forPlayer playerIndex: Int,
        allowedBlindBids: [Int],
        canChooseBlind: Bool,
        completion: @escaping (_ isBlind: Bool, _ bid: Int?) -> Void
    ) {
        let normalizedAllowedBlindBids = Array(Set(allowedBlindBids)).sorted()

        let playerName = gameState.players.indices.contains(playerIndex)
            ? gameState.players[playerIndex].name
            : "Игрок \(playerIndex + 1)"

        guard let presenter = topPresentedViewController() else {
            completion(false, nil)
            return
        }

        isAwaitingHumanBlindChoice = true

        let modal = BidSelectionViewController(
            playerName: playerName,
            allowedBlindBids: normalizedAllowedBlindBids,
            canChooseBlind: canChooseBlind
        ) { [weak self] isBlind, bid in
            self?.isAwaitingHumanBlindChoice = false
            completion(isBlind, bid)
        }
        modal.modalPresentationStyle = .overFullScreen
        modal.modalTransitionStyle = .crossDissolve
        presenter.present(modal, animated: true)
    }

    private func applyBidsToGameStateAndStartPlaying(_ bids: [Int], blindSelections: [Bool]) {
        guard bids.count == playerCount else { return }
        guard gameState.phase == .bidding else { return }

        let maxBid = max(0, gameState.currentCardsPerPlayer)
        var safetyCounter = 0

        while gameState.phase == .bidding && safetyCounter < playerCount {
            let playerIndex = gameState.currentPlayer
            var bid = min(max(bids[playerIndex], 0), maxBid)
            let allowedBids = gameState.allowedBids(forPlayer: playerIndex, bids: bids)
            if !allowedBids.contains(bid) {
                bid = allowedBids.first ?? 0
            }

            let isBlindBid = blindSelections.indices.contains(playerIndex)
                ? blindSelections[playerIndex]
                : false
            players[playerIndex].setBid(bid, isBlind: isBlindBid, animated: true)
            _ = gameState.placeBid(
                bid,
                forPlayer: playerIndex,
                isBlind: isBlindBid,
                lockBeforeDeal: isBlindBid
            )
            safetyCounter += 1
        }

        updateGameInfoLabel()
        updateTurnUI(animated: true)
        runBotTurnIfNeeded()
    }

    private func forbiddenDealerBidIfNeeded(for playerIndex: Int, bids: [Int]) -> Int? {
        guard playerIndex == gameState.currentDealer else { return nil }
        guard playerCount > 1 else { return nil }

        let totalWithoutDealer = bids.enumerated().reduce(0) { partial, pair in
            let (index, bid) = pair
            return partial + ((index == gameState.currentDealer) ? 0 : bid)
        }

        let forbidden = gameState.currentCardsPerPlayer - totalWithoutDealer
        guard forbidden >= 0 && forbidden <= gameState.currentCardsPerPlayer else { return nil }
        return forbidden
    }

    private func biddingOrder() -> [Int] {
        guard playerCount > 0 else { return [] }
        let start = (gameState.currentDealer + 1) % playerCount
        return (0..<playerCount).map { offset in
            (start + offset) % playerCount
        }
    }

    private func runBotTurnIfNeeded() {
        DispatchQueue.main.async { [weak self] in
            self?.scheduleBotTurnIfNeeded()
        }
    }

    private func scheduleBotTurnIfNeeded() {
        guard gameState.phase == .playing else { return }
        guard !isInteractionBlocked else { return }
        guard players.indices.contains(gameState.currentPlayer) else { return }
        guard isBotPlayer(gameState.currentPlayer) else { return }
        guard action(forKey: ActionKey.botTurn) == nil else { return }

        run(
            .sequence([
                .wait(forDuration: 0.35),
                .run { [weak self] in
                    guard let self = self else { return }
                    guard self.gameState.phase == .playing else { return }

                    if self.isInteractionBlocked {
                        self.runBotTurnIfNeeded()
                        return
                    }

                    let playerIndex = self.gameState.currentPlayer
                    guard self.isBotPlayer(playerIndex) else { return }
                    self.playAutomaticCard(for: playerIndex)
                }
            ]),
            withKey: ActionKey.botTurn
        )
    }

    private func requestJokerDecisionAndPlay(cardNode: CardNode, playerIndex: Int) {
        let isLeadCard = trickNode.playedCards.isEmpty
        let fallbackDecision = isLeadCard ? JokerPlayDecision.defaultLead : JokerPlayDecision.defaultNonLead
        isAwaitingJokerDecision = true

        let applyDecision: (JokerPlayDecision?) -> Void = { [weak self, weak cardNode] decision in
            guard let self = self else { return }
            self.isAwaitingJokerDecision = false

            guard self.players.indices.contains(playerIndex),
                  self.gameState.phase == .playing,
                  self.gameState.currentPlayer == playerIndex else {
                self.updateGameInfoLabel()
                self.updateTurnUI(animated: true)
                return
            }

            guard let resolvedDecision = decision else {
                self.updateGameInfoLabel()
                self.updateTurnUI(animated: true)
                return
            }

            guard let cardNode,
                  let card = self.players[playerIndex].hand.removeCardNode(cardNode, animated: true) else {
                self.updateGameInfoLabel()
                self.updateTurnUI(animated: true)
                return
            }

            self.playCardOnTable(
                card,
                by: playerIndex,
                jokerPlayStyle: resolvedDecision.style,
                jokerLeadDeclaration: resolvedDecision.leadDeclaration
            )
        }

        if let onJokerDecisionRequested {
            onJokerDecisionRequested(isLeadCard, applyDecision)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                guard let self else { return }
                guard self.isAwaitingJokerDecision else { return }
                guard !self.isJokerDecisionModalPresented else { return }

                self.presentJokerDecisionFallback(
                    isLeadCard: isLeadCard,
                    fallbackDecision: fallbackDecision,
                    completion: applyDecision
                )
            }
            return
        }

        presentJokerDecisionFallback(
            isLeadCard: isLeadCard,
            fallbackDecision: fallbackDecision,
            completion: applyDecision
        )
    }

    private func presentJokerDecisionFallback(
        isLeadCard: Bool,
        fallbackDecision: JokerPlayDecision,
        completion: @escaping (JokerPlayDecision?) -> Void
    ) {
        guard let presenter = topPresentedViewController() else {
            completion(fallbackDecision)
            return
        }

        let modal = JokerModeSelectionViewController(
            isLeadCard: isLeadCard,
            onSubmit: { decision in
                completion(decision)
            },
            onCancel: {
                completion(nil)
            }
        )
        modal.modalPresentationStyle = .overFullScreen
        modal.modalTransitionStyle = .crossDissolve
        presenter.present(modal, animated: true)
    }

    private func topPresentedViewController() -> UIViewController? {
        guard let view = self.view else { return nil }
        var topController = view.window?.rootViewController

        while let presented = topController?.presentedViewController {
            topController = presented
        }

        return topController
    }

    private var isJokerDecisionModalPresented: Bool {
        return topPresentedViewController() is JokerModeSelectionViewController
    }
}
