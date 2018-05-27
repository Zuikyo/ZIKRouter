//
//  ViewModuleRouterPerformTests.swift
//  ZRouterTests
//
//  Created by zuik on 2018/4/28.
//  Copyright © 2018 zuik. All rights reserved.
//

import XCTest
import ZRouter

class SubviewModuleRouterPerformTests: XCTestCase {
    weak var router: ModuleViewRouter<BSubviewModuleInput>? {
        willSet {
            strongRouter = newValue
        }
    }
    private var strongRouter: ModuleViewRouter<BSubviewModuleInput>?
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
    
    func testPerformWithPrepareDestination() {
        let expectation = self.expectation(description: "prepareDestination")
        enterTest()
        self.router = Router.perform(to: RoutableViewModule<BSubviewModuleInput>(), path: .makeDestination, configuring: { (config, prepareModule) in
            prepareModule({ module in
                module.title = "test title"
                expectation.fulfill()
                self.handle({
                    self.leaveTest()
                })
            })
        })
        waitForExpectations(timeout: 5, handler: { if let error = $0 {print(error)}})
    }
    
    func testPerformWithSuccessCompletionHandler() {
        let expectation = self.expectation(description: "completionHandler")
        enterTest()
        self.router = Router.perform(to: RoutableViewModule<BSubviewModuleInput>(), path: .makeDestination, configuring: { (config, prepareModule) in
            config.completionHandler = { (success, destination, action, error) in
                XCTAssertTrue(success)
                XCTAssertNotNil(destination)
                XCTAssert(destination is BSubviewInput)
                expectation.fulfill()
                self.handle({
                    self.leaveTest()
                })
            }
        })
        waitForExpectations(timeout: 5, handler: { if let error = $0 {print(error)}})
    }
    
    func testPerformWithErrorCompletionHandler() {
        let expectation = self.expectation(description: "completionHandler")
        TestConfig.routeShouldFail = true
        enterTest()
        self.router = Router.perform(to: RoutableViewModule<BSubviewModuleInput>(), path: .makeDestination, configuring: { (config, prepareModule) in
            config.completionHandler = { (success, destination, action, error) in
                XCTAssertFalse(success)
                XCTAssertNil(destination)
                XCTAssertNotNil(error)
                expectation.fulfill()
                self.handle({
                    self.leaveTest()
                })
            }
        })
        waitForExpectations(timeout: 5, handler: { if let error = $0 {print(error)}})
    }
    
    func testPerformWithSuccessCompletion() {
        let expectation = self.expectation(description: "completionHandler")
        enterTest()
        self.router = Router.perform(to: RoutableViewModule<BSubviewModuleInput>(), path: .makeDestination, completion: { (success, destination, action, error) in
            XCTAssertTrue(success)
            XCTAssertNotNil(destination)
            XCTAssert(destination is BSubviewInput)
            expectation.fulfill()
            self.handle({
                self.leaveTest()
            })
        })
        waitForExpectations(timeout: 5, handler: { if let error = $0 {print(error)}})
    }
    
    func testPerformWithErrorCompletion() {
        let expectation = self.expectation(description: "completionHandler")
        TestConfig.routeShouldFail = true
        enterTest()
        self.router = Router.perform(to: RoutableViewModule<BSubviewModuleInput>(), path: .makeDestination, completion: { (success, destination, action, error) in
            XCTAssertFalse(success)
            XCTAssertNil(destination)
            XCTAssertNotNil(error)
            expectation.fulfill()
            self.handle({
                self.leaveTest()
            })
        })
        waitForExpectations(timeout: 5, handler: { if let error = $0 {print(error)}})
    }
    
    func testPerformRouteWithSuccessCompletion() {
        let expectation = self.expectation(description: "completionHandler")
        enterTest()
        self.router = Router.perform(to: RoutableViewModule<BSubviewModuleInput>(), path: .makeDestination, completion: { (success, destination, action, error) in
            XCTAssertTrue(success)
            XCTAssertNotNil(destination)
            XCTAssert(destination is BSubviewInput)
            self.handle({
                XCTAssert(self.router?.state == .routed)
                self.router?.performRoute(completion: { (success, destination, action, error) in
                    XCTAssertTrue(success)
                    XCTAssertNotNil(destination)
                    expectation.fulfill()
                    self.leaveTest()
                })
                
            })
        })
        waitForExpectations(timeout: 5, handler: { if let error = $0 {print(error)}})
    }
    
    func testPerformRouteWithErrorCompletion() {
        let expectation = self.expectation(description: "completionHandler")
        TestConfig.routeShouldFail = false
        enterTest()
        self.router = Router.perform(to: RoutableViewModule<BSubviewModuleInput>(), path: .makeDestination, completion: { (success, destination, action, error) in
            XCTAssertTrue(success)
            XCTAssertNotNil(destination)
            XCTAssert(destination is BSubviewInput)
            self.handle({
                XCTAssert(self.router?.state == .routed)
                TestConfig.routeShouldFail = true
                self.router?.performRoute(completion: { (success, destination, action, error) in
                    XCTAssertFalse(success)
                    XCTAssertNil(destination)
                    XCTAssertNotNil(error)
                    expectation.fulfill()
                    self.leaveTest()
                })
            })
        })
        waitForExpectations(timeout: 5, handler: { if let error = $0 {print(error)}})
    }
    
    func testPerformWithSuccess() {
        let expectation = self.expectation(description: "successHandler")
        enterTest()
        self.router = Router.perform(to: RoutableViewModule<BSubviewModuleInput>(), path: .makeDestination, configuring: { (config, prepareModule) in
            prepareModule({ module in
                module.title = "test title"
            })
            config.successHandler = { d in
                let destination = d as? BSubviewInput
                XCTAssertNotNil(destination)
                XCTAssert(destination?.title == "test title")
                expectation.fulfill()
                self.handle({
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
        waitForExpectations(timeout: 5, handler: { if let error = $0 {print(error)}})
    }
    
    func testPerformWithPerformerSuccess() {
        let providerExpectation = self.expectation(description: "successHandler")
        providerExpectation.expectedFulfillmentCount = 2
        let performerExpectation = self.expectation(description: "performerSuccessHandler")
        enterTest()
        self.router = Router.perform(to: RoutableViewModule<BSubviewModuleInput>(), path: .makeDestination, configuring: { (config, prepareModule) in
            prepareModule({ module in
                module.title = "test title"
            })
            config.successHandler = { d in
                let destination = d as? BSubviewInput
                XCTAssertNotNil(destination)
                XCTAssert(destination?.title == "test title")
                providerExpectation.fulfill()
            }
            config.performerSuccessHandler = { d in
                let destination = d as? BSubviewInput
                XCTAssertNotNil(destination)
                XCTAssert(destination?.title == "test title")
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
    
    func testPerformWithError() {
        let providerExpectation = self.expectation(description: "errorHandler")
        let performerExpectation = self.expectation(description: "performerErrorHandler")
        TestConfig.routeShouldFail = true
        enterTest()
        self.router = Router.perform(to: RoutableViewModule<BSubviewModuleInput>(), path: .makeDestination, configuring: { (config, prepareModule) in
            prepareModule({ module in
                module.title = "test title"
            })
            config.successHandler = { d in
                XCTAssert(false, "errorHandler should not be called")
            }
            config.performerSuccessHandler = { d in
                XCTAssert(false, "performerErrorHandler should not be called")
            }
            config.errorHandler = { (action, error) in
                providerExpectation.fulfill()
            }
            config.performerErrorHandler = { (action, error) in
                performerExpectation.fulfill()
                self.handle({
                    XCTAssert(self.router == nil || self.router?.state == .unrouted)
                    self.leaveTest()
                })
            }
        })
        waitForExpectations(timeout: 2, handler: { if let error = $0 {print(error)}})
    }
}
