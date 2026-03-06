//
//  GameSceneModalPresenter.swift
//  Jocker
//
//  Created by Codex on 06.03.2026.
//

import SpriteKit
import UIKit

/// UIKit modal presentation helper used by `GameScene`.
struct GameSceneModalPresenter {
    func topPresentedViewController(for sceneView: SKView?) -> UIViewController? {
        guard let sceneView else { return nil }
        var topController = sceneView.window?.rootViewController

        while let presented = topController?.presentedViewController {
            topController = presented
        }

        return topController
    }

    @discardableResult
    func presentOverlay(_ modal: UIViewController, from sceneView: SKView?) -> Bool {
        guard let presenter = topPresentedViewController(for: sceneView) else { return false }
        modal.modalPresentationStyle = .overFullScreen
        modal.modalTransitionStyle = .crossDissolve
        presenter.present(modal, animated: true)
        return true
    }

    func isTopPresented<T: UIViewController>(_ type: T.Type, from sceneView: SKView?) -> Bool {
        return topPresentedViewController(for: sceneView) is T
    }

    func dismissGameViewControllerToStartScreen(from sceneView: SKView?) {
        DispatchQueue.main.async {
            guard let rootController = sceneView?.window?.rootViewController else { return }
            var topController = rootController

            while let presented = topController.presentedViewController {
                topController = presented
            }

            if let gameViewController = topController as? GameViewController {
                gameViewController.dismiss(animated: true)
                return
            }

            var currentController: UIViewController? = topController
            while let controller = currentController {
                if let gameViewController = controller as? GameViewController {
                    gameViewController.dismiss(animated: true)
                    return
                }
                currentController = controller.presentingViewController
            }
        }
    }
}
