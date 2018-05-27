//
//  ViewRouterPerformAddAsChildTests.swift
//  ZIKViewRouterTests
//
//  Created by zuik on 2018/4/26.
//  Copyright © 2018 zuik. All rights reserved.
//

import XCTest
import ZRouter

class ViewRouterPerformAddAsChildTests: ZIKViewRouterTestCase {
    
    weak var testRouter: DestinationViewRouter<AViewInput>? {
        willSet {
            self.router = newValue?.router
            self.strongTestRouter = newValue
        }
    }
    var strongTestRouter: DestinationViewRouter<AViewInput>?
    
    override func leaveTestView(completion: @escaping (Bool, ZIKRouteAction, Error?) -> Void) {
        XCTAssertNotNil(testRouter)
        testRouter?.removeRoute(configuring: { (config) in
            config.successHandler = {
                print("LeaveTestView succeed")
                self.leaveTestViewExpectation.fulfill()
            }
            config.errorHandler = { (_, _) in
                print("LeaveTestView failed")
                if type(of: self).allowLeaveTestViewFailing() {
                    self.leaveTestViewExpectation.fulfill()
                }
            }
            config.completionHandler = completion
        })
        strongTestRouter = nil
        strongRouter = nil
    }
    
    override func leaveTest() {
        if testRouter == nil || testRouter?.state == .unrouted || testRouter?.state == .removed {
            strongTestRouter = nil
            strongRouter = nil
            leaveTestViewExpectation.fulfill()
            leaveSourceView()
            return
        }
        leaveTestView { (_, _, _) in
            self.leaveSourceView()
        }
    }
    
    override func setUp() {
        super.setUp()
        self.routeType = .addAsChildViewController
    }
    
    override func tearDown() {
        super.tearDown()
        assert(testRouter == nil, "Didn't leave test view")
        self.testRouter = nil
        self.strongTestRouter = nil
    }
    
    func path(from source: UIViewController) ->ViewRoutePath {
        return ViewRoutePath.addAsChildViewController(from: source) { (destination, completion) in
            self.addChild(to: source.view, childView: destination.view, completion: completion)
        }
    }

    func configure(routeConfiguration config: ViewRouteConfig, source: ZIKViewRouteSource?) {
        config.animated = true
        config.routeType = self.routeType
    }
    
    func addChild(to parentView: UIView, childView: UIView, completion: @escaping () -> Void) {
        childView.frame = parentView.frame
        childView.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        UIView.animate(withDuration: 0.5, animations: {
            childView.backgroundColor = .red
            parentView.addSubview(childView)
            childView.transform = CGAffineTransform.identity
        }) { (finished) in
            completion()
        }
    }
    
    func testPerformWithPrepareDestination() {
        let expectation = self.expectation(description: "prepareDestination")
        enterTest { (source) in
            self.testRouter = Router.perform(
                to: RoutableView<AViewInput>(),
                path: self.path(from: source),
                configuring: { (config, _) in
                    self.configure(routeConfiguration: config.config.configuration, source: source)
                    config.prepareDestination = { destination in
                        destination.title = "test title"
                        expectation.fulfill()
                    }
                    config.successHandler = { destination in
                        XCTAssert(destination.title == "test title")
                        self.handle({
                            XCTAssert(self.router?.state == .routed)
                            self.leaveTest()
                        })
                    }
            })
        }
        waitForExpectations(timeout: 5, handler: { if let error = $0 {print(error)}})
    }
    
    func testPerformWithSuccessCompletionHandler() {
        let expectation = self.expectation(description: "completionHandler")
        enterTest { (source) in
            self.testRouter = Router.perform(
                to: RoutableView<AViewInput>(),
                path: self.path(from: source),
                configuring: { (config, _) in
                    self.configure(routeConfiguration: config.config.configuration, source: source)
                    config.completionHandler = { (success, destination, action, error) in
                        XCTAssertTrue(success)
                        XCTAssertNil(error)
                        expectation.fulfill()
                        self.handle({
                            XCTAssert(self.router?.state == .routed)
                            self.leaveTest()
                        })
                    }
            })
        }
        waitForExpectations(timeout: 5, handler: { if let error = $0 {print(error)}})
    }
    
    func testPerformWithErrorCompletionHandler() {
        let expectation = self.expectation(description: "completionHandler")
        enterTest { (source) in
            self.testRouter = Router.perform(
                to: RoutableView<AViewInput>(),
                path: .extensible(path: ZIKViewRoutePath(routeType: self.routeType, source: nil)),
                configuring: { (config, _) in
                    self.configure(routeConfiguration: config.config.configuration, source: source)
                    config.completionHandler = { (success, destination, action, error) in
                        XCTAssertFalse(success)
                        XCTAssertNotNil(error)
                        expectation.fulfill()
                        self.handle({
                            XCTAssert(self.router == nil || self.router?.state == .unrouted)
                            self.leaveTest()
                        })
                    }
            })
        }
        waitForExpectations(timeout: 5, handler: { if let error = $0 {print(error)}})
    }
    
    func testPerformWithSuccessCompletion() {
        let expectation = self.expectation(description: "completionHandler")
        enterTest { (source) in
            self.testRouter = Router.perform(
                to: RoutableView<AViewInput>(),
                path: self.path(from: source),
                completion: { (success, destination, action, error) in
                    XCTAssertTrue(success)
                    XCTAssertNil(error)
                    expectation.fulfill()
                    self.handle({
                        XCTAssert(self.router?.state == .routed)
                        self.leaveTest()
                    })
            })
        }
        waitForExpectations(timeout: 5, handler: { if let error = $0 {print(error)}})
    }
    
    func testPerformWithErrorCompletion() {
        let expectation = self.expectation(description: "completionHandler")
        enterTest { (source) in
            self.testRouter = Router.perform(
                to: RoutableView<AViewInput>(),
                path: .extensible(path: ZIKViewRoutePath(routeType: self.routeType, source: nil)),
                completion: { (success, destination, action, error) in
                    XCTAssertFalse(success)
                    XCTAssertNotNil(error)
                    expectation.fulfill()
                    self.handle({
                        XCTAssert(self.router == nil || self.router?.state == .unrouted)
                        self.leaveTest()
                    })
            })
        }
        waitForExpectations(timeout: 5, handler: { if let error = $0 {print(error)}})
    }
    
    func testPerformRouteWithSuccessCompletion() {
        let expectation = self.expectation(description: "completionHandler")
        expectation.assertForOverFulfill = true
        enterTest { (source) in
            self.testRouter = Router.perform(
                to: RoutableView<AViewInput>(),
                path: self.path(from: source),
                completion: { (success, destination, action, error) in
                    XCTAssertTrue(success)
                    XCTAssertNil(error)
                    self.handle({
                        XCTAssert(self.router?.state == .routed)
                        self.testRouter?.removeRoute(successHandler: {
                            XCTAssert(self.router?.state == .removed)
                            self.testRouter?.performRoute(completion: { (success, destination, action, error) in
                                XCTAssert(self.router?.state == .routed)
                                XCTAssertTrue(success)
                                XCTAssertNil(error)
                                expectation.fulfill()
                                self.leaveTest()
                            })
                        })
                    })
            })
        }
        waitForExpectations(timeout: 5, handler: { if let error = $0 {print(error)}})
    }
    
    func testPerformRouteWithErrorCompletion() {
        let expectation = self.expectation(description: "completionHandler")
        expectation.assertForOverFulfill = true
        enterTest { (source) in
            self.testRouter = Router.perform(
                to: RoutableView<AViewInput>(),
                path: self.path(from: source),
                completion: { (success, destination, action, error) in
                    XCTAssertTrue(success)
                    XCTAssertNil(error)
                    self.handle({
                        XCTAssert(self.router?.state == .routed)
                        XCTAssertTrue(self.router!.shouldRemoveBeforePerform())
                        self.testRouter?.performRoute(completion: { (success, destination, action, error) in
                            XCTAssert(self.router?.state == .routed)
                            XCTAssertFalse(success)
                            XCTAssertNotNil(error)
                            expectation.fulfill()
                            self.leaveTest()
                        })
                    })
            })
        }
        waitForExpectations(timeout: 5, handler: { if let error = $0 {print(error)}})
    }
    
    func testPerformWithSuccess() {
        let expectation = self.expectation(description: "successHandler")
        enterTest { (source) in
            self.testRouter = Router.perform(
                to: RoutableView<AViewInput>(),
                path: self.path(from: source),
                configuring: { (config, _) in
                    self.configure(routeConfiguration: config.config.configuration, source: source)
                    config.successHandler = { d in
                        expectation.fulfill()
                        self.handle({
                            XCTAssert(self.router?.state == .routed)
                            self.leaveTest()
                        })
                    }
            })
        }
        waitForExpectations(timeout: 5, handler: { if let error = $0 {print(error)}})
    }
    
    func testPerformWithPerformerSuccess() {
        let providerHandlerExpectation = self.expectation(description: "successHandler")
        providerHandlerExpectation.expectedFulfillmentCount = 2
        let performerHandlerExpectation = self.expectation(description: "performerSuccessHandler")
        performerHandlerExpectation.assertForOverFulfill = true
        enterTest { (source) in
            self.testRouter = Router.perform(
                to: RoutableView<AViewInput>(),
                path: self.path(from: source),
                configuring: { (config, _) in
                    self.configure(routeConfiguration: config.config.configuration, source: source)
                    config.successHandler = { d in
                        providerHandlerExpectation.fulfill()
                    }
                    config.performerSuccessHandler = { d in
                        performerHandlerExpectation.fulfill()
                        self.handle({
                            XCTAssert(self.router?.state == .routed)
                            self.testRouter?.removeRoute(successHandler: {
                                XCTAssert(self.router?.state == .removed)
                                self.testRouter?.performRoute(successHandler: { (d) in
                                    XCTAssert(self.router?.state == .routed)
                                    self.leaveTest()
                                })
                            })
                        })
                    }
            })
        }
        waitForExpectations(timeout: 5, handler: { if let error = $0 {print(error)}})
    }
    
    func testPerformWithError() {
        let providerHandlerExpectation = self.expectation(description: "errorHandler")
        let performerHandlerExpectation = self.expectation(description: "performerErrorHandler")
        enterTest { (source) in
            self.testRouter = Router.perform(
                to: RoutableView<AViewInput>(),
                path: .extensible(path: ZIKViewRoutePath(routeType: self.routeType, source: nil)),
                configuring: { (config, _) in
                    self.configure(routeConfiguration: config.config.configuration, source: source)
                    config.successHandler = { d in
                        XCTAssert(false, "successHandler should not be called")
                    }
                    config.performerSuccessHandler = { d in
                        XCTAssert(false, "performerSuccessHandler should not be called")
                    }
                    config.errorHandler = { (action, error) in
                        providerHandlerExpectation.fulfill()
                    }
                    config.performerErrorHandler = { (action, error) in
                        performerHandlerExpectation.fulfill()
                        self.handle({
                            XCTAssert(self.router == nil || self.router?.state == .unrouted)
                            self.leaveTest()
                        })
                    }
            })
        }
        waitForExpectations(timeout: 5, handler: { if let error = $0 {print(error)}})
    }
    
    func testPerformOnDestinationSuccess() {
        let providerHandlerExpectation = self.expectation(description: "errorHandler")
        let performerHandlerExpectation = self.expectation(description: "performerErrorHandler")
        let completionHandlerExpectation = self.expectation(description: "completionHandler")
        enterTest { (source) in
            let destination = Router.makeDestination(to: RoutableView<AViewInput>())
            self.testRouter = Router
                .to(RoutableView<AViewInput>())?
                .perform(
                    onDestination: destination!,
                    path: self.path(from: source),
                    configuring: { (config, _) in
                        self.configure(routeConfiguration: config.config.configuration, source: source)
                        config.successHandler = { d in
                            providerHandlerExpectation.fulfill()
                        }
                        config.performerSuccessHandler = { d in
                            performerHandlerExpectation.fulfill()
                        }
                        config.completionHandler = { (success, destination, action, error) in
                            completionHandlerExpectation.fulfill()
                            self.handle({
                                XCTAssert(self.router?.state == .routed)
                                self.leaveTest()
                            })
                        }
                        config.errorHandler = { (action, error) in
                            XCTAssert(false, "errorHandler should not be called")
                        }
                        config.performerErrorHandler = { (action, error) in
                            XCTAssert(false, "performerErrorHandler should not be called")
                        }
                })
        }
        waitForExpectations(timeout: 5, handler: { if let error = $0 {print(error)}})
    }
}

class ViewRouterPerformAddAsChildWithoutAnimationTests: ViewRouterPerformAddAsChildTests {
    override func configure(routeConfiguration config: ViewRouteConfig, source: ZIKViewRouteSource?) {
        super.configure(routeConfiguration: config, source: source)
        config.animated = false
    }
    
    override func addChild(to parentView: UIView, childView: UIView, completion: @escaping () -> Void) {
        childView.frame = parentView.frame
        parentView.addSubview(childView)
        completion()
    }
}
