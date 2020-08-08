//
//  AsyncViewController.swift
//  AsyncViewController
//
//  Created by Lukas Würzburger on 31.05.20.
//  Copyright © 2020 Lukas Würzburger. All rights reserved.
//

import UIKit

open class AsyncViewController<T>: UIViewController {

    public enum State {
        case idle
        case loading
        case finished
    }

    // MARK: - UI Elements

    public var loadingViewController: LoadingAnimatable = LoadingViewController()
    private var destinationViewController: UIViewController?

    // MARK: - Variables

    public var navigationItemOverridePolicy: NavigationItemOverridePolicy = []
    public var fadesInResultingViewAfterLoading: Bool = true
    public var state: State = .idle

    private var loadClosure: (@escaping (T) -> Void) -> Void
    private var buildClosure: (T) -> UIViewController?

    // MARK: - Initializer

    public init(
        load: @escaping (@escaping (T) -> Void) -> Void,
        build: @escaping (T) -> UIViewController?
    ) {
        loadClosure = load
        buildClosure = build
        super.init(nibName: nil, bundle: nil)
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Life Cycle

    open override func loadView() {
        super.loadView()
        view.backgroundColor = .white
    }

    open override func viewDidLoad() {
        super.viewDidLoad()
        reload()
    }

    // MARK: - View Helpers

    private func deployViewController(_ viewController: UIViewController) {
        destinationViewController = viewController
        addViewController(viewController)
        animateFadeInIfNeeded(for: viewController)
        overrideNavigationItemIfNeeded(viewController)
    }

    private func addViewController(_ viewController: UIViewController) {
        viewController.view.translatesAutoresizingMaskIntoConstraints = false
        addChild(viewController)
        view.addSubview(viewController.view)
        NSLayoutConstraint.activate([
            viewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            viewController.view.leftAnchor.constraint(equalTo: view.leftAnchor),
            viewController.view.rightAnchor.constraint(equalTo: view.rightAnchor),
            viewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        viewController.didMove(toParent: self)
    }

    private func animateFadeInIfNeeded(for viewController: UIViewController) {
        guard fadesInResultingViewAfterLoading else { return }
        viewController.view.alpha = 0
        UIView.animate(withDuration: 0.5) {
            viewController.view.alpha = 1
        }
    }

    private func overrideNavigationItemIfNeeded(_ viewController: UIViewController) {
        if navigationItemOverridePolicy.contains(.leftBarButtonItems) {
            navigationItem.leftBarButtonItems = viewController.navigationItem.leftBarButtonItems
        }
        if navigationItemOverridePolicy.contains(.title) {
            navigationItem.title = viewController.navigationItem.title
            navigationItem.titleView = viewController.navigationItem.titleView
        }
        if navigationItemOverridePolicy.contains(.rightBarButtonItems) {
            navigationItem.rightBarButtonItems = viewController.navigationItem.rightBarButtonItems
        }
    }

    private func removeDestinationViewControllerIfNeeded() {
        guard let viewController = destinationViewController else { return }
        remove(viewController)
    }

    private func remove(_ viewController: UIViewController) {
        viewController.view.removeFromSuperview()
        viewController.removeFromParent()
    }

    // MARK: - Life Cycle Hooks

    open func didLoadViewController(_ viewController: UIViewController) {}

    // MARK: - Networking

    public func reload() {
        state = .loading
        removeDestinationViewControllerIfNeeded()
        addViewController(loadingViewController)
        loadingViewController.startLoadingAnimation()
        loadClosure { [weak self] result in
            guard let self = self else { return }
            self.loadingViewController.stopLoadingAnimation()
            self.remove(self.loadingViewController)
            self.handleReload(result: result)
        }
    }

    private func handleReload(result: T) {
        state = .finished
        if let viewController = buildClosure(result) {
            didLoadViewController(viewController)
            deployViewController(viewController)
        }
    }
}
