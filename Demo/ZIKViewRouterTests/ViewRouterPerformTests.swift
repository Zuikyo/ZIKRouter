//
//  ZIKViewRouterPerformTests.swift
//  ZIKViewRouterTests
//
//  Created by zuik on 2018/4/23.
//  Copyright © 2018 zuik. All rights reserved.
//

import XCTest
import ZRouter

extension ZIKViewRouterTestCase {
    func path(from source: UIViewController) ->ViewRoutePath {
        var routeSource: ZIKViewRouteSource? = source
        if self.routeType == .addAsSubview {
            routeSource = source.view
        }
        let path = ViewRoutePath(rawValue: (self.routeType, routeSource))
        XCTAssertNotNil(path)
        return path!
    }
}

class ViewRouterPerformTests: ZIKViewRouterTestCase {
    
    weak var testRouter: DestinationViewRouter<AViewInput>? {
        willSet {
            self.router = newValue?.router
            self.strongTestRouter = newValue
        }
    }
    var strongTestRouter: DestinationViewRouter<AViewInput>?
    
    override func leaveTestView(completion: @escaping (Bool, ZIKRouteAction, Error?) -> Void) {
        XCTAssertNotNil(testRouter)
        testRouter?.removeRoute(configuring: { (config, _) in
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
        self.routeType = .presentModally
    }
    
    override func tearDown() {
        super.tearDown()
        assert(testRouter == nil, "Didn't leave test view")
        self.testRouter = nil
        self.strongTestRouter = nil
    }
    
    func configure(routeConfiguration config: ViewRouteConfig, source: ZIKViewRouteSource?) {
        config.animated = true
        config.routeType = self.routeType
    }
    
    func testPerformWithPrepareDestination() {
        let expectation = self.expectation(description: "prepareDestination")
        enterTest { (source) in
            self.testRouter = Router.perform(
                to: RoutableView<AViewInput>(),
                path: self.path(from: source),
                configuring: { (config, prepareDest, _) in
                    self.configure(routeConfiguration: config, source: source)
                    prepareDest({ destination in
                        destination.title = "test title"
                        expectation.fulfill()
                    })
                    config.successHandler = { destination in
                        XCTAssert(destination is AViewInput)
                        XCTAssert((destination as! AViewInput).title == "test title")
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
                configuring: { (config, prepareDest, _) in
                    self.configure(routeConfiguration: config, source: source)
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
                configuring: { (config, prepareDest, _) in
                    self.configure(routeConfiguration: config, source: source)
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
        waitForExpectations(timeout: 500, handler: { if let error = $0 {print(error)}})
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
                            XCTAssertFalse(success)
                            XCTAssertNotNil(error)
                            expectation.fulfill()
                            self.leaveTest()
                        })
                    })
            })
        }
        waitForExpectations(timeout: 500, handler: { if let error = $0 {print(error)}})
    }
}
