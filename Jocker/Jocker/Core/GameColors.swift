//
//  GameColors.swift
//  Jocker
//
//  Created by Чаниев Мурад on 08.02.2026.
//

import SpriteKit

/// Цветовая палитра игры — единый источник правды для всех цветов
enum GameColors {
    // MARK: - Акцентные цвета
    
    /// Золотистый — декоративные элементы, информационные лейблы
    static let gold = SKColor(red: 0.85, green: 0.65, blue: 0.13, alpha: 1.0)
    /// Полупрозрачный золотистый — декоративные границы
    static let goldTranslucent = SKColor(red: 0.85, green: 0.65, blue: 0.13, alpha: 0.6)
    
    // MARK: - Фон
    
    /// Тёмно-синий фон сцены
    static let sceneBackground = SKColor(red: 0.1, green: 0.1, blue: 0.15, alpha: 1.0)
    /// Фон аватара игрока
    static let playerBackground = SKColor(red: 0.2, green: 0.2, blue: 0.25, alpha: 0.9)
    
    // MARK: - Покерный стол
    
    /// Коричневая окантовка стола (дерево)
    static let tableBorder = SKColor(red: 0.4, green: 0.2, blue: 0.1, alpha: 1.0)
    /// Тёмная обводка стола
    static let tableBorderStroke = SKColor(red: 0.3, green: 0.15, blue: 0.05, alpha: 1.0)
    /// Зелёное сукно (Forest Green)
    static let tableFelt = SKColor(red: 0.13, green: 0.55, blue: 0.13, alpha: 1.0)
    /// Обводка зелёного сукна
    static let tableFeltStroke = SKColor(red: 0.1, green: 0.4, blue: 0.1, alpha: 1.0)
    /// Текстурные пятна на сукне
    static let tableTexture = SKColor(red: 0.1, green: 0.5, blue: 0.1, alpha: 0.05)
    
    // MARK: - Кнопки
    
    /// Красный фон кнопки
    static let buttonFill = SKColor(red: 0.85, green: 0.2, blue: 0.2, alpha: 1.0)
    /// Обводка кнопки
    static let buttonStroke = SKColor(red: 0.65, green: 0.1, blue: 0.1, alpha: 1.0)
    
    // MARK: - Карты
    
    /// Красный цвет масти (бубны, черви)
    static let cardRed = SKColor(red: 0.8, green: 0.1, blue: 0.1, alpha: 1.0)
    /// Чёрный цвет масти (пики, крести)
    static let cardBlack = SKColor(white: 0.1, alpha: 1.0)
    /// Фон рубашки карты
    static let cardBack = SKColor(red: 0.1, green: 0.2, blue: 0.6, alpha: 1.0)
    /// Фон джокера
    static let jokerBackground = SKColor(red: 1.0, green: 0.95, blue: 0.8, alpha: 1.0)
    /// Цвет текста "JOKER"
    static let jokerText = SKColor(red: 0.5, green: 0.0, blue: 0.5, alpha: 1.0)
    /// Рамка карты
    static let cardBorder = SKColor(white: 0.3, alpha: 1.0)
    
    // MARK: - Индикаторы состояния
    
    /// Зелёный — ставка выполнена / активный игрок
    static let statusGreen = SKColor(red: 0.2, green: 0.8, blue: 0.2, alpha: 1.0)
    /// Оранжевый — перебор
    static let statusOrange = SKColor(red: 1.0, green: 0.5, blue: 0.0, alpha: 1.0)
    
    // MARK: - Индикатор козыря
    
    /// Фон индикатора козыря
    static let trumpBackground = SKColor(white: 0.2, alpha: 0.8)
}
