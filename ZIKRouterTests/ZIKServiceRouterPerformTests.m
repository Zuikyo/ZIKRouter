//
//  ZIKServiceRouterPerformTests.m
//  ZIKRouterTests
//
//  Created by zuik on 2018/4/18.
//  Copyright © 2018 zuik. All rights reserved.
//

#import "ZIKRouterTestCase.h"
@import ZIKRouter;
#import "AServiceInput.h"
#import "TestConfig.h"

@interface ZIKServiceRouterPerformTests : ZIKRouterTestCase

@end

@implementation ZIKServiceRouterPerformTests

- (void)setUp {
    [super setUp];
    
}

- (void)tearDown {
    [super tearDown];
    
}

- (void)testPerformWithPrepareDestination {
    XCTestExpectation *expectation = [self expectationWithDescription:@"prepareDestination"];
    @autoreleasepool {
        [self enterTest];
        self.router = [ZIKRouterToService(AServiceInput) performWithConfiguring:^(ZIKPerformRouteConfiguration * _Nonnull config) {
            config.prepareDestination = ^(id _Nonnull destination) {
                self.destination = destination;
                XCTAssertNotNil(destination);
                XCTAssertTrue([destination conformsToProtocol:@protocol(AServiceInput)]);
                [expectation fulfill];
                [self handle:^{
                    [self leaveTest];
                }];
            };
        }];
    }
    
    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
        !error? : NSLog(@"%@", error);
    }];
}

- (void)testPerformWithSuccessCompletionHandler {
    XCTestExpectation *expectation = [self expectationWithDescription:@"completionHandler"];
    @autoreleasepool {
        [self enterTest];
        self.router = [ZIKRouterToService(AServiceInput) performWithConfiguring:^(ZIKPerformRouteConfiguration * _Nonnull config) {
            config.completionHandler = ^(BOOL success, id  _Nullable destination, ZIKRouteAction  _Nonnull routeAction, NSError * _Nullable error) {
                self.destination = destination;
                XCTAssertTrue(success);
                XCTAssertNil(error);
                [expectation fulfill];
                [self handle:^{
                    XCTAssert(self.router.state == ZIKRouterStateRouted);
                    [self leaveTest];
                }];
            };
        }];
    }
    
    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
        !error? : NSLog(@"%@", error);
    }];
}

- (void)testPerformWithErrorCompletionHandler {
    XCTestExpectation *expectation = [self expectationWithDescription:@"completionHandler"];
    @autoreleasepool {
        TestConfig.routeShouldFail = YES;
        [self enterTest];
        self.router = [ZIKRouterToService(AServiceInput) performWithConfiguring:^(ZIKPerformRouteConfiguration * _Nonnull config) {
            config.completionHandler = ^(BOOL success, id  _Nullable destination, ZIKRouteAction  _Nonnull routeAction, NSError * _Nullable error) {
                XCTAssertFalse(success);
                XCTAssertNotNil(error);
                [expectation fulfill];
                [self handle:^{
                    XCTAssert(self.router == nil || self.router.state == ZIKRouterStateUnrouted);
                    [self leaveTest];
                }];
            };
        }];
    }
    
    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
        !error? : NSLog(@"%@", error);
    }];
}

- (void)testPerformWithSuccessCompletion {
    XCTestExpectation *expectation = [self expectationWithDescription:@"completionHandler"];
    @autoreleasepool {
        [self enterTest];
        self.router = [ZIKRouterToService(AServiceInput) performWithCompletion:^(BOOL success, id<AServiceInput>  _Nullable destination, ZIKRouteAction  _Nonnull routeAction, NSError * _Nullable error) {
            self.destination = destination;
            XCTAssertTrue(success);
            XCTAssertNil(error);
            [expectation fulfill];
            [self handle:^{
                XCTAssert(self.router.state == ZIKRouterStateRouted);
                [self leaveTest];
            }];
        }];
    }
    
    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
        !error? : NSLog(@"%@", error);
    }];
}

- (void)testPerformWithErrorCompletion {
    XCTestExpectation *expectation = [self expectationWithDescription:@"completionHandler"];
    @autoreleasepool {
        TestConfig.routeShouldFail = YES;
        [self enterTest];
        self.router = [ZIKRouterToService(AServiceInput) performWithCompletion:^(BOOL success, id<AServiceInput>  _Nullable destination, ZIKRouteAction  _Nonnull routeAction, NSError * _Nullable error) {
            XCTAssertFalse(success);
            XCTAssertNotNil(error);
            [expectation fulfill];
            [self handle:^{
                XCTAssert(self.router == nil || self.router.state == ZIKRouterStateUnrouted);
                [self leaveTest];
            }];
        }];
    }
    
    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
        !error? : NSLog(@"%@", error);
    }];
}

- (void)testPerformWithPreparation {
    XCTestExpectation *expectation = [self expectationWithDescription:@"preparation"];
    @autoreleasepool {
        [self enterTest];
        self.router = [ZIKRouterToService(AServiceInput) performWithPreparation:^(id<AServiceInput>  _Nonnull destination) {
            XCTAssert(destination);
            [expectation fulfill];
            [self handle:^{
                XCTAssert(self.router.state == ZIKRouterStateRouted);
                [self leaveTest];
            }];
        }];
    }
    
    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
        !error? : NSLog(@"%@", error);
    }];
}

- (void)testPerformRouteWithSuccessCompletion {
    XCTestExpectation *expectation = [self expectationWithDescription:@"completionHandler"];
    expectation.assertForOverFulfill = YES;
    @autoreleasepool {
        [self enterTest];
        self.router = [ZIKRouterToService(AServiceInput) performWithCompletion:^(BOOL success, id<AServiceInput>  _Nullable destination, ZIKRouteAction  _Nonnull routeAction, NSError * _Nullable error) {
            XCTAssertTrue(success);
            XCTAssertNil(error);
            
            [self handle:^{
                XCTAssert(self.router.state == ZIKRouterStateRouted);
                [self.router performRouteWithCompletion:^(BOOL success, id  _Nullable destination, ZIKRouteAction  _Nonnull routeAction, NSError * _Nullable error) {
                    self.destination = destination;
                    XCTAssert(self.router.state == ZIKRouterStateRouted);
                    XCTAssertTrue(success);
                    XCTAssertNil(error);
                    [expectation fulfill];
                    [self leaveTest];
                }];
            }];
        }];
    }
    
    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
        !error? : NSLog(@"%@", error);
    }];
}

- (void)testPerformRouteWithErrorCompletion {
    XCTestExpectation *expectation = [self expectationWithDescription:@"completionHandler"];
    expectation.assertForOverFulfill = YES;
    @autoreleasepool {
        TestConfig.routeShouldFail = NO;
        [self enterTest];
        self.router = [ZIKRouterToService(AServiceInput) performWithCompletion:^(BOOL success, id<AServiceInput>  _Nullable destination, ZIKRouteAction  _Nonnull routeAction, NSError * _Nullable error) {
            XCTAssertTrue(success);
            
            [self handle:^{
                XCTAssert(self.router.state == ZIKRouterStateRouted);
                TestConfig.routeShouldFail = YES;
                [self.router performRouteWithCompletion:^(BOOL success, id  _Nullable destination, ZIKRouteAction  _Nonnull routeAction, NSError * _Nullable error) {
                    XCTAssert(self.router.state == ZIKRouterStateRouted);
                    XCTAssertFalse(success);
                    XCTAssertNotNil(error);
                    [expectation fulfill];
                    [self leaveTest];
                }];
            }];
            
        }];
    }
    
    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
        !error? : NSLog(@"%@", error);
    }];
}

- (void)testPerformWithSuccess {
    XCTestExpectation *expectation = [self expectationWithDescription:@"successHandler"];
    @autoreleasepool {
        [self enterTest];
        self.router = [ZIKRouterToService(AServiceInput) performWithConfiguring:^(ZIKPerformRouteConfiguration * _Nonnull config) {
            config.successHandler = ^(id  _Nonnull destination) {
                self.destination = destination;
                XCTAssertNotNil(destination);
                [expectation fulfill];
                [self handle:^{
                    XCTAssert(self.router.state == ZIKRouterStateRouted);
                    [self leaveTest];
                }];
            };
        }];
    }
    
    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
        !error? : NSLog(@"%@", error);
    }];
}

- (void)testPerformWithPerformerSuccess {
    XCTestExpectation *successHandlerExpectation = [self expectationWithDescription:@"successHandler"];
    successHandlerExpectation.expectedFulfillmentCount = 2;
    XCTestExpectation *performerSuccessHandlerExpectation = [self expectationWithDescription:@"performerSuccessHandler once"];
    performerSuccessHandlerExpectation.assertForOverFulfill = YES;
    @autoreleasepool {
        [self enterTest];
        self.router = [ZIKRouterToService(AServiceInput) performWithConfiguring:^(ZIKPerformRouteConfiguration * _Nonnull config) {
            config.successHandler = ^(id  _Nonnull destination) {
                XCTAssertNotNil(destination);
                [successHandlerExpectation fulfill];
            };
            config.performerSuccessHandler = ^(id  _Nonnull destination) {
                self.destination = destination;
                XCTAssertNotNil(destination);
                [performerSuccessHandlerExpectation fulfill];
                
                [self handle:^{
                    XCTAssert(self.router.state == ZIKRouterStateRouted);
                    [self.router performRouteWithSuccessHandler:^(id  _Nonnull destination) {
                        XCTAssert(self.router.state == ZIKRouterStateRouted);
                        XCTAssertNotNil(destination);
                        [self leaveTest];
                    } errorHandler:^(ZIKRouteAction  _Nonnull routeAction, NSError * _Nonnull error) {
                        
                    }];
                }];
                
            };
        }];
    }
    
    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
        !error? : NSLog(@"%@", error);
    }];
}

- (void)testPerformWithError {
    XCTestExpectation *providerErrorExpectation = [self expectationWithDescription:@"providerErrorHandler"];
    XCTestExpectation *performerErrorExpectation = [self expectationWithDescription:@"performerErrorHandler"];
    @autoreleasepool {
        TestConfig.routeShouldFail = YES;
        [self enterTest];
        self.router = [ZIKRouterToService(AServiceInput) performWithConfiguring:^(ZIKPerformRouteConfiguration * _Nonnull config) {
            config.successHandler = ^(id  _Nonnull destination) {
                XCTAssert(NO, @"successHandler should not be called");
            };
            config.performerSuccessHandler = ^(id  _Nonnull destination) {
                XCTAssert(NO, @"successHandler should not be called");
            };
            config.errorHandler = ^(ZIKRouteAction  _Nonnull routeAction, NSError * _Nonnull error) {
                XCTAssertNotNil(error);
                [providerErrorExpectation fulfill];
            };
            config.performerErrorHandler = ^(ZIKRouteAction  _Nonnull routeAction, NSError * _Nonnull error) {
                XCTAssertNotNil(error);
                [performerErrorExpectation fulfill];
                [self handle:^{
                    XCTAssert(self.router == nil || self.router.state == ZIKRouterStateUnrouted);
                    [self leaveTest];
                }];
            };
        }];
    }
    
    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
        !error? : NSLog(@"%@", error);
    }];
}

#pragma mark Strict

- (void)testStrictPerformWithPrepareDestination {
    XCTestExpectation *expectation = [self expectationWithDescription:@"prepareDestination"];
    @autoreleasepool {
        [self enterTest];
        self.router = [ZIKRouterToService(AServiceInput)
                       performWithStrictConfiguring:^(ZIKPerformRouteStrictConfiguration<id<AServiceInput>> *config, ZIKPerformRouteConfiguration * _Nonnull module) {
                           config.prepareDestination = ^(id<AServiceInput>  _Nonnull destination) {
                               destination.title = @"test title";
                           };
                           config.successHandler = ^(id<AServiceInput>  _Nonnull destination) {
                               self.destination = destination;
                               XCTAssertNotNil(destination);
                               XCTAssert([destination.title isEqualToString:@"test title"]);
                               [expectation fulfill];
                               [self handle:^{
                                   XCTAssert(self.router.state == ZIKRouterStateRouted);
                                   [self leaveTest];
                               }];
                               
                           };
                       }];
    }
    
    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
        !error? : NSLog(@"%@", error);
    }];
}

- (void)testStrictPerformWithSuccessCompletionHandler {
    XCTestExpectation *expectation = [self expectationWithDescription:@"completionHandler"];
    @autoreleasepool {
        [self enterTest];
        self.router = [ZIKRouterToService(AServiceInput)
                       performWithStrictConfiguring:^(ZIKPerformRouteStrictConfiguration<id<AServiceInput>> *config, ZIKPerformRouteConfiguration * _Nonnull module) {
                           config.completionHandler = ^(BOOL success, id<AServiceInput> _Nullable destination, ZIKRouteAction  _Nonnull routeAction, NSError * _Nullable error) {
                               self.destination = destination;
                               XCTAssertTrue(success);
                               XCTAssertNil(error);
                               [expectation fulfill];
                               [self handle:^{
                                   XCTAssert(self.router.state == ZIKRouterStateRouted);
                                   [self leaveTest];
                               }];
                           };
                       }];
    }
    
    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
        !error? : NSLog(@"%@", error);
    }];
}

- (void)testStrictPerformWithErrorCompletionHandler {
    XCTestExpectation *expectation = [self expectationWithDescription:@"completionHandler"];
    @autoreleasepool {
        TestConfig.routeShouldFail = YES;
        [self enterTest];
        self.router = [ZIKRouterToService(AServiceInput)
                       performWithStrictConfiguring:^(ZIKPerformRouteStrictConfiguration<id<AServiceInput>> *config, ZIKPerformRouteConfiguration * _Nonnull module) {
                           config.completionHandler = ^(BOOL success, id<AServiceInput> _Nullable destination, ZIKRouteAction  _Nonnull routeAction, NSError * _Nullable error) {
                               self.destination = destination;
                               XCTAssertFalse(success);
                               XCTAssertNotNil(error);
                               XCTAssert(self.router == nil || self.router.state == ZIKRouterStateUnrouted);
                               [expectation fulfill];
                               [self handle:^{
                                   [self leaveTest];
                               }];
                           };
                       }];
    }
    
    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
        !error? : NSLog(@"%@", error);
    }];
}

- (void)testStrictPerformWithSuccess {
    XCTestExpectation *expectation = [self expectationWithDescription:@"successHandler"];
    @autoreleasepool {
        [self enterTest];
        self.router = [ZIKRouterToService(AServiceInput)
                       performWithStrictConfiguring:^(ZIKPerformRouteStrictConfiguration<id<AServiceInput>> *config, ZIKPerformRouteConfiguration * _Nonnull module) {
                           config.successHandler = ^(id<AServiceInput> _Nonnull destination) {
                               self.destination = destination;
                               XCTAssertNotNil(destination);
                               [expectation fulfill];
                               [self handle:^{
                                   XCTAssert(self.router.state == ZIKRouterStateRouted);
                                   [self leaveTest];
                               }];
                           };
                       }];
    }
    
    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
        !error? : NSLog(@"%@", error);
    }];
}

- (void)testStrictPerformWithPerformerSuccess {
    XCTestExpectation *successHandlerExpectation = [self expectationWithDescription:@"successHandler"];
    successHandlerExpectation.expectedFulfillmentCount = 2;
    XCTestExpectation *performerSuccessHandlerExpectation = [self expectationWithDescription:@"performerSuccessHandler once"];
    performerSuccessHandlerExpectation.assertForOverFulfill = YES;
    @autoreleasepool {
        [self enterTest];
        self.router = [ZIKRouterToService(AServiceInput)
                       performWithStrictConfiguring:^(ZIKPerformRouteStrictConfiguration<id<AServiceInput>> *config, ZIKPerformRouteConfiguration * _Nonnull module) {
                           config.successHandler = ^(id<AServiceInput>  _Nonnull destination) {
                               XCTAssertNotNil(destination);
                               [successHandlerExpectation fulfill];
                           };
                           config.performerSuccessHandler = ^(id<AServiceInput>  _Nonnull destination) {
                               self.destination = destination;
                               XCTAssertNotNil(destination);
                               [performerSuccessHandlerExpectation fulfill];
                               
                               [self handle:^{
                                   [self.router performRouteWithSuccessHandler:^(id<AServiceInput>  _Nonnull destination) {
                                       XCTAssert(self.router.state == ZIKRouterStateRouted);
                                       XCTAssertNotNil(destination);
                                       [self leaveTest];
                                   } errorHandler:^(ZIKRouteAction  _Nonnull routeAction, NSError * _Nonnull error) {
                                       
                                   }];
                               }];
                               
                           };
                       }];
    }
    
    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
        !error? : NSLog(@"%@", error);
    }];
}

- (void)testStrictPerformWithError {
    XCTestExpectation *providerErrorExpectation = [self expectationWithDescription:@"providerErrorHandler"];
    XCTestExpectation *performerErrorExpectation = [self expectationWithDescription:@"performerErrorHandler"];
    @autoreleasepool {
        TestConfig.routeShouldFail = YES;
        [self enterTest];
        self.router = [ZIKRouterToService(AServiceInput)
                       performWithStrictConfiguring:^(ZIKPerformRouteStrictConfiguration<id<AServiceInput>> *config, ZIKPerformRouteConfiguration * _Nonnull module) {
                           config.successHandler = ^(id<AServiceInput>  _Nonnull destination) {
                               XCTAssert(NO, @"successHandler should not be called");
                           };
                           config.performerSuccessHandler = ^(id<AServiceInput>  _Nonnull destination) {
                               XCTAssert(NO, @"successHandler should not be called");
                           };
                           config.errorHandler = ^(ZIKRouteAction  _Nonnull routeAction, NSError * _Nonnull error) {
                               XCTAssertNotNil(error);
                               [providerErrorExpectation fulfill];
                           };
                           config.performerErrorHandler = ^(ZIKRouteAction  _Nonnull routeAction, NSError * _Nonnull error) {
                               XCTAssertNotNil(error);
                               [performerErrorExpectation fulfill];
                               [self handle:^{
                                   XCTAssert(self.router == nil || self.router.state == ZIKRouterStateUnrouted);
                                   [self leaveTest];
                               }];
                           };
                       }];
    }
    
    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
        !error? : NSLog(@"%@", error);
    }];
}

@end
