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
    
    override func setUp() {
        super.setUp()
        self.routeType = .presentModally
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func configure(routeConfiguration config: ViewRouteConfig, source: ZIKViewRouteSource?) {
        config.animated = true
        config.routeType = self.routeType
    }
    
    func testPerformWithPrepareDestination() {
        let expectation = self.expectation(description: "prepareDestination")
        enterTest { (source) in
            self.router = Router.perform(
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
            })?.router
        }
        waitForExpectations(timeout: 5, handler: { if let error = $0 {print(error)}})
    }
    
    func testPerformWithSuccessCompletionHandler() {
        let expectation = self.expectation(description: "completionHandler")
        enterTest { (source) in
            self.router = Router.perform(
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
            })?.router
        }
        waitForExpectations(timeout: 5, handler: { if let error = $0 {print(error)}})
    }
    
    func testPerformWithErrorCompletionHandler() {
        let expectation = self.expectation(description: "completionHandler")
        enterTest { (source) in
            self.router = Router.perform(
                to: RoutableView<AViewInput>(),
                from: nil,
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
            })?.router
        }
        waitForExpectations(timeout: 5, handler: { if let error = $0 {print(error)}})
    }
    
    func testPerformWithSuccessCompletion() {
        let expectation = self.expectation(description: "completionHandler")
        enterTest { (source) in
            self.router = Router.perform(
                to: RoutableView<AViewInput>(),
                path: ViewRoutePath.presentModally(from: source),
                completion: { (success, destination, action, error) in
                    XCTAssertTrue(success)
                    XCTAssertNil(error)
                    expectation.fulfill()
                    self.handle({
                        XCTAssert(self.router?.state == .routed)
                        self.leaveTest()
                    })
            })?.router
        }
        waitForExpectations(timeout: 5, handler: { if let error = $0 {print(error)}})
    }
}
