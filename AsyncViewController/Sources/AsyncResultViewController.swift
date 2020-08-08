//
//  AsyncViewController.swift
//  AsyncResultViewController
//
//  Created by Lukas Würzburger on 08.05.20.
//  Copyright © 2020 Lukas Würzburger. All rights reserved.
//

import UIKit

open class AsyncResultViewController<VC: UIViewController, T, E: Error>: AsyncViewController<Result<T, E>> {

    public enum State {
        case idle
        case loading
        case succeeded
        case failed
    }

    public enum FailureResolution {
        case showViewController(UIViewController)
        case custom((AsyncResultViewController<VC, T, E>) -> Void)
    }

    // MARK: - UI Elements

    private(set) public var successViewController: VC?

    // MARK: - Variables

    private var loadClosure: (@escaping (Result<T, E>) -> Void) -> Void
    private var successClosure: (T) -> VC
    private var failureClosure: (E) -> FailureResolution

    // MARK: - Initializer

    public init(
        load: @escaping (@escaping (Result<T, E>) -> Void) -> Void,
        success: @escaping (T) -> VC,
        failure: @escaping (E) -> FailureResolution
    ) {
        loadClosure = load
        successClosure = success
        failureClosure = failure
        var buildClosure: ((Result<T, E>) -> UIViewController?)?
        super.init(load: load, build: { (result) -> UIViewController? in
            buildClosure?(result)
        })
        buildClosure = { result in
            self.handleReload(result: result)
        }
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Life Cycle Hooks

    open func didSucceedLoading(_ viewController: VC) {}

    open func didFailLoading(_ error: E) {}

    // MARK: - Networking

    private func handleReload(result: Result<T, E>) -> UIViewController? {
        switch result {
        case .success(let model):
            let viewController = successClosure(model)
            successViewController = viewController
            didSucceedLoading(viewController)
            return viewController
        case .failure(let error):
            didFailLoading(error)
            switch failureClosure(error) {
            case .showViewController(let viewController):
                return viewController
            case .custom(let customCallback):
                customCallback(self)
                return nil
            }
        }
    }
}
