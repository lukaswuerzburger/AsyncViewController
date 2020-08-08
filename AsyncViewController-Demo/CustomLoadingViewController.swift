//
//  CustomLoadingViewController.swift
//  AsyncViewController-Demo
//
//  Created by Lukas Würzburger on 09.05.20.
//  Copyright © 2020 Lukas Würzburger. All rights reserved.
//

import UIKit
import AsyncViewController

class CustomLoadingViewController: UIViewController, LoadingAnimatable {

    // MARK: - UI Elements

    let dot = UIView()
    var centerConstraint: NSLayoutConstraint!

    // MARK: - Variables

    var isAnimating: Bool = false

    // MARK: - View Life Cycle

    override func loadView() {
        super.loadView()
        dot.translatesAutoresizingMaskIntoConstraints = false
        dot.backgroundColor = .darkGray
        dot.layer.masksToBounds = true
        dot.layer.cornerRadius = 10
        view.addSubview(dot)
        centerConstraint = dot.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: -30)
        NSLayoutConstraint.activate([
            centerConstraint,
            dot.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            dot.widthAnchor.constraint(equalToConstant: 20),
            dot.heightAnchor.constraint(equalToConstant: 20)
        ])
        view.layoutIfNeeded()
    }

    // MARK: - Animations

    func animate() {
        centerConstraint.constant = 30
        view.setNeedsUpdateConstraints()
        UIView.animate(withDuration: 0.5, delay: 0, options: [.curveEaseInOut], animations: {
            self.view.layoutIfNeeded()
        }, completion: { finished in
            guard finished else { return }
            self.centerConstraint.constant = -30
            self.view.setNeedsUpdateConstraints()
            UIView.animate(withDuration: 0.5, delay: 0, options: [.curveEaseInOut], animations: {
                self.view.layoutIfNeeded()
            }, completion: { finished in
                guard finished else { return }
                self.animate()
            })
        })
    }

    // MARK: - Loading Animatable

    func startLoadingAnimation() {
        animate()
    }

    func stopLoadingAnimation() {
        view.layer.removeAllAnimations()
    }
}
