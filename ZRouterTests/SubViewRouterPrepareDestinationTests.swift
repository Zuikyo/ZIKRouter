//
//  ViewRouterPrepareDestinationTests.swift
//  ZRouterTests
//
//  Created by zuik on 2018/4/28.
//  Copyright © 2018 zuik. All rights reserved.
//

import XCTest
import ZRouter

class ViewRouterPrepareDestinationTests: XCTestCase {
    weak var router: DestinationViewRouter<BSubviewInput>? {
        willSet {
            strongRouter = newValue
        }
    }
    private var strongRouter: DestinationViewRouter<BSubviewInput>?
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
    
    func testPrepareDestinationWithSuccessHandler() {
        let providerExpectation = self.expectation(description: "successHandler")
        let performerExpectation = self.expectation(description: "performerSuccessHandler")
        let completionHandlerExpectation = self.expectation(description: "completionHandler")
        enterTest()
        let destination = BSubview()
        self.router = Router.to(RoutableView<BSubviewInput>())?.prepare(destination: destination, configuring: { (config, prepareModule) in
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
