//
//  JokerPlayDecision.swift
//  Jocker
//
//  Created by Codex on 15.02.2026.
//

import Foundation

/// Пользовательское решение о розыгрыше джокера в текущей взятке.
struct JokerPlayDecision: Equatable {
    let style: JokerPlayStyle
    let leadDeclaration: JokerLeadDeclaration?

    static var defaultLead: JokerPlayDecision {
        return JokerPlayDecision(
            style: .faceUp,
            leadDeclaration: .wish
        )
    }

    static var defaultNonLead: JokerPlayDecision {
        return JokerPlayDecision(
            style: .faceUp,
            leadDeclaration: nil
        )
    }
}
