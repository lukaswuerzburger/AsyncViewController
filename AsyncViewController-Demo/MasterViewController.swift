//
//  MasterViewController.swift
//  AsyncViewController-Demo
//
//  Created by Lukas Würzburger on 08.05.20.
//  Copyright © 2020 Lukas Würzburger. All rights reserved.
//

import UIKit
import AsyncViewController

struct Example {
    var title: String
    var action: () -> Void
}

class MasterViewController: UITableViewController {

    var examples: [Example] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        examples = [
            .init(title: "🎉 Success Push") { self.presentSuccessPush() },
            .init(title: "🎉 Success Modal") { self.presentSuccessModal() },
            .init(title: "⚠️ Failure Push") { self.presentFailurePush() },
            .init(title: "⚠️ Failure Modal") { self.presentFailureModal() },
            .init(title: "⚠️ Failure Push (Auto Dismiss + Alert)") { self.presentFailurePush(autoDismiss: true) },
            .init(title: "⚠️ Failure Modal (Auto Dismiss + Alert)") { self.presentFailureModal(autoDismiss: true) },
            .init(title: "🌈 Custom Loading Animation") { self.presentCustomAnimation() },
            .init(title: "🧭 Navigation Item Override") { self.presentNavigationOverride() },
            .init(title: "🧭 Custom Navigation Item Override") { self.presentCustomNavigationOverride() },
            .init(title: "✅ Unfailable Async Task") { self.presentUnfailableAsyncTask() }

        ]

        clearsSelectionOnViewWillAppear = true
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return examples.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel!.text = examples[indexPath.row].title
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        examples[indexPath.row].action()
    }

    // MARK: - Helper

    func successViewController() -> AsyncResultViewController<UIViewController, String, Error> {
        let viewController = AsyncResultViewController(load: { callback in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                callback(.success("It worked 🎉"))
            }
        }, success: { string -> UIViewController in
            return self.viewController(title: string)
        }, failure: { error -> AsyncResultViewController<UIViewController, String, Error>.FailureResolution in
            return .showViewController(self.errorViewController(error: error))
        })
        return viewController
    }

    func failureViewController(_ failureBlock: @escaping (Error) -> AsyncResultViewController<UIViewController, String, Error>.FailureResolution) -> UIViewController {
        let viewController = AsyncResultViewController(load: { callback in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                callback(.failure(MyResponseError.notFound))
            }
        }, success: { string -> UIViewController in
            return self.viewController(title: string)
        }, failure: { error -> AsyncResultViewController<UIViewController, String, Error>.FailureResolution in
            return failureBlock(error)
        })
        return viewController
    }

    func customAnimationViewController() -> UIViewController {
        let viewController = AsyncResultViewController(load: { callback in
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                callback(.success("It worked 🎉"))
            }
        }, success: { string -> UIViewController in
            return self.viewController(title: string)
        }, failure: { error -> AsyncResultViewController<UIViewController, String, Error>.FailureResolution in
            return .showViewController(self.errorViewController(error: error))
        })
        viewController.loadingViewController = CustomLoadingViewController()
        return viewController
    }

    func viewController(title: String) -> UIViewController {
        let viewController = storyboard?.instantiateViewController(withIdentifier: "detail") as? DetailViewController
        viewController!.title = title
        return viewController!
    }

    func errorViewController(error: Error) -> UIViewController {
        return viewController(title: "⚠️ Something went wrong:\n\n" + error.localizedDescription)
    }

    func presentSuccessPush() {
        navigationController?.pushViewController(successViewController(), animated: true)
    }

    func presentSuccessModal() {
        presentModalViewController(viewController: successViewController())
    }

    func presentFailurePush(autoDismiss: Bool = false) {
        let viewController = failureViewController({ error in
            if autoDismiss {
                return .custom({ asyncViewController in
                    asyncViewController.navigationController?.popToRootViewController(animated: true)
                    self.presentErrorAlert(error)
                })
            } else {
                return .showViewController(self.errorViewController(error: error))
            }
        })
        navigationController?.pushViewController(viewController, animated: true)
    }

    func presentFailureModal(autoDismiss: Bool = false) {
        let viewController = failureViewController({ error in
            if autoDismiss {
                return .custom({ asyncViewController in
                    asyncViewController.dismiss(animated: true)
                    self.presentErrorAlert(error)
                })
            } else {
                return .showViewController(self.errorViewController(error: error))
            }
        })
        presentModalViewController(viewController: viewController)
    }

    func presentCustomAnimation() {
        navigationController?.pushViewController(customAnimationViewController(), animated: true)
    }

    func presentNavigationOverride() {
        let viewController = successViewController()
        viewController.title = "Loading"
        viewController.navigationItemOverridePolicy = .all
        navigationController?.pushViewController(viewController, animated: true)
    }

    func presentCustomNavigationOverride() {
        let viewController = successViewController()
        viewController.title = "Loading"
        viewController.navigationItem.rightBarButtonItems = [UIBarButtonItem(barButtonSystemItem: .cancel, target: nil, action: nil)]
        viewController.navigationItemOverridePolicy = .rightBarButtonItems
        navigationController?.pushViewController(viewController, animated: true)
    }

    func presentUnfailableAsyncTask() {
        let viewController = AsyncViewController(load: { callback in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                callback("Always success!")
            }
        }, build: { string in
            let viewController = UIViewController()
            viewController.title = string
            return viewController
        })
        viewController.navigationItemOverridePolicy = .title
        presentModalViewController(viewController: viewController)
    }

    func presentModalViewController(viewController: UIViewController) {
        let navigationController = UINavigationController(rootViewController: viewController)
        navigationController.modalPresentationStyle = .fullScreen
        viewController.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissViewController))
        present(navigationController, animated: true)
    }

    @objc func dismissViewController() {
        presentedViewController?.dismiss(animated: true)
    }

    func presentErrorAlert(_ error: Error) {
        let alert = UIAlertController(title: "⚠️ Something went wrong", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(.init(title: "Dismiss", style: .cancel))
        present(alert, animated: true)
    }
}

enum MyResponseError: Error {
    case notFound
}
