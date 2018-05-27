//
//  ViewRouterComposedTypeTests.swift
//  ZRouterTests
//
//  Created by zuik on 2018/5/14.
//  Copyright © 2018 zuik. All rights reserved.
//

import XCTest
import UIKit
import ZRouter

class ViewRouterComposedTypeTests: XCTestCase {
    
    typealias AViewControllerInput = UIViewController & AViewInput
    
    weak var router: DestinationViewRouter<UIViewController & AViewInput>? {
        willSet {
            strongRouter = newValue
        }
    }
    private var strongRouter: DestinationViewRouter<UIViewController & AViewInput>?
    var leaveTestExpectation: XCTestExpectation?
    
    func enterTest() {
        leaveTestExpectation = self.expectation(description: "Leave test")
    }
    
    func leaveTest() {
        strongRouter = nil
        leaveTestExpectation?.fulfill()
    }
    
    func handle(_ block: @escaping () -> Void) {
        DispatchQueue.main.async {
            block()
        }
    }
    
    override func setUp() {
        super.setUp()
        TestRouteRegistry.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
        XCTAssert(self.router == nil, "Test router is not released")
        TestConfig.routeShouldFail = false
    }
    
    func testPerform() {
        let providerExpectation = self.expectation(description: "successHandler")
        providerExpectation.expectedFulfillmentCount = 2
        let performerExpectation = self.expectation(description: "performerSuccessHandler")
        enterTest()
        self.router = Router.perform(to: RoutableView<UIViewController & AViewInput>(), path: .makeDestination, configuring: { (config, prepareModule) in
            config.prepareDestination = { destination in
                destination.title = "test title"
            }
            config.successHandler = { destination in
                XCTAssertNotNil(destination)
                XCTAssert(destination.title == "test title")
                providerExpectation.fulfill()
            }
            config.performerSuccessHandler = { destination in
                XCTAssertNotNil(destination)
                XCTAssert(destination.title == "test title")
                performerExpectation.fulfill()
                self.handle({
                    XCTAssert(self.router?.state == .routed)
                    self.router?.performRoute(successHandler: { (destination) in
                        XCTAssert(self.router?.state == .routed)
                        self.leaveTest()
                    })
                })
            }
            config.errorHandler = { (action, error) in
                XCTAssert(false, "errorHandler should not be called")
            }
            config.performerErrorHandler = { (action, error) in
                XCTAssert(false, "performerErrorHandler should not be called")
            }
        })
        waitForExpectations(timeout: 5, handler: { if let error = $0 {print(error)}})
    }
    
    func testMakeDestination() {
        let providerExpectation = self.expectation(description: "successHandler")
        let performerExpectation = self.expectation(description: "performerSuccessHandler")
        let completionHandlerExpectation = self.expectation(description: "completionHandler")
        XCTAssertTrue(Router.to(RoutableView<UIViewController & AViewInput>())!.canMakeDestination)
        let destination = Router.makeDestination(to: RoutableView<UIViewController & AViewInput>(), configuring: { (config, prepareModule) in
            config.prepareDestination = { destination in
                destination.title = "test title"
            }
            config.successHandler = { d in
                providerExpectation.fulfill()
            }
            config.performerSuccessHandler = { d in
                performerExpectation.fulfill()
            }
            config.errorHandler = { (action, error) in
                XCTAssert(false, "errorHandler should not be called")
            }
            config.performerErrorHandler = { (action, error) in
                XCTAssert(false, "performerErrorHandler should not be called")
            }
            config.completionHandler = { (success, destination, action, error) in
                XCTAssertTrue(success)
                XCTAssert(destination != nil)
                completionHandlerExpectation.fulfill()
            }
        })
        XCTAssertNotNil(destination)
        XCTAssert(destination?.title == "test title")
        waitForExpectations(timeout: 5, handler: { if let error = $0 {print(error)}})
    }
    
    func testPrepareDestination() {
        let providerExpectation = self.expectation(description: "successHandler")
        let performerExpectation = self.expectation(description: "performerSuccessHandler")
        let completionHandlerExpectation = self.expectation(description: "completionHandler")
        enterTest()
        let destination = AViewController()
        self.router = Router.to(RoutableView<UIViewController & AViewInput>())?.prepare(destination: destination, configuring: { (config, prepareModule) in
            config.prepareDestination = { destination in
                destination.title = "test title"
            }
            config.successHandler = { d in
                XCTAssert(d.title == "test title")
                providerExpectation.fulfill()
            }
            config.performerSuccessHandler = { d in
                performerExpectation.fulfill()
            }
            config.errorHandler = { (action, error) in
                XCTAssert(false, "errorHandler should not be called")
            }
            config.performerErrorHandler = { (action, error) in
                XCTAssert(false, "performerErrorHandler should not be called")
            }
            config.completionHandler = { (success, destination, action, error) in
                XCTAssertTrue(success)
                XCTAssert(destination != nil)
                completionHandlerExpectation.fulfill()
                self.handle({
                    self.leaveTest()
                })
            }
        })
        waitForExpectations(timeout: 5, handler: { if let error = $0 {print(error)}})
    }
}
