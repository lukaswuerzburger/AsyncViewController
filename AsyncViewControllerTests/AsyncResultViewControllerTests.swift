//
//  AsyncResultViewControllerTests.swift
//  AsyncViewControllerTests
//
//  Created by Lukas Würzburger on 12.05.20.
//  Copyright © 2020 Lukas Würzburger. All rights reserved.
//

import XCTest
@testable import AsyncViewController

class AsyncResultViewControllerTests: XCTestCase {

    enum MyError: Int, Error, Equatable {
        case loadingFailed
    }

    class MockAsyncViewController: AsyncResultViewController<UIViewController, String, MyError> {

        var didCallDidLoadViewController = false
        var didCallDidSucceedLoading = false
        var didCallDidFailLoading = false

        override func didLoadViewController(_ viewController: UIViewController) {
            super.didLoadViewController(viewController)
            didCallDidLoadViewController = true
        }

        override func didSucceedLoading(_ viewController: UIViewController) {
            super.didSucceedLoading(viewController)
            didCallDidSucceedLoading = true
        }

        override func didFailLoading(_ error: MyError) {
            super.didFailLoading(error)
            didCallDidFailLoading = true
        }
    }

    // MARK: - Tests

    func testSetupDidAssignViewController() {
        let asyncViewController = AsyncResultViewController(load: { _ in
        }, success: { _ -> UIViewController in
            .init()
        }, failure: { _ -> AsyncResultViewController<UIViewController, String, Error>.FailureResolution in
            .showViewController(.init())
        })
        XCTAssertNotNil(asyncViewController)
    }

    func testExecutesLoadingClosureWhenViewDidLoad() {
        let expect = expectation(description: "Loading closure should be called")
        let _: AsyncResultViewController<UIViewController, String, Error> = presentAsyncViewController(load: { _ in
            expect.fulfill()
        })
        wait(for: [expect], timeout: 1)
    }

    func testExecutesSuccessClosureWithResultOnSuccess() {
        let expect = expectation(description: "Success closure should be called")
        let _: AsyncResultViewController<UIViewController, String, Error> = presentAsyncViewController(load: { callback in
            callback(.success("Hello"))
        }, success: { string -> UIViewController in
            XCTAssertEqual(string, "Hello")
            expect.fulfill()
            return .init()
        })
        wait(for: [expect], timeout: 1)
    }

    func testExecutesFailureClosureWithResultOnError() {
        let expect = expectation(description: "Failure closure should be called")
        presentAsyncViewController(load: { callback in
            callback(.failure(.loadingFailed))
        }, failure: { error -> AsyncResultViewController<UIViewController, String, MyError>.FailureResolution in
            XCTAssertEqual(.loadingFailed, error)
            expect.fulfill()
            return .showViewController(.init())
        })
        wait(for: [expect], timeout: 1)
    }

    func testNavigationItemOverridePolicyIsSkippedWhenEmpty() {
        let leftBarButtonItem = UIBarButtonItem()
        let title = String()
        let rightBarButtonItem = UIBarButtonItem()
        let viewController = UIViewController()
        viewController.navigationItem.leftBarButtonItem = leftBarButtonItem
        viewController.navigationItem.title = title
        viewController.navigationItem.rightBarButtonItem = rightBarButtonItem
        let asyncViewController: AsyncResultViewController<UIViewController, String, Error> = presentAsyncViewController(load: { callback in
            callback(.success("Hello"))
        }, success: { _ -> UIViewController in
            return viewController
        })
        XCTAssertEqual(viewController, asyncViewController.successViewController)
        XCTAssertNotEqual(viewController.navigationItem.leftBarButtonItems, asyncViewController.navigationItem.leftBarButtonItems)
        XCTAssertNotEqual(viewController.navigationItem.title, asyncViewController.navigationItem.title)
        XCTAssertNotEqual(viewController.navigationItem.rightBarButtonItems, asyncViewController.navigationItem.rightBarButtonItems)
        asyncViewController.navigationItemOverridePolicy = .leftBarButtonItems
        asyncViewController.reload()
        XCTAssertEqual(viewController.navigationItem.leftBarButtonItems, asyncViewController.navigationItem.leftBarButtonItems)
        XCTAssertNotEqual(viewController.navigationItem.title, asyncViewController.navigationItem.title)
        XCTAssertNotEqual(viewController.navigationItem.rightBarButtonItems, asyncViewController.navigationItem.rightBarButtonItems)
        asyncViewController.navigationItemOverridePolicy = .title
        asyncViewController.reload()
        XCTAssertEqual(viewController.navigationItem.leftBarButtonItems, asyncViewController.navigationItem.leftBarButtonItems)
        XCTAssertEqual(viewController.navigationItem.title, asyncViewController.navigationItem.title)
        XCTAssertNotEqual(viewController.navigationItem.rightBarButtonItems, asyncViewController.navigationItem.rightBarButtonItems)
        asyncViewController.navigationItemOverridePolicy = .rightBarButtonItems
        asyncViewController.reload()
        XCTAssertEqual(viewController.navigationItem.leftBarButtonItems, asyncViewController.navigationItem.leftBarButtonItems)
        XCTAssertEqual(viewController.navigationItem.title, asyncViewController.navigationItem.title)
        XCTAssertEqual(viewController.navigationItem.rightBarButtonItems, asyncViewController.navigationItem.rightBarButtonItems)
    }

    func testSuccessLifeCycleHookGetsCalled() {
        let mock = presentMockAsyncViewController(result: .success("Hello"))
        XCTAssertTrue(mock.didCallDidLoadViewController)
        XCTAssertTrue(mock.didCallDidSucceedLoading)
        XCTAssertFalse(mock.didCallDidFailLoading)
    }

    func testFailureLifeCycleHookGetsCalled() {
        let mock = presentMockAsyncViewController(result: .failure(.loadingFailed))
        XCTAssertTrue(mock.didCallDidLoadViewController)
        XCTAssertTrue(mock.didCallDidFailLoading)
        XCTAssertFalse(mock.didCallDidSucceedLoading)
    }

    func testCustomFailureResolutionGetsCalled() {
        let expect = expectation(description: "Custom failure closure should be called")
        presentAsyncViewController(load: { callback in
            callback(.failure(MyError.loadingFailed))
        }, failure: { _ -> AsyncResultViewController<UIViewController, String, MyError>.FailureResolution in
            .custom { _ in
                expect.fulfill()
            }
        })
        wait(for: [expect], timeout: 1)
    }

    func testLoadingViewStartsLoading() {
        let expect = expectation(description: "Success closure should be called")
        var asyncViewController: AsyncResultViewController<UIViewController, String, Error>!
        asyncViewController = presentAsyncViewController(load: { callback in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                callback(.success("Hello"))
            }
        }, success: { _ -> UIViewController in
            XCTAssertFalse(asyncViewController.loadingViewController.isAnimating)
            expect.fulfill()
            return .init()
        }, autoPresent: false)
        XCTAssertFalse(asyncViewController.loadingViewController.isAnimating)
        asyncViewController.loadView()
        asyncViewController.viewDidLoad()
        XCTAssertTrue(asyncViewController.loadingViewController.isAnimating)
        wait(for: [expect], timeout: 1)
    }

    func testPresentsSuccessViewControllerOnSuccess() {
        let successViewController = UIViewController()
        let asyncViewController: AsyncResultViewController<UIViewController, String, Error> = presentAsyncViewController(load: { callback in
            callback(.success("Hallo"))
        }, success: { _ -> UIViewController in
            return successViewController
        })
        XCTAssertEqual(asyncViewController.successViewController, successViewController)
        XCTAssertTrue(asyncViewController.children.contains(successViewController))
        XCTAssertTrue(asyncViewController.view.subviews.contains(successViewController.view))
    }

    func testPresentsFailureViewControllerOnSuccess() {
        let errorViewController = UIViewController()
        let asyncViewController: AsyncResultViewController<UIViewController, String, Error> = presentAsyncViewController(load: { callback in
            callback(.failure(MyError.loadingFailed))
        }, failure: { _ -> AsyncResultViewController<UIViewController, String, Error>.FailureResolution in
            .showViewController(errorViewController)
        })
        XCTAssertNil(asyncViewController.successViewController)
        XCTAssertTrue(asyncViewController.children.contains(errorViewController))
        XCTAssertTrue(asyncViewController.view.subviews.contains(errorViewController.view))
    }

    func testStateCycleWithSuccess() {
        let expect = expectation(description: "Success closure should be called")
        var asyncViewController: AsyncResultViewController<UIViewController, String, Error>!
        asyncViewController = presentAsyncViewController(load: { callback in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                callback(.success("Hello"))
            }
        }, success: { _ -> UIViewController in
            XCTAssertEqual(asyncViewController.state, .finished)
            expect.fulfill()
            return .init()
        }, autoPresent: false)
        XCTAssertEqual(asyncViewController.state, .idle)
        asyncViewController.loadView()
        asyncViewController.viewDidLoad()
        XCTAssertEqual(asyncViewController.state, .loading)
        wait(for: [expect], timeout: 1)
    }

    func testStateCycleWithFailure() {
        let expect = expectation(description: "Success closure should be called")
        var asyncViewController: AsyncResultViewController<UIViewController, String, MyError>!
        asyncViewController = presentAsyncViewController(load: { callback in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                callback(.failure(.loadingFailed))
            }
        }, failure: { _ -> AsyncResultViewController<UIViewController, String, MyError>.FailureResolution in
            XCTAssertEqual(asyncViewController.state, .finished)
            expect.fulfill()
            return .showViewController(.init())
        }, autoPresent: false)
        XCTAssertEqual(asyncViewController.state, .idle)
        asyncViewController.loadView()
        asyncViewController.viewDidLoad()
        XCTAssertEqual(asyncViewController.state, .loading)
        wait(for: [expect], timeout: 1)
    }

    // MARK: - Helper

    @discardableResult func presentAsyncViewController<T, E>(load: @escaping (@escaping (Result<T, E>) -> Void) -> Void, success: ((T) -> UIViewController)? = nil, failure: ((E) -> AsyncResultViewController<UIViewController, T, E>.FailureResolution)? = nil, autoPresent: Bool = true) -> AsyncResultViewController<UIViewController, T, E> {
        let asyncViewController = AsyncResultViewController(load: { callback in
            load(callback)
        }, success: { object -> UIViewController in
            return success?(object) ?? .init()
        }, failure: { error -> AsyncResultViewController<UIViewController, T, E>.FailureResolution in
            return failure?(error) ?? .showViewController(.init())
        })
        if autoPresent {
            asyncViewController.loadView()
            asyncViewController.viewDidLoad()
        }
        return asyncViewController
    }

    @discardableResult func presentMockAsyncViewController(result: Result<String, MyError>) -> MockAsyncViewController {
        let mockAsyncViewController = MockAsyncViewController(load: { callback in
            callback(result)
        }, success: { _ -> UIViewController in
            .init()
        }, failure: { _ -> MockAsyncViewController.FailureResolution in
            .showViewController(.init())
        })
        mockAsyncViewController.loadView()
        mockAsyncViewController.viewDidLoad()
        return mockAsyncViewController
    }
}
