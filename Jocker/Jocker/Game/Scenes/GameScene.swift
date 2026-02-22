//
//  GameScene.swift
//  Jocker
//
//  Created by Чаниев Мурад on 25.01.2026.
//

import SpriteKit
import UIKit

class GameScene: SKScene {
    enum ActionKey {
        static let firstDealerSelection = "GameScene.firstDealerSelection"
        static let botTurn = "GameScene.botTurn"
    }

    private enum LayoutMetrics {
        static let roundBidInfoFontScale: CGFloat = 1.1
        static let actionButtonSize = CGSize(width: 300, height: 86)
        static let actionButtonHorizontalInset: CGFloat = 34
        static let actionButtonBottomInset: CGFloat = 24
        static let roundBidInfoWidth: CGFloat = 300
        static let roundBidInfoTopSpacing: CGFloat = 14
        static let roundBidInfoVerticalPadding: CGFloat = 12
        static let roundBidInfoTitleHeight: CGFloat = 24 * roundBidInfoFontScale
        static let roundBidInfoRowHeight: CGFloat = 26 * roundBidInfoFontScale
        static let roundBidInfoRowSpacing: CGFloat = 6
        static let roundBidInfoTitleToRowsSpacing: CGFloat = 10
        static let roundBidInfoTitleFontSize: CGFloat = 21 * roundBidInfoFontScale
        static let roundBidInfoRowFontSize: CGFloat = 20 * roundBidInfoFontScale
        static let gameInfoTopInset: CGFloat = 34
        static let trickCenterYOffset: CGFloat = 20
        static let trumpIndicatorInset: CGFloat = 116
        static let jokerLeadInfoSize = CGSize(width: 264, height: 156)
        static let jokerLeadInfoHorizontalMargin: CGFloat = 18
        static let jokerLeadInfoTopInset: CGFloat = 22
    }

    var playerCount: Int = 4
    var playerNames: [String] = []
    var playerControlTypes: [PlayerControlType] = []
    var onScoreButtonTapped: (() -> Void)?
    var onJokerDecisionRequested: ((_ isLeadCard: Bool, _ completion: @escaping (JokerPlayDecision?) -> Void) -> Void)?
    var gameResultsModalPresenter: (([GameFinalPlayerSummary]) -> Bool)?
    var pokerTable: PokerTableNode?
    var players: [PlayerNode] = []
    var dealButton: GameButton?
    var scoreButton: GameButton?
    var turnIndicator: TurnIndicatorNode?

    // UI элементы для отображения состояния игры
    var gameInfoLabel: SKLabelNode?
    var roundBidInfoPanel: SKShapeNode?
    var roundBidInfoTitleLabel: SKLabelNode?
    var roundBidInfoRowLabels: [SKLabelNode] = []
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
    var botDifficultiesByPlayer: [BotDifficulty] = []
    private(set) lazy var scoreManager: ScoreManager = ScoreManager(gameState: gameState)
    lazy var coordinator: GameSceneCoordinator = {
        return GameSceneCoordinator()
    }()
    private lazy var botTuningsByDifficulty: [BotDifficulty: BotTuning] = {
        var map: [BotDifficulty: BotTuning] = [:]
        for difficulty in BotDifficulty.allCases {
            map[difficulty] = BotTuning(difficulty: difficulty)
        }
        return map
    }()
    private lazy var botBiddingServicesByDifficulty: [BotDifficulty: BotBiddingService] = {
        var map: [BotDifficulty: BotBiddingService] = [:]
        for difficulty in BotDifficulty.allCases {
            map[difficulty] = BotBiddingService(tuning: tuning(for: difficulty))
        }
        return map
    }()
    private lazy var botTrumpSelectionServicesByDifficulty: [BotDifficulty: BotTrumpSelectionService] = {
        var map: [BotDifficulty: BotTrumpSelectionService] = [:]
        for difficulty in BotDifficulty.allCases {
            map[difficulty] = BotTrumpSelectionService(tuning: tuning(for: difficulty))
        }
        return map
    }()
    private lazy var botTurnServicesByDifficulty: [BotDifficulty: GameTurnService] = {
        var map: [BotDifficulty: GameTurnService] = [:]
        for difficulty in BotDifficulty.allCases {
            map[difficulty] = GameTurnService(tuning: tuning(for: difficulty))
        }
        return map
    }()
    let gameStatisticsStore: GameStatisticsStore = UserDefaultsGameStatisticsStore()
    let dealHistoryStore = DealHistoryStore()
    let dealHistoryExportService = DealHistoryExportService()
    let shouldRevealAllPlayersCards = false
    private var interactionBlockers: GameSceneInteractionBlockers = []
    private var interactionState = GameSceneInteractionState()
    var isSelectingFirstDealer: Bool {
        get { interactionBlockers.contains(.selectingFirstDealer) }
        set { setInteractionBlocker(.selectingFirstDealer, isActive: newValue) }
    }
    var isAwaitingJokerDecision: Bool {
        get { interactionBlockers.contains(.awaitingJokerDecision) }
        set { setInteractionBlocker(.awaitingJokerDecision, isActive: newValue) }
    }
    var isAwaitingHumanBidChoice: Bool {
        get { interactionBlockers.contains(.awaitingHumanBidChoice) }
        set { setInteractionBlocker(.awaitingHumanBidChoice, isActive: newValue) }
    }
    var isAwaitingHumanBlindChoice: Bool {
        get { interactionBlockers.contains(.awaitingHumanBlindChoice) }
        set { setInteractionBlocker(.awaitingHumanBlindChoice, isActive: newValue) }
    }
    var isAwaitingHumanTrumpChoice: Bool {
        get { interactionBlockers.contains(.awaitingHumanTrumpChoice) }
        set { setInteractionBlocker(.awaitingHumanTrumpChoice, isActive: newValue) }
    }
    var isRunningBiddingFlow: Bool {
        get { interactionBlockers.contains(.runningBiddingFlow) }
        set { setInteractionBlocker(.runningBiddingFlow, isActive: newValue) }
    }
    var isRunningPreDealBlindFlow: Bool {
        get { interactionBlockers.contains(.runningPreDealBlindFlow) }
        set { setInteractionBlocker(.runningPreDealBlindFlow, isActive: newValue) }
    }
    var isRunningTrumpSelectionFlow: Bool {
        get { interactionBlockers.contains(.runningTrumpSelectionFlow) }
        set { setInteractionBlocker(.runningTrumpSelectionFlow, isActive: newValue) }
    }
    var pendingBids: [Int] = []
    var pendingBlindSelections: [Bool] = []
    var firstDealerAnnouncementNode: SKNode?
    var firstDealerAnnouncementLabel: SKLabelNode?
    var firstDealerSelectionCardsNode: SKNode?
    var hasPresentedGameResultsModal = false
    var lastPresentedBlockResultsCount = 0
    var hasSavedGameStatistics = false
    var exportedBlockIndices: Set<Int> = []
    var hasExportedFinalGameHistory = false
    var hasDealtAtLeastOnce = false
    var isUITestMode: Bool {
        return ProcessInfo.processInfo.arguments.contains("-uiTestMode")
    }

    var isInteractionBlocked: Bool {
        return coordinator.isInteractionLocked || interactionState.isBlockingInteraction
    }

    func setInteractionBlocker(
        _ blocker: GameSceneInteractionBlockers,
        isActive: Bool
    ) {
        if isActive {
            interactionBlockers.insert(blocker)
        } else {
            interactionBlockers.remove(blocker)
        }
        syncInteractionStateFromBlockers()
    }

    func clearInteractionBlockers(_ blockers: GameSceneInteractionBlockers) {
        interactionBlockers.subtract(blockers)
        syncInteractionStateFromBlockers()
    }

    func resetTransientDealFlowState() {
        clearInteractionBlockers(.dealStartResettable)
        pendingBids.removeAll()
        pendingBlindSelections.removeAll()
    }

    func resetAllInteractionFlowState() {
        interactionBlockers = []
        syncInteractionStateFromBlockers()
        pendingBids.removeAll()
        pendingBlindSelections.removeAll()
    }

    func syncInteractionStateFromBlockers() {
        interactionState = GameSceneInteractionState(blockers: interactionBlockers)
        assert(
            !interactionState.hasConflictingFlowBlockers,
            "Conflicting GameScene flow blockers: \(interactionBlockers)"
        )
        assert(
            !interactionState.hasConflictingModalBlockers,
            "Conflicting GameScene modal blockers: \(interactionBlockers)"
        )
    }

    func setPrimaryInteractionFlow(_ flow: GameSceneInteractionState.PrimaryFlow) {
        clearInteractionBlockers(.primaryFlowStates)
        guard let blocker = interactionBlocker(forPrimaryFlow: flow) else { return }
        setInteractionBlocker(blocker, isActive: true)
    }

    func clearPrimaryInteractionFlow(_ flow: GameSceneInteractionState.PrimaryFlow) {
        guard let blocker = interactionBlocker(forPrimaryFlow: flow) else { return }
        setInteractionBlocker(blocker, isActive: false)
    }

    func setPendingInteractionModal(_ modal: GameSceneInteractionState.PendingModal) {
        clearInteractionBlockers(.pendingModalStates)
        guard let blocker = interactionBlocker(forPendingModal: modal) else { return }
        setInteractionBlocker(blocker, isActive: true)
    }

    func clearPendingInteractionModal(_ modal: GameSceneInteractionState.PendingModal) {
        guard let blocker = interactionBlocker(forPendingModal: modal) else { return }
        setInteractionBlocker(blocker, isActive: false)
    }

    private func interactionBlocker(
        forPrimaryFlow flow: GameSceneInteractionState.PrimaryFlow
    ) -> GameSceneInteractionBlockers? {
        switch flow {
        case .idle:
            return nil
        case .selectingFirstDealer:
            return .selectingFirstDealer
        case .bidding:
            return .runningBiddingFlow
        case .preDealBlind:
            return .runningPreDealBlindFlow
        case .trumpSelection:
            return .runningTrumpSelectionFlow
        }
    }

    private func interactionBlocker(
        forPendingModal modal: GameSceneInteractionState.PendingModal
    ) -> GameSceneInteractionBlockers? {
        switch modal {
        case .none:
            return nil
        case .jokerDecision:
            return .awaitingJokerDecision
        case .humanBidChoice:
            return .awaitingHumanBidChoice
        case .humanBlindChoice:
            return .awaitingHumanBlindChoice
        case .humanTrumpChoice:
            return .awaitingHumanTrumpChoice
        }
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

    func dealHistory(forBlockIndex blockIndex: Int, roundIndex: Int) -> DealHistory? {
        return dealHistoryStore.history(blockIndex: blockIndex, roundIndex: roundIndex)
    }

    var canDealCards: Bool {
        guard gameState.phase != .notStarted else { return false }
        guard gameState.phase != .gameEnd else { return false }

        if hasDealtAtLeastOnce {
            return gameState.phase == .roundEnd
        }

        return gameState.phase == .bidding
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
        applyConfiguredBotDifficulties()

        setupPokerTable()
        setupPlayers()
        setupDealButton()
        setupScoreButton()
        setupRoundBidInfoPanel()
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

    private func applyConfiguredBotDifficulties() {
        var resolved = Array(repeating: BotDifficulty.hard, count: playerCount)

        for index in 0..<playerCount {
            if botDifficultiesByPlayer.indices.contains(index) {
                resolved[index] = botDifficultiesByPlayer[index]
            }
        }

        if !resolved.isEmpty {
            resolved[0] = .hard
        }

        botDifficultiesByPlayer = resolved
    }

    func isHumanPlayer(_ index: Int) -> Bool {
        guard playerControlTypes.indices.contains(index) else { return false }
        return playerControlTypes[index] == .human
    }

    func isBotPlayer(_ index: Int) -> Bool {
        return !isHumanPlayer(index)
    }

    func botDifficulty(for playerIndex: Int) -> BotDifficulty {
        guard isBotPlayer(playerIndex) else { return .hard }
        guard botDifficultiesByPlayer.indices.contains(playerIndex) else {
            return botDifficulty
        }
        return botDifficultiesByPlayer[playerIndex]
    }

    func botBiddingService(for playerIndex: Int) -> BotBiddingService {
        let difficulty = botDifficulty(for: playerIndex)
        return botBiddingServicesByDifficulty[difficulty] ?? BotBiddingService(tuning: tuning(for: difficulty))
    }

    func botTrumpSelectionService(for playerIndex: Int) -> BotTrumpSelectionService {
        let difficulty = botDifficulty(for: playerIndex)
        return botTrumpSelectionServicesByDifficulty[difficulty] ??
            BotTrumpSelectionService(tuning: tuning(for: difficulty))
    }

    func botTurnService(for playerIndex: Int) -> GameTurnService {
        let difficulty = botDifficulty(for: playerIndex)
        return botTurnServicesByDifficulty[difficulty] ?? GameTurnService(tuning: tuning(for: difficulty))
    }

    func timing(for playerIndex: Int) -> BotTuning.Timing {
        return tuning(for: botDifficulty(for: playerIndex)).timing
    }

    private func tuning(for difficulty: BotDifficulty) -> BotTuning {
        return botTuningsByDifficulty[difficulty] ?? BotTuning(difficulty: difficulty)
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
        updateDealButtonState()
        updateRoundBidInfo()
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

    private func setupDealButton() {
        let button = makeActionButton(
            title: "Раздать карты",
            position: dealButtonPosition(insets: safeInsets())
        ) { [weak self] in
            self?.dealCards()
        }

        self.dealButton = button
        self.addChild(button)
        updateDealButtonState()
    }

    func updateDealButtonState() {
        dealButton?.isEnabled = canDealCards
    }

    private func setupRoundBidInfoPanel() {
        guard roundBidInfoPanel == nil else { return }

        let panelSize = roundBidInfoSize()
        let panel = SKShapeNode(rectOf: panelSize, cornerRadius: 16)
        panel.fillColor = SKColor(red: 0.03, green: 0.07, blue: 0.13, alpha: 0.96)
        panel.strokeColor = GameColors.gold.withAlphaComponent(0.8)
        panel.lineWidth = 2
        panel.zPosition = 102
        panel.isHidden = true
        panel.position = roundBidInfoPosition(insets: safeInsets())

        let titleLabel = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
        titleLabel.fontSize = LayoutMetrics.roundBidInfoTitleFontSize
        titleLabel.fontColor = GameColors.gold
        titleLabel.horizontalAlignmentMode = .center
        titleLabel.verticalAlignmentMode = .center
        titleLabel.text = "Заказанные взятки"

        let contentTop = panelSize.height / 2 - LayoutMetrics.roundBidInfoVerticalPadding
        titleLabel.position = CGPoint(
            x: 0,
            y: contentTop - LayoutMetrics.roundBidInfoTitleHeight / 2
        )
        panel.addChild(titleLabel)

        let rowsTop = titleLabel.position.y
            - LayoutMetrics.roundBidInfoTitleHeight / 2
            - LayoutMetrics.roundBidInfoTitleToRowsSpacing
            - LayoutMetrics.roundBidInfoRowHeight / 2

        var rowLabels: [SKLabelNode] = []
        for rowIndex in 0..<max(playerCount, 1) {
            let rowLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
            rowLabel.fontSize = LayoutMetrics.roundBidInfoRowFontSize
            rowLabel.fontColor = GameColors.textPrimary
            rowLabel.horizontalAlignmentMode = .center
            rowLabel.verticalAlignmentMode = .center
            rowLabel.position = CGPoint(
                x: 0,
                y: rowsTop - CGFloat(rowIndex) * (LayoutMetrics.roundBidInfoRowHeight + LayoutMetrics.roundBidInfoRowSpacing)
            )
            rowLabel.text = ""
            rowLabel.isHidden = true
            panel.addChild(rowLabel)
            rowLabels.append(rowLabel)
        }

        addChild(panel)
        roundBidInfoPanel = panel
        roundBidInfoTitleLabel = titleLabel
        roundBidInfoRowLabels = rowLabels
    }

    private func updateRoundBidInfo() {
        guard let panel = roundBidInfoPanel else { return }

        let shouldShow = gameState.phase == .bidding || gameState.phase == .playing
        guard shouldShow else {
            panel.isHidden = true
            roundBidInfoRowLabels.forEach {
                $0.text = ""
                $0.isHidden = true
            }
            return
        }

        for rowIndex in roundBidInfoRowLabels.indices {
            guard let text = roundBidInfoText(for: rowIndex) else {
                roundBidInfoRowLabels[rowIndex].text = ""
                roundBidInfoRowLabels[rowIndex].isHidden = true
                continue
            }

            roundBidInfoRowLabels[rowIndex].text = text
            roundBidInfoRowLabels[rowIndex].isHidden = false
        }

        panel.isHidden = false
    }

    func roundBidInfoText(for playerIndex: Int) -> String? {
        guard gameState.players.indices.contains(playerIndex) else { return nil }
        let player = gameState.players[playerIndex]
        let bidText = "\(player.name): \(player.currentBid)"
        return isHumanPlayer(playerIndex) ? "\(bidText) / \(player.tricksTaken)" : bidText
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
        setPrimaryInteractionFlow(.selectingFirstDealer)
        showFirstDealerAnnouncement()

        guard playerCount > 0 else {
            finishFirstDealerSelectionFlow(selectedDealerIndex: 0)
            return
        }

        deck.reset()
        deck.shuffle()

        // Начинаем выбор с игрока слева относительно первого места (индекс 0).
        let firstPlayerOnLeft = playerCount > 1 ? 1 : 0
        let selection = deck.prepareFirstDealerSelection(
            playerCount: playerCount,
            startingPlayerIndex: firstPlayerOnLeft
        )

        runFirstDealerSelectionAnimation(
            tableCard: selection.tableCard,
            dealtCards: selection.dealtCards,
            selectedDealerIndex: selection.dealerIndex
        )
    }

    private func runFirstDealerSelectionAnimation(
        tableCard: Card?,
        dealtCards: [(playerIndex: Int, card: Card)],
        selectedDealerIndex: Int
    ) {
        removeAction(forKey: ActionKey.firstDealerSelection)
        firstDealerSelectionCardsNode?.removeFromParent()

        let container = SKNode()
        container.zPosition = 310
        addChild(container)
        firstDealerSelectionCardsNode = container

        let deckNode = makeFirstDealerDeckNode()
        deckNode.position = firstDealerSelectionDeckPosition()
        container.addChild(deckNode)

        var latestCardByPlayer: [Int: CardNode] = [:]
        var actions: [SKAction] = []

        updateFirstDealerAnnouncement(text: "На раздающего")

        if tableCard != nil {
            actions.append(.wait(forDuration: 0.35))
            actions.append(.run { [weak self, weak container] in
                guard let self, let container else { return }

                let tableCardNode = CardNode(card: .joker, faceUp: false)
                tableCardNode.position = self.firstDealerSelectionDeckPosition()
                tableCardNode.setScale(0.42)
                tableCardNode.zPosition = 5
                container.addChild(tableCardNode)

                let move = SKAction.move(to: self.firstDealerSelectionTableCardPosition(), duration: 0.25)
                let scale = SKAction.scale(to: 0.52, duration: 0.25)
                tableCardNode.run(.group([move, scale]))
            })
            actions.append(.wait(forDuration: 0.2))
        }

        for deal in dealtCards {
            actions.append(.run { [weak self, weak container] in
                guard let self, let container else { return }
                guard self.players.indices.contains(deal.playerIndex) else { return }

                let targetPosition = self.firstDealerSelectionCardPosition(for: deal.playerIndex)
                let dealtCardNode = CardNode(card: deal.card, faceUp: true)
                dealtCardNode.position = self.firstDealerSelectionDeckPosition()
                dealtCardNode.setScale(0.42)
                dealtCardNode.zPosition = 20
                container.addChild(dealtCardNode)

                let move = SKAction.move(to: targetPosition, duration: 0.28)
                let scale = SKAction.scale(to: 0.55, duration: 0.28)
                dealtCardNode.run(.group([move, scale]))

                if let previousCardNode = latestCardByPlayer[deal.playerIndex] {
                    let fadeOut = SKAction.fadeOut(withDuration: 0.12)
                    previousCardNode.run(.sequence([fadeOut, .removeFromParent()]))
                }
                latestCardByPlayer[deal.playerIndex] = dealtCardNode

                guard deal.card.rank == .ace else { return }

                let winnerName = self.playerDisplayName(at: deal.playerIndex)
                self.updateFirstDealerAnnouncement(text: "Раздаёт \(winnerName)")

                let pulse = SKAction.sequence([
                    .scale(to: 0.62, duration: 0.12),
                    .scale(to: 0.55, duration: 0.12)
                ])
                let glowIn = SKAction.fadeAlpha(to: 1.0, duration: 0.08)
                dealtCardNode.alpha = 0.95
                dealtCardNode.run(.group([pulse, glowIn]))
            })
            actions.append(.wait(forDuration: deal.card.rank == .ace ? 0.85 : 0.28))
        }

        if dealtCards.isEmpty {
            actions.append(.wait(forDuration: 0.4))
        }

        actions.append(.run { [weak self] in
            self?.finishFirstDealerSelectionFlow(selectedDealerIndex: selectedDealerIndex)
        })

        run(.sequence(actions), withKey: ActionKey.firstDealerSelection)
    }

    private func finishFirstDealerSelectionFlow(selectedDealerIndex: Int) {
        removeAction(forKey: ActionKey.firstDealerSelection)

        firstDealerIndex = selectedDealerIndex
        resetForNewGameSession()
        gameState.startGame(initialDealerIndex: selectedDealerIndex)

        firstDealerAnnouncementNode?.removeFromParent()
        firstDealerAnnouncementNode = nil
        firstDealerAnnouncementLabel = nil
        firstDealerSelectionCardsNode?.removeFromParent()
        firstDealerSelectionCardsNode = nil
        clearPrimaryInteractionFlow(.selectingFirstDealer)

        updateGameInfoLabel()
        updateTurnUI(animated: true)

        if let firstPlayerName = firstPlayerOnLeftName(fromDealer: selectedDealerIndex) {
            presentFirstPlayerAnnouncementModal(firstPlayerName: firstPlayerName)
        }
    }

    func resetForNewGameSession() {
        removeAllActions()
        removeAction(forKey: ActionKey.firstDealerSelection)
        removeAction(forKey: ActionKey.botTurn)
        coordinator.cancelPendingTrickResolution(on: self)
        coordinator = GameSceneCoordinator()

        deck.reset()
        currentTrump = nil
        trickNode.clearTrick(
            toPosition: trickNode.centerPosition,
            animated: false
        )
        trumpIndicator.resetDisplay(animated: false)
        clearJokerLeadInfo()

        for player in players {
            player.hand.removeAllCards(animated: false)
            player.resetForNewRound()
            player.highlight(false)
            player.setHandDimmed(false, animated: false)
        }

        firstDealerAnnouncementNode?.removeFromParent()
        firstDealerAnnouncementNode = nil
        firstDealerAnnouncementLabel = nil
        firstDealerSelectionCardsNode?.removeFromParent()
        firstDealerSelectionCardsNode = nil

        scoreManager.reset()
        clearInProgressRoundResultsForScoreTable()
        dealHistoryStore.reset()

        hasPresentedGameResultsModal = false
        lastPresentedBlockResultsCount = 0
        hasSavedGameStatistics = false
        exportedBlockIndices.removeAll()
        hasExportedFinalGameHistory = false
        hasDealtAtLeastOnce = false
        resetAllInteractionFlowState()
        updateDealButtonState()
    }

    private func clearInProgressRoundResultsForScoreTable() {
        scoreManager.clearInProgressRoundResults()
    }

    func completeGameAndPresentResultsForUITest() {
        guard isUITestMode else { return }

        resetForNewGameSession()
        gameState.startGame(initialDealerIndex: 0)
        populateCompletedBlocksForUITest()
        gameState.markGameEnded()

        updateGameInfoLabel()
        updateTurnUI(animated: false)
        _ = tryPresentGameResultsIfNeeded()
    }

    private func populateCompletedBlocksForUITest() {
        scoreManager.reset()

        let allBlocks: [GameBlock] = [.first, .second, .third, .fourth]
        for block in allBlocks {
            let deals = GameConstants.deals(for: block, playerCount: playerCount)
            for cardsInRound in deals {
                let roundResults = (0..<playerCount).map { _ in
                    RoundResult(
                        cardsInRound: cardsInRound,
                        bid: 0,
                        tricksTaken: 0,
                        isBlind: false
                    )
                }
                scoreManager.recordRoundResults(roundResults)
            }
            _ = scoreManager.finalizeBlock(blockNumber: block.rawValue)
        }
    }

    private func firstDealerSelectionDeckPosition() -> CGPoint {
        return CGPoint(x: size.width / 2, y: size.height / 2 + 164)
    }

    private func firstDealerSelectionTableCardPosition() -> CGPoint {
        return CGPoint(x: size.width / 2, y: size.height / 2 + 28)
    }

    private func firstDealerSelectionCardPosition(for playerIndex: Int) -> CGPoint {
        guard players.indices.contains(playerIndex) else {
            return CGPoint(x: size.width / 2, y: size.height / 2)
        }

        let player = players[playerIndex]
        return player.convert(player.hand.position, to: self)
    }

    private func playerDisplayName(at index: Int) -> String {
        guard gameState.players.indices.contains(index) else {
            return "Игрок \(index + 1)"
        }
        return gameState.players[index].name
    }

    private func firstPlayerOnLeftName(fromDealer dealerIndex: Int) -> String? {
        guard playerCount > 0 else { return nil }
        let firstPlayerIndex = (dealerIndex + 1) % playerCount
        return playerDisplayName(at: firstPlayerIndex)
    }

    private func makeFirstDealerDeckNode() -> SKNode {
        let node = SKNode()

        let bottomCard = CardNode(card: .joker, faceUp: false)
        bottomCard.position = CGPoint(x: -7, y: 7)
        bottomCard.setScale(0.53)
        bottomCard.alpha = 0.7
        node.addChild(bottomCard)

        let topCard = CardNode(card: .joker, faceUp: false)
        topCard.setScale(0.53)
        node.addChild(topCard)

        return node
    }

    private func updateFirstDealerAnnouncement(text: String) {
        firstDealerAnnouncementLabel?.text = text
    }

    private func showFirstDealerAnnouncement() {
        firstDealerAnnouncementNode?.removeFromParent()
        firstDealerAnnouncementLabel = nil

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
        firstDealerAnnouncementLabel = label
    }

    private func refreshLayout() {
        setupPlayers()

        let insets = safeInsets()
        gameInfoLabel?.position = gameInfoLabelPosition(insets: insets)
        scoreButton?.position = scoreButtonPosition(insets: insets)
        dealButton?.position = dealButtonPosition(insets: insets)
        roundBidInfoPanel?.position = roundBidInfoPosition(insets: insets)

        trickNode.centerPosition = trickCenterPosition()
        trumpIndicator.position = trumpIndicatorPosition(insets: insets)
        jokerLeadInfoPanel?.position = jokerLeadInfoPosition(insets: insets)
        firstDealerAnnouncementNode?.position = CGPoint(x: self.size.width / 2, y: self.size.height / 2)

        updateDealButtonState()
        updateRoundBidInfo()
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

    private func scoreButtonPosition(insets: UIEdgeInsets) -> CGPoint {
        return CGPoint(
            x: actionButtonX(insets: insets),
            y: size.height - insets.top - LayoutMetrics.actionButtonBottomInset - LayoutMetrics.actionButtonSize.height / 2
        )
    }

    private func roundBidInfoPosition(insets: UIEdgeInsets) -> CGPoint {
        let scorePosition = scoreButtonPosition(insets: insets)
        let panelSize = roundBidInfoSize()
        let offset = LayoutMetrics.actionButtonSize.height / 2 +
            LayoutMetrics.roundBidInfoTopSpacing +
            panelSize.height / 2

        return CGPoint(
            x: scorePosition.x,
            y: scorePosition.y - offset
        )
    }

    private func roundBidInfoSize() -> CGSize {
        let rowCount = max(playerCount, 1)
        let rowsHeight = CGFloat(rowCount) * LayoutMetrics.roundBidInfoRowHeight +
            CGFloat(max(0, rowCount - 1)) * LayoutMetrics.roundBidInfoRowSpacing
        let height = LayoutMetrics.roundBidInfoVerticalPadding * 2 +
            LayoutMetrics.roundBidInfoTitleHeight +
            LayoutMetrics.roundBidInfoTitleToRowsSpacing +
            rowsHeight

        return CGSize(width: LayoutMetrics.roundBidInfoWidth, height: height)
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
            x: size.width
                - insets.right
                - LayoutMetrics.jokerLeadInfoHorizontalMargin
                - LayoutMetrics.jokerLeadInfoSize.width / 2,
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
        titleLabel.text = "Заход с джокера"
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

    func buildFinalGamePlayerSummaries() -> [GameFinalPlayerSummary] {
        return GameFinalPlayerSummary.build(
            playerNames: gameState.players.map(\.name),
            playerCount: playerCount,
            completedBlocks: scoreManager.completedBlocks
        )
    }

    @discardableResult
    func tryPresentBlockResultsIfNeeded() -> Bool {
        guard !hasPresentedGameResultsModal else { return false }
        guard gameState.phase == .roundEnd else { return false }

        let completedBlockCount = scoreManager.completedBlocks.count
        guard completedBlockCount > 0 else { return false }
        guard completedBlockCount < GameConstants.totalBlocks else { return false }
        guard completedBlockCount > lastPresentedBlockResultsCount else { return false }
        guard gameState.currentRoundInBlock + 1 >= gameState.totalRoundsInBlock else { return false }

        exportCompletedBlockHistoryIfNeeded(completedBlockCount: completedBlockCount)

        if !presentBlockResultsModal(forCompletedBlockCount: completedBlockCount) {
            return false
        }

        lastPresentedBlockResultsCount = completedBlockCount
        return true
    }

    @discardableResult
    func tryPresentGameResultsIfNeeded() -> Bool {
        guard !hasPresentedGameResultsModal else { return false }
        guard scoreManager.completedBlocks.count >= GameConstants.totalBlocks else { return false }

        let isFinalRoundCompleted =
            gameState.currentBlock == .fourth &&
            gameState.currentRoundInBlock + 1 >= gameState.totalRoundsInBlock
        let shouldPresent =
            gameState.phase == .gameEnd ||
            (gameState.phase == .roundEnd && isFinalRoundCompleted)
        guard shouldPresent else { return false }

        let playerSummaries = buildFinalGamePlayerSummaries()
        guard !playerSummaries.isEmpty else { return false }

        exportFinalGameHistoryIfNeeded()

        hasPresentedGameResultsModal = true
        gameState.markGameEnded()
        updateGameInfoLabel()
        updateTurnUI(animated: true)

        let didPresentModal: Bool
        if let gameResultsModalPresenter {
            didPresentModal = gameResultsModalPresenter(playerSummaries)
        } else {
            didPresentModal = presentGameResultsModal(playerSummaries: playerSummaries)
        }

        if !didPresentModal {
            hasPresentedGameResultsModal = false
            return false
        }

        return true
    }

    private func exportCompletedBlockHistoryIfNeeded(completedBlockCount: Int) {
        let blockIndex = completedBlockCount - 1
        guard blockIndex >= 0 else { return }
        guard !exportedBlockIndices.contains(blockIndex) else { return }

        exportedBlockIndices.insert(blockIndex)
        exportDealHistorySnapshot(reason: .blockCompleted(blockIndex: blockIndex))
    }

    private func exportFinalGameHistoryIfNeeded() {
        guard !hasExportedFinalGameHistory else { return }
        hasExportedFinalGameHistory = true
        exportDealHistorySnapshot(reason: .gameCompleted)
    }

    private func exportDealHistorySnapshot(reason: DealHistoryExportService.ExportReason) {
        let histories = dealHistoryStore.allHistories()
        guard !histories.isEmpty else { return }

        _ = dealHistoryExportService.export(
            histories: histories,
            playerCount: playerCount,
            playerNames: currentPlayerNames,
            playerControlTypes: playerControlTypes,
            reason: reason
        )
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
