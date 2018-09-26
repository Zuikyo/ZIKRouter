//
//  ViewRouterMakeDestinationTests.swift
//  ZRouterTests
//
//  Created by zuik on 2018/4/28.
//  Copyright © 2018 zuik. All rights reserved.
//

import XCTest
import ZRouter

class ViewRouterMakeDestinationTests: XCTestCase {
    weak var router: DestinationViewRouter<AViewInput>? {
        willSet {
            strongRouter = newValue
        }
    }
    private var strongRouter: DestinationViewRouter<AViewInput>?
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
    
    func testMakeDestination() {
        XCTAssertTrue(Router.to(RoutableView<AViewInput>())!.canMakeDestination)
        let destination = Router.makeDestination(to: RoutableView<AViewInput>())
        XCTAssertNotNil(destination)
    }
    
    func testMakeDestinationWithPreparation() {
        XCTAssertTrue(Router.to(RoutableView<AViewInput>())!.canMakeDestination)
        let destination = Router.makeDestination(to: RoutableView<AViewInput>(), preparation: { (destination) in
            destination.viewTitle = "test title"
        })
        XCTAssertNotNil(destination)
        XCTAssert(destination?.viewTitle == "test title")
    }
    
    func testMakeDestinationWithConfiguring() {
        let providerExpectation = self.expectation(description: "successHandler")
        let performerExpectation = self.expectation(description: "performerSuccessHandler")
        let completionHandlerExpectation = self.expectation(description: "completionHandler")
        XCTAssertTrue(Router.to(RoutableView<AViewInput>())!.canMakeDestination)
        let destination = Router.makeDestination(to: RoutableView<AViewInput>(), configuring: { (config, prepareModule) in
            config.prepareDestination = { destination in
                destination.viewTitle = "test title"
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
        XCTAssert(destination?.viewTitle == "test title")
        waitForExpectations(timeout: 5, handler: { if let error = $0 {print(error)}})
    }
    
    func testSwiftAdapter() {
        let providerExpectation = self.expectation(description: "successHandler")
        let performerExpectation = self.expectation(description: "performerSuccessHandler")
        let completionHandlerExpectation = self.expectation(description: "completionHandler")
        XCTAssertTrue(Router.to(RoutableView<AViewInputAdapter>())!.canMakeDestination)
        let destination = Router.makeDestination(to: RoutableView<AViewInput>(), configuring: { (config, prepareModule) in
            config.prepareDestination = { destination in
                destination.viewTitle = "test title"
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
        XCTAssert(destination?.viewTitle == "test title")
        waitForExpectations(timeout: 5, handler: { if let error = $0 {print(error)}})
    }
    
    func testObjcAdapter() {
        let providerExpectation = self.expectation(description: "successHandler")
        let performerExpectation = self.expectation(description: "performerSuccessHandler")
        let completionHandlerExpectation = self.expectation(description: "completionHandler")
        XCTAssertTrue(Router.to(RoutableView<AViewInputObjcAdapter>())!.canMakeDestination)
        let destination = Router.makeDestination(to: RoutableView<AViewInput>(), configuring: { (config, prepareModule) in
            config.prepareDestination = { destination in
                destination.viewTitle = "test title"
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
        XCTAssert(destination?.viewTitle == "test title")
        waitForExpectations(timeout: 5, handler: { if let error = $0 {print(error)}})
    }
    
}
