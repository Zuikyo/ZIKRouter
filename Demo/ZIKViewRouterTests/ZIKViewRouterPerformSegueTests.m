//
//  ZIKViewRouterPerformSegueTests.m
//  ZIKViewRouterTests
//
//  Created by zuik on 2018/4/23.
//  Copyright © 2018 zuik. All rights reserved.
//

#import "ZIKViewRouterTestCase.h"
#import "TestPerformSegueViewRouter.h"
#import "ZIKInfoViewProtocol.h"

@interface ZIKViewRouterTestCase()
@property (nonatomic, strong) UIViewController *masterViewController;
@property (nonatomic, strong) TestPerformSegueViewRouter *sourceRouter;
@end

@interface ZIKViewRouterPerformSegueTests : ZIKViewRouterTestCase

@end

@implementation ZIKViewRouterPerformSegueTests

- (void)setUp {
    [super setUp];
    self.routeType = ZIKViewRouteTypePerformSegue;
}

- (void)enterSourceViewWithSuccess:(void(^)(UIViewController *source))successHandler {
    self.sourceRouter = [TestPerformSegueViewRouter performPath:ZIKViewRoutePath.pushFrom(self.masterViewController) configuring:^(ZIKViewRouteConfig * _Nonnull config) {
        config.animated = NO;
        config.successHandler = ^(id  _Nonnull destination) {
            NSLog(@"%@: enterSourceView succeed", destination);
            if (successHandler) {
                successHandler(destination);
            }
        };
    }];
}

- (ZIKViewRoutePath *)pathFromSource:(UIViewController *)source {
    return ZIKViewRoutePath.performSegueFrom(source, @"presentInfo", nil);
}

- (void)configRouteConfiguration:(ZIKViewRouteConfiguration *)configuration source:(UIViewController *)source {
    BOOL supportRouteType = [ZIKRouterToView(ZIKInfoViewProtocol) supportRouteType:self.routeType];
    XCTAssertTrue(supportRouteType);
}

- (void)testPerformWithPrepareDestination {
    XCTestExpectation *expectation = [self expectationWithDescription:@"prepareDestination"];
    {
        [self enterTest:^(UIViewController *source) {
            self.router = [ZIKRouterToView(ZIKInfoViewProtocol) performPath:[self pathFromSource:source] configuring:^(ZIKViewRouteConfiguration * _Nonnull config) {
                [self configRouteConfiguration:config source:source];
                config.prepareDestination = ^(id<ZIKInfoViewProtocol>  _Nonnull destination) {
                    destination.delegate = (id)source;
                    destination.name = @"test title";
                    destination.age = 18;
                };
                config.successHandler = ^(id<ZIKInfoViewProtocol>  _Nonnull destination) {
                    XCTAssertNotNil(destination);
                    XCTAssert([destination.name isEqualToString:@"test title"]);
                    [expectation fulfill];
                    [self handle:^{
                        XCTAssert(self.router.state == ZIKRouterStateRouted);
                        [self leaveTest];
                    }];
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
            self.router = [ZIKRouterToView(ZIKInfoViewProtocol) performPath:[self pathFromSource:source] configuring:^(ZIKViewRouteConfiguration * _Nonnull config) {
                [self configRouteConfiguration:config source:source];
                config.completionHandler = ^(BOOL success, id  _Nullable destination, ZIKRouteAction  _Nonnull routeAction, NSError * _Nullable error) {
                    XCTAssertTrue(success);
                    XCTAssertNil(error);
                    [expectation fulfill];
                    [self handle:^{
                        XCTAssert(self.router.state == ZIKRouterStateRouted);
                        [self leaveTest];
                    }];
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
            ZIKViewRoutePath *path = [[ZIKViewRoutePath alloc] initWithRouteType:self.routeType source:nil];
            self.router = [ZIKRouterToView(ZIKInfoViewProtocol) performPath:path configuring:^(ZIKViewRouteConfiguration * _Nonnull config) {
                [self configRouteConfiguration:config source:source];
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
            self.router = [ZIKRouterToView(ZIKInfoViewProtocol) performPath:[[ZIKViewRoutePath alloc] initWithRouteType:self.routeType source:nil] completion:^(BOOL success, id<ZIKInfoViewProtocol>  _Nullable destination, ZIKRouteAction  _Nonnull routeAction, NSError * _Nullable error) {
                XCTAssertFalse(success);
                [expectation fulfill];
                [self handle:^{
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
            self.router = [ZIKRouterToView(ZIKInfoViewProtocol) performPath:[self pathFromSource:source] configuring:^(ZIKViewRouteConfiguration * _Nonnull config) {
                [self configRouteConfiguration:config source:source];
                config.successHandler = ^(id  _Nonnull destination) {
                    XCTAssertNotNil(destination);
                    [expectation fulfill];
                    [self handle:^{
                        XCTAssert(self.router.state == ZIKRouterStateRouted);
                        [self leaveTest];
                    }];
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
            self.router = [ZIKRouterToView(ZIKInfoViewProtocol) performPath:[self pathFromSource:source] configuring:^(ZIKViewRouteConfiguration * _Nonnull config) {
                [self configRouteConfiguration:config source:source];
                config.successHandler = ^(id  _Nonnull destination) {
                    XCTAssertNotNil(destination);
                    [successHandlerExpectation fulfill];
                };
                config.performerSuccessHandler = ^(id  _Nonnull destination) {
                    XCTAssertNotNil(destination);
                    [performerSuccessHandlerExpectation fulfill];
                    
                    [self handle:^{
                        XCTAssert(self.router.state == ZIKRouterStateRouted);
                        [self.router removeRouteWithSuccessHandler:^{
                            XCTAssert(self.router.state == ZIKRouterStateRemoved);
                            [self.router performRouteWithSuccessHandler:^(id<ZIKInfoViewProtocol>  _Nonnull destination) {
                                XCTAssert(self.router.state == ZIKRouterStateRouted);
                                XCTAssertNotNil(destination);
                                [self leaveTest];
                            } errorHandler:^(ZIKRouteAction  _Nonnull routeAction, NSError * _Nonnull error) {
                                
                            }];
                            
                        } errorHandler:nil];
                    }];
                    
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
            ZIKViewRoutePath *path = [[ZIKViewRoutePath alloc] initWithRouteType:self.routeType source:nil];
            self.router = [ZIKRouterToView(ZIKInfoViewProtocol) performPath:path configuring:^(ZIKViewRouteConfiguration * _Nonnull config) {
                [self configRouteConfiguration:config source:source];
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
            self.router = [ZIKRouterToView(ZIKInfoViewProtocol)
                           performPath:[self pathFromSource:source]
                           strictConfiguring:^(ZIKViewRouteStrictConfiguration<id<ZIKInfoViewProtocol>> * _Nonnull config, ZIKViewRouteConfiguration * _Nonnull module) {
                               [self configRouteConfiguration:config.configuration source:source];
                               config.routeType = self.routeType;
                               config.prepareDestination = ^(id<ZIKInfoViewProtocol> destination) {
                                   destination.name = @"test title";
                               };
                               config.successHandler = ^(id<ZIKInfoViewProtocol>  _Nonnull destination) {
                                   XCTAssertNotNil(destination);
                                   XCTAssert([destination.name isEqualToString:@"test title"]);
                                   [expectation fulfill];
                                   [self handle:^{
                                       XCTAssert(self.router.state == ZIKRouterStateRouted);
                                       [self leaveTest];
                                   }];
                                   
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
            self.router = [ZIKRouterToView(ZIKInfoViewProtocol)
                           performPath:[self pathFromSource:source]
                           strictConfiguring:^(ZIKViewRouteStrictConfiguration<id<ZIKInfoViewProtocol>> * _Nonnull config, ZIKViewRouteConfiguration * _Nonnull module) {
                               [self configRouteConfiguration:config.configuration source:source];
                               config.routeType = self.routeType;
                               config.completionHandler = ^(BOOL success, id  _Nullable destination, ZIKRouteAction  _Nonnull routeAction, NSError * _Nullable error) {
                                   XCTAssertTrue(success);
                                   XCTAssertNil(error);
                                   [expectation fulfill];
                                   [self handle:^{
                                       XCTAssert(self.router.state == ZIKRouterStateRouted);
                                       [self leaveTest];
                                   }];
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
            ZIKViewRoutePath *path = [[ZIKViewRoutePath alloc] initWithRouteType:self.routeType source:nil];
            self.router = [ZIKRouterToView(ZIKInfoViewProtocol)
                           performPath:path
                           strictConfiguring:^(ZIKViewRouteStrictConfiguration<id<ZIKInfoViewProtocol>> * _Nonnull config, ZIKViewRouteConfiguration * _Nonnull module) {
                               [self configRouteConfiguration:config.configuration source:source];
                               config.routeType = self.routeType;
                               config.completionHandler = ^(BOOL success, id  _Nullable destination, ZIKRouteAction  _Nonnull routeAction, NSError * _Nullable error) {
                                   XCTAssertFalse(success);
                                   XCTAssertNotNil(error);
                                   XCTAssert(self.router == nil || self.router.state == ZIKRouterStateUnrouted);
                                   [expectation fulfill];
                                   [self handle:^{
                                       [self leaveTest];
                                   }];
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
            self.router = [ZIKRouterToView(ZIKInfoViewProtocol)
                           performPath:[self pathFromSource:source]
                           strictConfiguring:^(ZIKViewRouteStrictConfiguration<id<ZIKInfoViewProtocol>> * _Nonnull config, ZIKViewRouteConfiguration * _Nonnull module) {
                               [self configRouteConfiguration:config.configuration source:source];
                               config.routeType = self.routeType;
                               config.successHandler = ^(id  _Nonnull destination) {
                                   XCTAssertNotNil(destination);
                                   [expectation fulfill];
                                   [self handle:^{
                                       XCTAssert(self.router.state == ZIKRouterStateRouted);
                                       [self leaveTest];
                                   }];
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
            self.router = [ZIKRouterToView(ZIKInfoViewProtocol)
                           performPath:[self pathFromSource:source]
                           strictConfiguring:^(ZIKViewRouteStrictConfiguration<id<ZIKInfoViewProtocol>> * _Nonnull config, ZIKViewRouteConfiguration * _Nonnull module) {
                               [self configRouteConfiguration:config.configuration source:source];
                               config.routeType = self.routeType;
                               config.successHandler = ^(id  _Nonnull destination) {
                                   XCTAssertNotNil(destination);
                                   [successHandlerExpectation fulfill];
                               };
                               config.performerSuccessHandler = ^(id  _Nonnull destination) {
                                   XCTAssertNotNil(destination);
                                   [performerSuccessHandlerExpectation fulfill];
                                   
                                   [self handle:^{
                                       [self.router removeRouteWithSuccessHandler:^{
                                           XCTAssert(self.router.state == ZIKRouterStateRemoved);
                                           [self.router performRouteWithSuccessHandler:^(id<ZIKInfoViewProtocol>  _Nonnull destination) {
                                               XCTAssert(self.router.state == ZIKRouterStateRouted);
                                               XCTAssertNotNil(destination);
                                               [self leaveTest];
                                           } errorHandler:^(ZIKRouteAction  _Nonnull routeAction, NSError * _Nonnull error) {
                                               
                                           }];
                                           
                                       } errorHandler:nil];
                                   }];
                                   
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
            ZIKViewRoutePath *path = [[ZIKViewRoutePath alloc] initWithRouteType:self.routeType source:nil];
            self.router = [ZIKRouterToView(ZIKInfoViewProtocol)
                           performPath:path
                           strictConfiguring:^(ZIKViewRouteStrictConfiguration<id<ZIKInfoViewProtocol>> * _Nonnull config, ZIKViewRouteConfiguration * _Nonnull module) {
                               [self configRouteConfiguration:config.configuration source:source];
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
                                   [self handle:^{
                                       XCTAssert(self.router == nil || self.router.state == ZIKRouterStateUnrouted);
                                       [self leaveTest];
                                   }];
                               };
                           }];
        }];
    }
    
    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
        !error? : NSLog(@"%@", error);
    }];
}

@end

@interface ZIKViewRouterPerformCustomSegueTests : ZIKViewRouterPerformSegueTests

@end

@implementation ZIKViewRouterPerformCustomSegueTests

- (ZIKViewRoutePath *)pathFromSource:(UIViewController *)source {
    return ZIKViewRoutePath.performSegueFrom(source, @"customSegue", nil);
}

@end

@interface ZIKViewRouterPerformSegueForUnroutableDestinationTests : ZIKViewRouterPerformSegueTests

@end

@implementation ZIKViewRouterPerformSegueForUnroutableDestinationTests

- (void)setUp {
    [super setUp];
    self.routeType = ZIKViewRouteTypePerformSegue;
}

- (void)enterSourceViewWithSuccess:(void(^)(UIViewController *source))successHandler {
    self.sourceRouter = [TestPerformSegueViewRouter performPath:ZIKViewRoutePath.pushFrom(self.masterViewController) configuring:^(ZIKViewRouteConfig * _Nonnull config) {
        config.animated = NO;
        config.successHandler = ^(id  _Nonnull destination) {
            NSLog(@"%@: enterSourceView succeed", destination);
            if (successHandler) {
                successHandler(destination);
            }
        };
    }];
}

- (ZIKViewRoutePath *)pathFromSource:(UIViewController *)source {
    return ZIKViewRoutePath.performSegueFrom(source, @"showUnroutableDestination", nil);
}

- (void)testPerformWithPrepareDestination {
    XCTestExpectation *expectation = [self expectationWithDescription:@"prepareDestination"];
    {
        [self enterTest:^(UIViewController *source) {
            self.router = [ZIKAnyViewRouter performPath:[self pathFromSource:source] configuring:^(ZIKViewRouteConfiguration * _Nonnull config) {
                [self configRouteConfiguration:config source:source];
                config.prepareDestination = ^(id  _Nonnull destination) {
                    [expectation fulfill];
                };
                config.successHandler = ^(id  _Nonnull destination) {
                    XCTAssertNotNil(destination);
                    [self handle:^{
                        XCTAssert(self.router.state == ZIKRouterStateRouted);
                        [self leaveTest];
                    }];
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
            self.router = [ZIKAnyViewRouter performPath:[self pathFromSource:source] configuring:^(ZIKViewRouteConfiguration * _Nonnull config) {
                [self configRouteConfiguration:config source:source];
                config.completionHandler = ^(BOOL success, id  _Nullable destination, ZIKRouteAction  _Nonnull routeAction, NSError * _Nullable error) {
                    XCTAssertTrue(success);
                    XCTAssertNil(error);
                    [expectation fulfill];
                    [self handle:^{
                        XCTAssert(self.router.state == ZIKRouterStateRouted);
                        [self leaveTest];
                    }];
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
            ZIKViewRoutePath *path = [[ZIKViewRoutePath alloc] initWithRouteType:self.routeType source:nil];
            self.router = [ZIKAnyViewRouter performPath:path configuring:^(ZIKViewRouteConfiguration * _Nonnull config) {
                [self configRouteConfiguration:config source:source];
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
            self.router = [ZIKAnyViewRouter performPath:[[ZIKViewRoutePath alloc] initWithRouteType:self.routeType source:nil] completion:^(BOOL success, id  _Nullable destination, ZIKRouteAction  _Nonnull routeAction, NSError * _Nullable error) {
                XCTAssertFalse(success);
                [expectation fulfill];
                [self leaveTest];
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
            self.router = [ZIKAnyViewRouter performPath:[self pathFromSource:source] configuring:^(ZIKViewRouteConfiguration * _Nonnull config) {
                [self configRouteConfiguration:config source:source];
                config.successHandler = ^(id  _Nonnull destination) {
                    XCTAssertNotNil(destination);
                    [expectation fulfill];
                    [self handle:^{
                        XCTAssert(self.router.state == ZIKRouterStateRouted);
                        [self leaveTest];
                    }];
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
            self.router = [ZIKAnyViewRouter performPath:[self pathFromSource:source] configuring:^(ZIKViewRouteConfiguration * _Nonnull config) {
                [self configRouteConfiguration:config source:source];
                config.successHandler = ^(id  _Nonnull destination) {
                    XCTAssertNotNil(destination);
                    [successHandlerExpectation fulfill];
                };
                config.performerSuccessHandler = ^(id  _Nonnull destination) {
                    XCTAssertNotNil(destination);
                    [performerSuccessHandlerExpectation fulfill];
                    
                    [self handle:^{
                        XCTAssert(self.router.state == ZIKRouterStateRouted);
                        [self.router removeRouteWithSuccessHandler:^{
                            XCTAssert(self.router.state == ZIKRouterStateRemoved);
                            [self.router performRouteWithSuccessHandler:^(id  _Nonnull destination) {
                                XCTAssert(self.router.state == ZIKRouterStateRouted);
                                XCTAssertNotNil(destination);
                                [self leaveTest];
                            } errorHandler:^(ZIKRouteAction  _Nonnull routeAction, NSError * _Nonnull error) {
                                
                            }];
                            
                        } errorHandler:nil];
                    }];
                    
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
            ZIKViewRoutePath *path = [[ZIKViewRoutePath alloc] initWithRouteType:self.routeType source:nil];
            self.router = [ZIKAnyViewRouter performPath:path configuring:^(ZIKViewRouteConfiguration * _Nonnull config) {
                [self configRouteConfiguration:config source:source];
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
            self.router = [ZIKAnyViewRouter
                           performPath:[self pathFromSource:source]
                           strictConfiguring:^(ZIKViewRouteStrictConfiguration * _Nonnull config, ZIKViewRouteConfiguration * _Nonnull module) {
                               [self configRouteConfiguration:config.configuration source:source];
                               config.prepareDestination = ^(id  _Nonnull destination) {
                                   [expectation fulfill];
                               };
                               config.successHandler = ^(id  _Nonnull destination) {
                                   XCTAssertNotNil(destination);
                                   [self handle:^{
                                       XCTAssert(self.router.state == ZIKRouterStateRouted);
                                       [self leaveTest];
                                   }];
                                   
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
            self.router = [ZIKAnyViewRouter
                           performPath:[self pathFromSource:source]
                           strictConfiguring:^(ZIKViewRouteStrictConfiguration * _Nonnull config, ZIKViewRouteConfiguration * _Nonnull module) {
                               [self configRouteConfiguration:config.configuration source:source];
                               config.routeType = self.routeType;
                               config.completionHandler = ^(BOOL success, id  _Nullable destination, ZIKRouteAction  _Nonnull routeAction, NSError * _Nullable error) {
                                   XCTAssertTrue(success);
                                   XCTAssertNil(error);
                                   [expectation fulfill];
                                   [self handle:^{
                                       XCTAssert(self.router.state == ZIKRouterStateRouted);
                                       [self leaveTest];
                                   }];
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
            ZIKViewRoutePath *path = [[ZIKViewRoutePath alloc] initWithRouteType:self.routeType source:nil];
            self.router = [ZIKAnyViewRouter
                           performPath:path
                           strictConfiguring:^(ZIKViewRouteStrictConfiguration * _Nonnull config, ZIKViewRouteConfiguration * _Nonnull module) {
                               [self configRouteConfiguration:config.configuration source:source];
                               config.routeType = self.routeType;
                               config.completionHandler = ^(BOOL success, id  _Nullable destination, ZIKRouteAction  _Nonnull routeAction, NSError * _Nullable error) {
                                   XCTAssertFalse(success);
                                   XCTAssertNotNil(error);
                                   XCTAssert(self.router == nil || self.router.state == ZIKRouterStateUnrouted);
                                   [expectation fulfill];
                                   [self handle:^{
                                       [self leaveTest];
                                   }];
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
            self.router = [ZIKAnyViewRouter
                           performPath:[self pathFromSource:source]
                           strictConfiguring:^(ZIKViewRouteStrictConfiguration * _Nonnull config, ZIKViewRouteConfiguration * _Nonnull module) {
                               [self configRouteConfiguration:config.configuration source:source];
                               config.routeType = self.routeType;
                               config.successHandler = ^(id  _Nonnull destination) {
                                   XCTAssertNotNil(destination);
                                   [expectation fulfill];
                                   [self handle:^{
                                       XCTAssert(self.router.state == ZIKRouterStateRouted);
                                       [self leaveTest];
                                   }];
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
            self.router = [ZIKAnyViewRouter
                           performPath:[self pathFromSource:source]
                           strictConfiguring:^(ZIKViewRouteStrictConfiguration * _Nonnull config, ZIKViewRouteConfiguration * _Nonnull module) {
                               [self configRouteConfiguration:config.configuration source:source];
                               config.routeType = self.routeType;
                               config.successHandler = ^(id  _Nonnull destination) {
                                   XCTAssertNotNil(destination);
                                   [successHandlerExpectation fulfill];
                               };
                               config.performerSuccessHandler = ^(id  _Nonnull destination) {
                                   XCTAssertNotNil(destination);
                                   [performerSuccessHandlerExpectation fulfill];
                                   
                                   [self handle:^{
                                       [self.router removeRouteWithSuccessHandler:^{
                                           XCTAssert(self.router.state == ZIKRouterStateRemoved);
                                           [self.router performRouteWithSuccessHandler:^(id  _Nonnull destination) {
                                               XCTAssert(self.router.state == ZIKRouterStateRouted);
                                               XCTAssertNotNil(destination);
                                               [self leaveTest];
                                           } errorHandler:^(ZIKRouteAction  _Nonnull routeAction, NSError * _Nonnull error) {
                                               
                                           }];
                                           
                                       } errorHandler:nil];
                                   }];
                                   
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
            ZIKViewRoutePath *path = [[ZIKViewRoutePath alloc] initWithRouteType:self.routeType source:nil];
            self.router = [ZIKAnyViewRouter
                           performPath:path
                           strictConfiguring:^(ZIKViewRouteStrictConfiguration * _Nonnull config, ZIKViewRouteConfiguration * _Nonnull module) {
                               [self configRouteConfiguration:config.configuration source:source];
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
                                   [self handle:^{
                                       XCTAssert(self.router == nil || self.router.state == ZIKRouterStateUnrouted);
                                       [self leaveTest];
                                   }];
                               };
                           }];
        }];
    }
    
    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
        !error? : NSLog(@"%@", error);
    }];
}

@end
