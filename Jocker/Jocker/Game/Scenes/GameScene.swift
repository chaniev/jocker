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
    
    var playerCount: Int = 4
    var onScoreButtonTapped: (() -> Void)?
    private var pokerTable: PokerTableNode?
    private var players: [PlayerNode] = []
    private var dealButton: GameButton?
    private var scoreButton: GameButton?
    
    // UI элементы для отображения состояния игры
    private var gameInfoLabel: SKLabelNode?
    
    // Игровые компоненты
    private var deck = Deck()
    private var trickNode: TrickNode!
    private var trumpIndicator: TrumpIndicator!
    private var currentTrump: Suit?
    private var gameState: GameState!
    private(set) var scoreManager: ScoreManager?
    private var hasDealtAtLeastOnce = false
    private let shouldRevealAllPlayersCards = true
    
    override func didMove(to view: SKView) {
        self.backgroundColor = GameColors.sceneBackground
        
        setupPokerTable()
        setupPlayers()
        setupDealButton()
        setupScoreButton()
        setupGameInfoLabel()
        setupGameComponents()
        
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
            
            if let playerIndex = playerIndex(at: location) {
                registerTrickWin(for: playerIndex)
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
        
        let radiusX = min(table.tableWidth / 2 + 40, (maxX - minX) / 2)
        let radiusY = min(table.tableHeight / 2 + 20, (maxY - minY) / 2)
        
        let avatars = ["👨‍💼", "👩‍💼", "🧔", "👨‍🦰", "👩‍🦱"]
        let angles = seatAngles(for: playerCount)
        
        for (index, angle) in angles.enumerated() {
            let rawX = center.x + radiusX * cos(angle)
            let rawY = center.y + radiusY * sin(angle)
            
            let x = min(max(rawX, minX), maxX)
            let y = min(max(rawY, minY), maxY)
            let direction = CGVector(dx: cos(angle), dy: sin(angle))
            
            let playerNode = PlayerNode(
                playerNumber: index + 1,
                avatar: avatars[index % avatars.count],
                position: CGPoint(x: x, y: y),
                seatDirection: direction,
                isLocalPlayer: index == 0,
                shouldRevealCards: shouldRevealAllPlayersCards,
                totalPlayers: playerCount
            )
            
            players.append(playerNode)
            self.addChild(playerNode)
        }
    }
    
    private func seatAngles(for count: Int) -> [CGFloat] {
        switch count {
        case 3:
            return [-.pi / 2, 5 * .pi / 6, .pi / 6]
        case 4:
            return [-.pi / 2, .pi, .pi / 2, 0]
        default:
            guard count > 0 else { return [] }
            var result: [CGFloat] = []
            result.reserveCapacity(count)
            let angleStep = (2.0 * CGFloat.pi) / CGFloat(count)
            for index in 0..<count {
                let angle = -CGFloat(index) * angleStep - (CGFloat.pi / 2)
                result.append(angle)
            }
            return result
        }
    }
    
    // MARK: - Информация об игре
    
    private func setupGameInfoLabel() {
        let infoLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        infoLabel.text = "Ожидание раздачи"
        infoLabel.fontSize = 20
        infoLabel.fontColor = GameColors.gold
        infoLabel.horizontalAlignmentMode = .center
        infoLabel.verticalAlignmentMode = .center
        let insets = view?.safeAreaInsets ?? .zero
        infoLabel.position = CGPoint(x: self.size.width / 2, y: self.size.height - insets.top - 30)
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
        
        label.text = "\(blockName) | \(roundInfo) | \(cardsInfo)"
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
        gameInfoLabel?.position = CGPoint(x: self.size.width / 2, y: self.size.height - insets.top - 30)
        scoreButton?.position = CGPoint(x: insets.left + 34 + 150, y: self.size.height - insets.top - 24 - 43)
        dealButton?.position = CGPoint(x: insets.left + 34 + 150, y: insets.bottom + 24 + 43)
        
        trickNode?.centerPosition = CGPoint(x: self.size.width / 2, y: self.size.height / 2 + 20)
        trumpIndicator?.position = CGPoint(
            x: self.size.width - insets.right - 116,
            y: insets.bottom + 116
        )
    }
    
    // MARK: - Раздача карт (SKAction-based анимация)
    
    private func dealCards() {
        recordCurrentRoundIfNeeded()
        
        updateGameInfoLabel()
        
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
        let dealResult = deck.dealCards(playerCount: playerCount, cardsPerPlayer: cardsPerPlayer)
        
        // Строим цепочку анимаций через SKAction
        var actions: [SKAction] = []
        
        // 1. Раздаём карты каждому игроку с задержкой
        for (index, player) in players.enumerated() {
            let cards = dealResult.hands[index]
            let delay = SKAction.wait(forDuration: Double(index) * 0.3)
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
        
        // 4. Демонстрация: устанавливаем ставки
        let bidDelay = SKAction.wait(forDuration: Double(playerCount) * 0.3 + 2.0)
        let bidAction = SKAction.run { [weak self] in
            guard let self = self else { return }
            for (index, player) in self.players.enumerated() {
                let bid = (index % max(1, cardsPerPlayer)) + 1
                player.setBid(bid, animated: true)
                self.gameState.setBid(bid, forPlayerAt: index)
            }
        }
        actions.append(SKAction.sequence([bidDelay, bidAction]))
        
        // 5. Демонстрация: выделяем первого игрока
        let highlightDelay = SKAction.wait(forDuration: Double(playerCount) * 0.3 + 3.0)
        let highlightAction = SKAction.run { [weak self] in
            self?.players.first?.highlight(true)
        }
        actions.append(SKAction.sequence([highlightDelay, highlightAction]))
        
        // Запускаем все действия параллельно (каждое со своей задержкой)
        run(SKAction.group(actions), withKey: "dealSequence")
        
        // Подготавливаем следующий раунд
        if gameState.currentRoundInBlock + 1 >= gameState.totalRoundsInBlock {
            let currentBlockNumber = gameState.currentBlock.rawValue
            if currentBlockNumber >= GameConstants.totalBlocks {
                return
            }
        }
        
        gameState.startNewRound()
        hasDealtAtLeastOnce = true
    }
    
    // MARK: - Логика раунда
    
    private func recordCurrentRoundIfNeeded() {
        guard hasDealtAtLeastOnce, let scoreManager = scoreManager else { return }
        guard recordedRoundsInCurrentBlock() < gameState.currentRoundInBlock else { return }
        
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
    }
    
    private func registerTrickWin(for playerIndex: Int) {
        guard playerIndex >= 0, playerIndex < playerCount else { return }
        gameState.completeTrick(winner: playerIndex)
        players[playerIndex].incrementTricks()
        completeRoundIfNeeded()
    }
    
    private func completeRoundIfNeeded() {
        let totalTricks = gameState.players.reduce(0) { $0 + $1.tricksTaken }
        guard totalTricks >= gameState.currentCardsPerPlayer else { return }
        
        gameState.completeRound()
        recordCurrentRoundIfNeeded()
    }
    
    private func playerIndex(at point: CGPoint) -> Int? {
        let nodesAtPoint = nodes(at: point)
        for node in nodesAtPoint {
            if let playerNode = node as? PlayerNode {
                return playerNode.playerNumber - 1
            }
            if let playerNode = node.parent as? PlayerNode {
                return playerNode.playerNumber - 1
            }
            if let playerNode = node.parent?.parent as? PlayerNode {
                return playerNode.playerNumber - 1
            }
        }
        return nil
    }
    
    private func recordedRoundsInCurrentBlock() -> Int {
        guard let scoreManager = scoreManager else { return 0 }
        return scoreManager.currentBlockRoundResults.map { $0.count }.min() ?? 0
    }
}
