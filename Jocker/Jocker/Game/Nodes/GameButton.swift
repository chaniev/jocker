//
//  GameButton.swift
//  Jocker
//
//  Created by Чаниев Мурад on 08.02.2026.
//

import SpriteKit

/// Универсальная кнопка для игровой сцены
///
/// Инкапсулирует логику создания стилизованной кнопки с тенью,
/// хайлайтом и анимацией нажатия. Заменяет дублированный код
/// `setupDealButton` и `setupScoreButton` в `GameScene`.
class GameButton: SKNode {
    
    // MARK: - Properties
    
    /// Callback при нажатии
    var onTap: (() -> Void)?
    
    private let backgroundNode: SKShapeNode
    private let titleLabel: SKLabelNode
    private let buttonSize: CGSize
    
    // MARK: - Initialization
    
    /// Создать кнопку с заданным заголовком и размером
    ///
    /// - Parameters:
    ///   - title: текст на кнопке
    ///   - size: размер кнопки (по умолчанию 360×100)
    ///   - fillColor: цвет фона кнопки
    ///   - strokeColor: цвет обводки кнопки
    init(
        title: String,
        size: CGSize = CGSize(width: 360, height: 100),
        fillColor: SKColor = SKColor(red: 0.85, green: 0.2, blue: 0.2, alpha: 1.0),
        strokeColor: SKColor = SKColor(red: 0.65, green: 0.1, blue: 0.1, alpha: 1.0)
    ) {
        self.buttonSize = size
        
        let cornerRadius: CGFloat = 24
        let buttonRect = CGRect(
            x: -size.width / 2,
            y: -size.height / 2,
            width: size.width,
            height: size.height
        )
        
        // Фон кнопки
        backgroundNode = SKShapeNode(rect: buttonRect, cornerRadius: cornerRadius)
        backgroundNode.fillColor = fillColor
        backgroundNode.strokeColor = strokeColor
        backgroundNode.lineWidth = 3
        backgroundNode.zPosition = 0
        
        // Текст кнопки
        titleLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        titleLabel.text = title
        titleLabel.fontSize = 40
        titleLabel.fontColor = .white
        titleLabel.verticalAlignmentMode = .center
        titleLabel.horizontalAlignmentMode = .center
        titleLabel.position = .zero
        titleLabel.zPosition = 2
        
        super.init()
        
        self.zPosition = 100
        
        addChild(backgroundNode)
        
        // Эффект градиента (хайлайт верхней половины)
        let highlightRect = CGRect(
            x: -size.width / 2,
            y: 0,
            width: size.width,
            height: size.height / 2
        )
        let highlight = SKShapeNode(rect: highlightRect, cornerRadius: cornerRadius)
        highlight.fillColor = SKColor(white: 1.0, alpha: 0.15)
        highlight.strokeColor = .clear
        highlight.zPosition = 1
        backgroundNode.addChild(highlight)
        
        // Тень текста
        let shadow = SKLabelNode(fontNamed: "Helvetica-Bold")
        shadow.text = title
        shadow.fontSize = 40
        shadow.fontColor = SKColor(white: 0.0, alpha: 0.5)
        shadow.verticalAlignmentMode = .center
        shadow.horizontalAlignmentMode = .center
        shadow.position = CGPoint(x: 2, y: -2)
        shadow.zPosition = 1
        backgroundNode.addChild(shadow)
        
        backgroundNode.addChild(titleLabel)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Public Methods
    
    /// Обновить текст кнопки
    func setTitle(_ title: String) {
        titleLabel.text = title
        // Обновляем тень
        if let shadow = backgroundNode.children.compactMap({ $0 as? SKLabelNode }).first(where: { $0 !== titleLabel }) {
            shadow.text = title
        }
    }
    
    /// Проверить, содержит ли кнопка указанную точку (в координатах родителя)
    func containsPoint(_ point: CGPoint) -> Bool {
        let localPoint = convert(point, from: parent ?? self)
        return backgroundNode.contains(localPoint)
    }
    
    /// Анимация нажатия с вызовом callback по завершении
    func animateTap() {
        let scaleDown = SKAction.scale(to: 0.95, duration: 0.1)
        let scaleUp = SKAction.scale(to: 1.0, duration: 0.1)
        let pulse = SKAction.sequence([scaleDown, scaleUp])
        
        run(pulse) { [weak self] in
            self?.onTap?()
        }
    }
}
