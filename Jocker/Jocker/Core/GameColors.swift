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
    static let gold = SKColor(red: 0.93, green: 0.76, blue: 0.33, alpha: 1.0)
    /// Полупрозрачный золотистый — декоративные границы
    static let goldTranslucent = SKColor(red: 0.93, green: 0.76, blue: 0.33, alpha: 0.42)
    /// Основной цвет текста
    static let textPrimary = SKColor(red: 0.94, green: 0.96, blue: 1.00, alpha: 1.0)
    /// Вторичный цвет текста
    static let textSecondary = SKColor(red: 0.72, green: 0.79, blue: 0.90, alpha: 1.0)
    
    // MARK: - Фон
    
    /// Тёмно-синий фон сцены
    static let sceneBackground = SKColor(red: 0.06, green: 0.09, blue: 0.15, alpha: 1.0)
    /// Фон аватара игрока
    static let playerBackground = SKColor(red: 0.12, green: 0.17, blue: 0.26, alpha: 0.94)
    /// Полупрозрачные панели поверх стола
    static let panelBackground = SKColor(red: 0.09, green: 0.13, blue: 0.20, alpha: 0.82)
    
    // MARK: - Покерный стол
    
    /// Тёмная окантовка стола (резиновый/кожаный борт)
    static let tableBorder = SKColor(red: 0.08, green: 0.09, blue: 0.11, alpha: 1.0)
    /// Обводка борта (лёгкий блик)
    static let tableBorderStroke = SKColor(red: 0.18, green: 0.19, blue: 0.22, alpha: 1.0)
    /// Тёмно-зелёное сукно
    static let tableFelt = SKColor(red: 0.05, green: 0.34, blue: 0.18, alpha: 1.0)
    /// Обводка сукна / внутренние линии
    static let tableFeltStroke = SKColor(red: 0.10, green: 0.53, blue: 0.29, alpha: 1.0)
    /// Доп. цвет для текстур/паттернов на сукне
    static let tableTexture = SKColor(white: 0.0, alpha: 0.07)
    
    // MARK: - Кнопки
    
    /// Акцентный синий фон кнопки
    static let buttonFill = SKColor(red: 0.16, green: 0.39, blue: 0.77, alpha: 1.0)
    /// Обводка кнопки
    static let buttonStroke = SKColor(red: 0.10, green: 0.24, blue: 0.50, alpha: 1.0)
    /// Верхний блик кнопки
    static let buttonHighlight = SKColor(white: 1.0, alpha: 0.13)
    /// Цвет текста на кнопках
    static let buttonText = SKColor(red: 0.96, green: 0.98, blue: 1.0, alpha: 1.0)
    
    // MARK: - Карты
    
    /// Красный цвет масти (бубны, черви)
    static let cardRed = SKColor(red: 0.8, green: 0.1, blue: 0.1, alpha: 1.0)
    /// Почти чёрный цвет пик
    static let cardSpade = SKColor(white: 0.12, alpha: 1.0)
    /// Тёмно-зелёный цвет крестей
    static let cardClub = SKColor(red: 0.06, green: 0.34, blue: 0.20, alpha: 1.0)
    /// Универсальный тёмный цвет (legacy/общий)
    static let cardBlack = SKColor(white: 0.1, alpha: 1.0)
    /// Фон рубашки карты
    static let cardBack = SKColor(red: 0.16, green: 0.31, blue: 0.63, alpha: 1.0)
    /// Фон джокера
    static let jokerBackground = SKColor(red: 1.0, green: 0.95, blue: 0.8, alpha: 1.0)
    /// Цвет текста "JOKER"
    static let jokerText = SKColor(red: 0.43, green: 0.16, blue: 0.18, alpha: 1.0)
    /// Рамка карты
    static let cardBorder = SKColor(white: 0.3, alpha: 1.0)
    
    // MARK: - Индикаторы состояния
    
    /// Зелёный — ставка выполнена / активный игрок
    static let statusGreen = SKColor(red: 0.28, green: 0.82, blue: 0.53, alpha: 1.0)
    /// Оранжевый — перебор
    static let statusOrange = SKColor(red: 0.96, green: 0.57, blue: 0.16, alpha: 1.0)
    
    // MARK: - Индикатор козыря
    
    /// Фон индикатора козыря
    static let trumpBackground = SKColor(red: 0.10, green: 0.16, blue: 0.25, alpha: 0.88)
}
