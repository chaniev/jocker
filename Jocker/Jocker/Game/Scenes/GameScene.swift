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
    enum ActionKey {
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
        static let jokerLeadInfoSize = CGSize(width: 264, height: 156)
        static let jokerLeadInfoRightInset: CGFloat = 120
        static let jokerLeadInfoTopInset: CGFloat = 22
    }

    var playerCount: Int = 4
    var playerNames: [String] = []
    var playerControlTypes: [PlayerControlType] = []
    var onScoreButtonTapped: (() -> Void)?
    var onTricksButtonTapped: ((_ playerNames: [String], _ maxTricks: Int, _ currentBids: [Int], _ dealerIndex: Int) -> Void)?
    var onJokerDecisionRequested: ((_ isLeadCard: Bool, _ completion: @escaping (JokerPlayDecision?) -> Void) -> Void)?
    var pokerTable: PokerTableNode?
    var players: [PlayerNode] = []
    var dealButton: GameButton?
    var tricksButton: GameButton?
    var scoreButton: GameButton?
    var turnIndicator: TurnIndicatorNode?

    // UI элементы для отображения состояния игры
    var gameInfoLabel: SKLabelNode?
    var jokerLeadInfoPanel: SKShapeNode?
    var jokerLeadInfoPlayerLabel: SKLabelNode?
    var jokerLeadInfoModeLabel: SKLabelNode?

    // Игровые компоненты
    var deck = Deck()
    lazy var trickNode: TrickNode = {
        let node = TrickNode()
        node.zPosition = 50
        return node
    }()
    lazy var trumpIndicator: TrumpIndicator = {
        let indicator = TrumpIndicator()
        indicator.zPosition = 100
        return indicator
    }()
    var currentTrump: Suit?
    lazy var gameState: GameState = {
        return GameState(playerCount: playerCount)
    }()
    var firstDealerIndex: Int = 0
    var botDifficulty: BotDifficulty = .hard
    lazy var botTuning: BotTuning = {
        return BotTuning(difficulty: botDifficulty)
    }()
    private(set) lazy var scoreManager: ScoreManager = ScoreManager(gameState: gameState)
    lazy var coordinator: GameSceneCoordinator = {
        return GameSceneCoordinator(tuning: botTuning)
    }()
    lazy var botBiddingService: BotBiddingService = {
        return BotBiddingService(tuning: botTuning)
    }()
    lazy var botTrumpSelectionService: BotTrumpSelectionService = {
        return BotTrumpSelectionService(tuning: botTuning)
    }()
    let shouldRevealAllPlayersCards = false
    var isSelectingFirstDealer = false
    var isAwaitingJokerDecision = false
    var isAwaitingHumanBidChoice = false
    var isAwaitingHumanBlindChoice = false
    var isAwaitingHumanTrumpChoice = false
    var isRunningBiddingFlow = false
    var isRunningPreDealBlindFlow = false
    var isRunningTrumpSelectionFlow = false
    var pendingBids: [Int] = []
    var pendingBlindSelections: [Bool] = []
    var firstDealerAnnouncementNode: SKNode?

    var isInteractionBlocked: Bool {
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

    /// Обновляет снимок текущего раунда для таблицы очков.
    func syncInProgressRoundResultsForScoreTable() {
        guard gameState.phase == .playing else { return }
        guard gameState.players.count >= playerCount else { return }

        let cardsInRound = gameState.currentCardsPerPlayer
        let results = (0..<playerCount).map { index in
            let player = gameState.players[index]
            return RoundResult(
                cardsInRound: cardsInRound,
                bid: player.currentBid,
                tricksTaken: player.tricksTaken,
                isBlind: player.isBlindBid
            )
        }

        let blockIndex = max(0, gameState.currentBlock.rawValue - 1)
        scoreManager.setInProgressRoundResults(
            results,
            blockIndex: blockIndex,
            roundIndex: gameState.currentRoundInBlock
        )
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

    func isHumanPlayer(_ index: Int) -> Bool {
        guard playerControlTypes.indices.contains(index) else { return false }
        return playerControlTypes[index] == .human
    }

    func isBotPlayer(_ index: Int) -> Bool {
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

    func updateGameInfoLabel() {
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

    func updateTurnUI(animated: Bool) {
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

        setupJokerLeadInfoPanel()
        jokerLeadInfoPanel?.position = jokerLeadInfoPosition(insets: safeInsets())
        clearJokerLeadInfo()
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
        jokerLeadInfoPanel?.position = jokerLeadInfoPosition(insets: insets)
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

    private func jokerLeadInfoPosition(insets: UIEdgeInsets) -> CGPoint {
        let centerY = size.height
            - insets.top
            - LayoutMetrics.jokerLeadInfoTopInset
            - LayoutMetrics.jokerLeadInfoSize.height / 2

        return CGPoint(
            x: size.width - insets.right - LayoutMetrics.jokerLeadInfoRightInset,
            y: centerY
        )
    }

    private func setupJokerLeadInfoPanel() {
        guard jokerLeadInfoPanel == nil else { return }

        let panel = SKShapeNode(rectOf: LayoutMetrics.jokerLeadInfoSize, cornerRadius: 16)
        panel.fillColor = SKColor(red: 0.04, green: 0.08, blue: 0.15, alpha: 0.96)
        panel.strokeColor = GameColors.gold.withAlphaComponent(0.95)
        panel.lineWidth = 3
        panel.zPosition = 115
        panel.isHidden = true

        let panelShadow = SKShapeNode(rectOf: LayoutMetrics.jokerLeadInfoSize, cornerRadius: 16)
        panelShadow.fillColor = .black
        panelShadow.strokeColor = .clear
        panelShadow.alpha = 0.36
        panelShadow.position = CGPoint(x: 0, y: -4)
        panelShadow.zPosition = -1
        panel.addChild(panelShadow)

        let titleLabel = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
        titleLabel.text = "Заход бота с джокера"
        titleLabel.fontSize = 18
        titleLabel.fontColor = GameColors.textPrimary
        titleLabel.horizontalAlignmentMode = .center
        titleLabel.verticalAlignmentMode = .center
        titleLabel.position = CGPoint(x: 0, y: 44)
        panel.addChild(titleLabel)

        let playerLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        playerLabel.fontSize = 31
        playerLabel.fontColor = GameColors.textPrimary
        playerLabel.horizontalAlignmentMode = .center
        playerLabel.verticalAlignmentMode = .center
        playerLabel.position = CGPoint(x: 0, y: 12)
        playerLabel.text = ""
        panel.addChild(playerLabel)

        let separator = SKShapeNode(rectOf: CGSize(width: LayoutMetrics.jokerLeadInfoSize.width - 26, height: 1))
        separator.fillColor = .clear
        separator.strokeColor = GameColors.gold.withAlphaComponent(0.52)
        separator.lineWidth = 1
        separator.position = CGPoint(x: 0, y: -8)
        panel.addChild(separator)

        let modeLabel = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
        modeLabel.fontSize = 22
        modeLabel.fontColor = GameColors.gold.withAlphaComponent(0.98)
        modeLabel.horizontalAlignmentMode = .center
        modeLabel.verticalAlignmentMode = .center
        modeLabel.position = CGPoint(x: 0, y: -38)
        modeLabel.text = ""
        panel.addChild(modeLabel)

        addChild(panel)
        jokerLeadInfoPanel = panel
        jokerLeadInfoPlayerLabel = playerLabel
        jokerLeadInfoModeLabel = modeLabel
    }

    func showBotJokerLeadInfo(for playerIndex: Int, declaration: JokerLeadDeclaration?) {
        guard isBotPlayer(playerIndex) else {
            clearJokerLeadInfo()
            return
        }

        guard let panel = jokerLeadInfoPanel else { return }

        let defaultName = "Игрок \(playerIndex + 1)"
        let playerName = gameState.players.indices.contains(playerIndex)
            ? gameState.players[playerIndex].name
            : defaultName

        jokerLeadInfoPlayerLabel?.text = playerName
        jokerLeadInfoModeLabel?.text = jokerLeadInfoText(for: declaration)
        panel.isHidden = false
    }

    func clearJokerLeadInfo() {
        jokerLeadInfoPanel?.isHidden = true
        jokerLeadInfoPlayerLabel?.text = ""
        jokerLeadInfoModeLabel?.text = ""
    }

    private func jokerLeadInfoText(for declaration: JokerLeadDeclaration?) -> String {
        switch declaration {
        case .wish, .none:
            return "Просто хочет взятку"
        case .above(let suit):
            return "Выше: \(suit.name) \(suit.rawValue)"
        case .takes(let suit):
            return "Забирает: \(suit.name) \(suit.rawValue)"
        }
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

    func findAncestor<T: SKNode>(
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

}
