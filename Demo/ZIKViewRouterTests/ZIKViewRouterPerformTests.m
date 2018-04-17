//
//  ZIKViewRouterPerformTests.m
//  ZIKViewRouterTests
//
//  Created by zuik on 2018/4/11.
//  Copyright © 2018 zuik. All rights reserved.
//

#import "ZIKViewRouterTestCase.h"
@import ZIKRouter;
#import "AViewInput.h"

@interface ZIKViewRouterPerformTests : ZIKViewRouterTestCase

@end

@implementation ZIKViewRouterPerformTests

- (void)setUp {
    [super setUp];
}

- (void)configRouteConfiguration:(ZIKViewRouteConfiguration *)configuration {
    configuration.animated = YES;
}

- (void)testPerformWithPrepareDestination {
    XCTestExpectation *expectation = [self expectationWithDescription:@"prepareDestination"];
    {
        [self enterTest:^(UIViewController *source) {
            self.router = [ZIKRouterToView(AViewInput) performFromSource:source configuring:^(ZIKViewRouteConfiguration * _Nonnull config) {
                [self configRouteConfiguration:config];
                config.routeType = self.routeType;
                config.prepareDestination = ^(id<AViewInput>  _Nonnull destination) {
                    destination.title = @"test title";
                };
                config.successHandler = ^(id<AViewInput>  _Nonnull destination) {
                    XCTAssertNotNil(destination);
                    XCTAssert([destination.title isEqualToString:@"test title"]);
                    [expectation fulfill];
                    [self leaveTest];
                };
            }];
        }];
    }
    
    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
        !error? : NSLog(@"%@", error);
    }];
}

- (void)testPerformWithSuccessCompletionHandler {
    XCTestExpectation *expectation = [self expectationWithDescription:@"completionHandler"];
    {
        [self enterTest:^(UIViewController *source) {
            self.router = [ZIKRouterToView(AViewInput) performFromSource:source configuring:^(ZIKViewRouteConfiguration * _Nonnull config) {
                [self configRouteConfiguration:config];
                config.routeType = self.routeType;
                config.completionHandler = ^(BOOL success, id  _Nullable destination, ZIKRouteAction  _Nonnull routeAction, NSError * _Nullable error) {
                    XCTAssertTrue(success);
                    XCTAssertNil(error);
                    [expectation fulfill];
                    [self leaveTest];
                };
            }];
        }];
    }
    
    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
        !error? : NSLog(@"%@", error);
    }];
}

- (void)testPerformWithErrorCompletionHandler {
    XCTestExpectation *expectation = [self expectationWithDescription:@"completionHandler"];
    {
        [self enterTest:^(UIViewController *source) {
            self.router = [ZIKRouterToView(AViewInput) performFromSource:nil configuring:^(ZIKViewRouteConfiguration * _Nonnull config) {
                [self configRouteConfiguration:config];
                config.routeType = self.routeType;
                config.completionHandler = ^(BOOL success, id  _Nullable destination, ZIKRouteAction  _Nonnull routeAction, NSError * _Nullable error) {
                    XCTAssertFalse(success);
                    XCTAssertNotNil(error);
                    XCTAssertNil(self.router);
                    [expectation fulfill];
                    [self leaveTest];
                };
            }];
        }];
    }
    
    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
        !error? : NSLog(@"%@", error);
    }];
}

- (void)testPerformWithSuccessCompletion {
    XCTestExpectation *expectation = [self expectationWithDescription:@"completionHandler"];
    {
        [self enterTest:^(UIViewController *source) {
            self.router = [ZIKRouterToView(AViewInput) performFromSource:source routeType:self.routeType completion:^(BOOL success, id<AViewInput>  _Nullable destination, ZIKRouteAction  _Nonnull routeAction, NSError * _Nullable error) {
                XCTAssertTrue(success);
                XCTAssertNil(error);
                [expectation fulfill];
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
    {
        [self enterTest:^(UIViewController *source) {
            self.router = [ZIKRouterToView(AViewInput) performFromSource:nil routeType:self.routeType completion:^(BOOL success, id<AViewInput>  _Nullable destination, ZIKRouteAction  _Nonnull routeAction, NSError * _Nullable error) {
                XCTAssertFalse(success);
                XCTAssertNotNil(error);
                XCTAssertNil(self.router);
                [expectation fulfill];
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
    {
        [self enterTest:^(UIViewController *source) {
            self.router = [ZIKRouterToView(AViewInput) performFromSource:source routeType:self.routeType completion:^(BOOL success, id<AViewInput>  _Nullable destination, ZIKRouteAction  _Nonnull routeAction, NSError * _Nullable error) {
                XCTAssertTrue(success);
                XCTAssertNil(error);
                
                [self.router removeRouteWithSuccessHandler:^{
                    
                    [self.router performRouteWithCompletion:^(BOOL success, id  _Nullable destination, ZIKRouteAction  _Nonnull routeAction, NSError * _Nullable error) {
                        XCTAssertTrue(success);
                        XCTAssertNil(error);
                        [expectation fulfill];
                        [self leaveTest];
                    }];
                    
                } errorHandler:nil];
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
    {
        [self enterTest:^(UIViewController *source) {
            self.router = [ZIKRouterToView(AViewInput) performFromSource:source routeType:self.routeType completion:^(BOOL success, id<AViewInput>  _Nullable destination, ZIKRouteAction  _Nonnull routeAction, NSError * _Nullable error) {
                XCTAssertTrue(success);
                [self.router performRouteWithCompletion:^(BOOL success, id  _Nullable destination, ZIKRouteAction  _Nonnull routeAction, NSError * _Nullable error) {
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
    {
        [self enterTest:^(UIViewController *source) {
            self.router = [ZIKRouterToView(AViewInput) performFromSource:source configuring:^(ZIKViewRouteConfiguration * _Nonnull config) {
                config.routeType = self.routeType;
                config.successHandler = ^(id  _Nonnull destination) {
                    XCTAssertNotNil(destination);
                    [expectation fulfill];
                    [self leaveTest];
                };
            }];
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
    {
        [self enterTest:^(UIViewController *source) {
            self.router = [ZIKRouterToView(AViewInput) performFromSource:source configuring:^(ZIKViewRouteConfiguration * _Nonnull config) {
                [self configRouteConfiguration:config];
                config.routeType = self.routeType;
                config.successHandler = ^(id  _Nonnull destination) {
                    XCTAssertNotNil(destination);
                    [successHandlerExpectation fulfill];
                };
                config.performerSuccessHandler = ^(id  _Nonnull destination) {
                    XCTAssertNotNil(destination);
                    [performerSuccessHandlerExpectation fulfill];
                    
                    [self.router removeRouteWithSuccessHandler:^{
                        
                        [self.router performRouteWithSuccessHandler:^(id<AViewInput>  _Nonnull destination) {
                            XCTAssertNotNil(destination);
                            [self leaveTest];
                        } errorHandler:^(ZIKRouteAction  _Nonnull routeAction, NSError * _Nonnull error) {
                            
                        }];
                        
                    } errorHandler:nil];
                    
                };
            }];
        }];
    }
    
    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
        !error? : NSLog(@"%@", error);
    }];
}

- (void)testPerformWithError {
    XCTestExpectation *providerErrorExpectation = [self expectationWithDescription:@"providerErrorHandler"];
    XCTestExpectation *performerErrorExpectation = [self expectationWithDescription:@"performerErrorHandler"];
    {
        [self enterTest:^(UIViewController *source) {
            self.router = [ZIKRouterToView(AViewInput) performFromSource:nil configuring:^(ZIKViewRouteConfiguration * _Nonnull config) {
                [self configRouteConfiguration:config];
                config.routeType = self.routeType;
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
                    [self leaveTest];
                };
            }];
        }];
    }
    
    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
        !error? : NSLog(@"%@", error);
    }];
}

#pragma mark Strict

- (void)testStrictPerformWithPrepareDestination {
    XCTestExpectation *expectation = [self expectationWithDescription:@"prepareDestination"];
    {
        [self enterTest:^(UIViewController *source) {
            self.router = [ZIKRouterToView(AViewInput)
                           performFromSource:source
                           strictConfiguring:^(ZIKViewRouteConfiguration * _Nonnull config,
                                               void (^prepareDest)(void (^)(id<AViewInput> destination)),
                                               void (^prepareModule)(void (^)(ZIKViewRouteConfig *config))) {
                               [self configRouteConfiguration:config];
                               config.routeType = self.routeType;
                               prepareDest(^(id<AViewInput> destination) {
                                   destination.title = @"test title";
                               });
                               config.successHandler = ^(id<AViewInput>  _Nonnull destination) {
                                   XCTAssertNotNil(destination);
                                   XCTAssert([destination.title isEqualToString:@"test title"]);
                                   [expectation fulfill];
                                   [self leaveTest];
                };
            }];
        }];
    }
    
    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
        !error? : NSLog(@"%@", error);
    }];
}

- (void)testStrictPerformWithSuccessCompletionHandler {
    XCTestExpectation *expectation = [self expectationWithDescription:@"completionHandler"];
    {
        [self enterTest:^(UIViewController *source) {
            self.router = [ZIKRouterToView(AViewInput)
                           performFromSource:source
                           strictConfiguring:^(ZIKViewRouteConfiguration * _Nonnull config,
                                               void (^prepareDest)(void (^)(id<AViewInput> destination)),
                                               void (^prepareModule)(void (^)(ZIKViewRouteConfig *config))) {
                               [self configRouteConfiguration:config];
                               config.routeType = self.routeType;
                               config.completionHandler = ^(BOOL success, id  _Nullable destination, ZIKRouteAction  _Nonnull routeAction, NSError * _Nullable error) {
                                   XCTAssertTrue(success);
                                   XCTAssertNil(error);
                                   [expectation fulfill];
                                   [self leaveTest];
                               };
            }];
        }];
    }
    
    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
        !error? : NSLog(@"%@", error);
    }];
}

- (void)testStrictPerformWithErrorCompletionHandler {
    XCTestExpectation *expectation = [self expectationWithDescription:@"completionHandler"];
    {
        [self enterTest:^(UIViewController *source) {
            self.router = [ZIKRouterToView(AViewInput)
                           performFromSource:nil
                           strictConfiguring:^(ZIKViewRouteConfiguration * _Nonnull config,
                                               void (^prepareDest)(void (^)(id<AViewInput> destination)),
                                               void (^prepareModule)(void (^)(ZIKViewRouteConfig *config))) {
                               [self configRouteConfiguration:config];
                               config.routeType = self.routeType;
                               config.completionHandler = ^(BOOL success, id  _Nullable destination, ZIKRouteAction  _Nonnull routeAction, NSError * _Nullable error) {
                                   XCTAssertFalse(success);
                                   XCTAssertNotNil(error);
                                   XCTAssertNil(self.router);
                                   [expectation fulfill];
                                   [self leaveTest];
                               };
            }];
        }];
    }
    
    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
        !error? : NSLog(@"%@", error);
    }];
}

- (void)testStrictPerformWithSuccess {
    XCTestExpectation *expectation = [self expectationWithDescription:@"successHandler"];
    {
        [self enterTest:^(UIViewController *source) {
            self.router = [ZIKRouterToView(AViewInput)
                           performFromSource:source
                           strictConfiguring:^(ZIKViewRouteConfiguration * _Nonnull config,
                                               void (^prepareDest)(void (^)(id<AViewInput> destination)),
                                               void (^prepareModule)(void (^)(ZIKViewRouteConfig *config))) {
                               [self configRouteConfiguration:config];
                               config.routeType = self.routeType;
                               config.successHandler = ^(id  _Nonnull destination) {
                                   XCTAssertNotNil(destination);
                                   [expectation fulfill];
                                   [self leaveTest];
                               };
            }];
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
    {
        [self enterTest:^(UIViewController *source) {
            self.router = [ZIKRouterToView(AViewInput)
                           performFromSource:source
                           strictConfiguring:^(ZIKViewRouteConfiguration * _Nonnull config,
                                               void (^prepareDest)(void (^)(id<AViewInput> destination)),
                                               void (^prepareModule)(void (^)(ZIKViewRouteConfig *config))) {
                               [self configRouteConfiguration:config];
                               config.routeType = self.routeType;
                               config.successHandler = ^(id  _Nonnull destination) {
                                   XCTAssertNotNil(destination);
                                   [successHandlerExpectation fulfill];
                               };
                               config.performerSuccessHandler = ^(id  _Nonnull destination) {
                                   XCTAssertNotNil(destination);
                                   [performerSuccessHandlerExpectation fulfill];
                                   
                                   [self.router removeRouteWithSuccessHandler:^{
                                       
                                       [self.router performRouteWithSuccessHandler:^(id<AViewInput>  _Nonnull destination) {
                                           XCTAssertNotNil(destination);
                                           [self leaveTest];
                                       } errorHandler:^(ZIKRouteAction  _Nonnull routeAction, NSError * _Nonnull error) {
                                           
                                       }];
                                       
                                   } errorHandler:nil];
                                   
                               };
            }];
        }];
    }
    
    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
        !error? : NSLog(@"%@", error);
    }];
}

- (void)testStrictPerformWithError {
    XCTestExpectation *providerErrorExpectation = [self expectationWithDescription:@"providerErrorHandler"];
    XCTestExpectation *performerErrorExpectation = [self expectationWithDescription:@"performerErrorHandler"];
    {
        [self enterTest:^(UIViewController *source) {
            self.router = [ZIKRouterToView(AViewInput)
                           performFromSource:nil
                           strictConfiguring:^(ZIKViewRouteConfiguration * _Nonnull config,
                                               void (^prepareDest)(void (^)(id<AViewInput> destination)),
                                               void (^prepareModule)(void (^)(ZIKViewRouteConfig *config))) {
                               [self configRouteConfiguration:config];
                               config.routeType = self.routeType;
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
                                   [self leaveTest];
                               };
            }];
        }];
    }
    
    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
        !error? : NSLog(@"%@", error);
    }];
}

@end

@interface ZIKViewRouterPerformWithoutAnimationTests : ZIKViewRouterPerformTests

@end

@implementation ZIKViewRouterPerformWithoutAnimationTests

- (void)configRouteConfiguration:(ZIKViewRouteConfiguration *)configuration {
    [super configRouteConfiguration:configuration];
    configuration.animated = NO;
}

@end

@interface ZIKViewRouterPerformPushTests : ZIKViewRouterPerformTests

@end

@implementation ZIKViewRouterPerformPushTests

- (void)setUp {
    [super setUp];
    self.routeType = ZIKViewRouteTypePush;
}

@end

@interface ZIKViewRouterPerformPushWithoutAnimationTests : ZIKViewRouterPerformWithoutAnimationTests

@end

@implementation ZIKViewRouterPerformPushWithoutAnimationTests

- (void)setUp {
    [super setUp];
    self.routeType = ZIKViewRouteTypePush;
}

@end

@interface ZIKViewRouterPerformShowTests : ZIKViewRouterPerformTests

@end

@implementation ZIKViewRouterPerformShowTests

- (void)setUp {
    [super setUp];
    self.routeType = ZIKViewRouteTypeShow;
}

@end

@interface ZIKViewRouterPerformShowWithoutAnimationTests : ZIKViewRouterPerformWithoutAnimationTests

@end

@implementation ZIKViewRouterPerformShowWithoutAnimationTests

- (void)setUp {
    [super setUp];
    self.routeType = ZIKViewRouteTypeShow;
}

@end
