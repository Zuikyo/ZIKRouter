//
//  ZIKViewRouterPerformAddAsChildTests.m
//  ZIKViewRouterTests
//
//  Created by zuik on 2018/4/17.
//  Copyright © 2018 zuik. All rights reserved.
//

#import "ZIKViewRouterTestCase.h"

@interface ZIKViewRouterPerformAddAsChildTests : ZIKViewRouterTestCase

@end

@implementation ZIKViewRouterPerformAddAsChildTests

- (void)setUp {
    [super setUp];
    self.routeType = ZIKViewRouteTypeAddAsChildViewController;
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)configRouteConfiguration:(ZIKViewRouteConfiguration *)configuration source:(UIViewController *)source {
    configuration.animated = YES;
}

+ (void)addChildToParentView:(UIView *)parentView childView:(UIView *)childView completion:(void(^)(void))completion {
    childView.frame = parentView.frame;
    childView.transform = CGAffineTransformMakeScale(0.1, 0.1);
    [UIView animateWithDuration:0.5 animations:^{
        childView.backgroundColor = [UIColor redColor];
        [parentView addSubview:childView];
        childView.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        if (completion) {
            completion();
        }
    }];
}

- (void)testPerformWithPrepareDestination {
    XCTestExpectation *expectation = [self expectationWithDescription:@"prepareDestination"];
    {
        [self enterTest:^(UIViewController *source) {
            ZIKAnyViewRouter *router;
            router = [ZIKRouterToView(AViewInput) performFromSource:source configuring:^(ZIKViewRouteConfiguration * _Nonnull config) {
                [self configRouteConfiguration:config source:source];
                config.routeType = self.routeType;
                config.prepareDestination = ^(id<AViewInput>  _Nonnull destination) {
                    destination.title = @"test title";
                };
                config.successHandler = ^(UIViewController<AViewInput> * _Nonnull destination) {
                    XCTAssertNotNil(destination);
                    XCTAssert([destination.title isEqualToString:@"test title"]);
                    [[self class] addChildToParentView:source.view childView:destination.view completion:^{
                        XCTAssert(self.router.state == ZIKRouterStateRouted);
                        [destination didMoveToParentViewController:source];
                        [expectation fulfill];
                        self.strongRouter = nil;
                        [self leaveTest];
                    }];
                };
            }];
            self.router = router;
            self.strongRouter = router;
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
            ZIKAnyViewRouter *router;
            router = [ZIKRouterToView(AViewInput) performFromSource:source configuring:^(ZIKViewRouteConfiguration * _Nonnull config) {
                [self configRouteConfiguration:config source:source];
                config.routeType = self.routeType;
                config.completionHandler = ^(BOOL success, UIViewController  *_Nullable destination, ZIKRouteAction  _Nonnull routeAction, NSError * _Nullable error) {
                    XCTAssertTrue(success);
                    XCTAssertNil(error);
                    [[self class] addChildToParentView:source.view childView:destination.view completion:^{
                        XCTAssert(self.router.state == ZIKRouterStateRouted);
                        [destination didMoveToParentViewController:source];
                        [expectation fulfill];
                        self.strongRouter = nil;
                        [self leaveTest];
                    }];
                };
            }];
            self.router = router;
            self.strongRouter = router;
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
                [self configRouteConfiguration:config source:source];
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
            ZIKAnyViewRouter *router;
            router = [ZIKRouterToView(AViewInput) performFromSource:source routeType:self.routeType completion:^(BOOL success, UIViewController<AViewInput> *_Nullable destination, ZIKRouteAction  _Nonnull routeAction, NSError * _Nullable error) {
                XCTAssertTrue(success);
                XCTAssertNil(error);
                [[self class] addChildToParentView:source.view childView:destination.view completion:^{
                    XCTAssert(self.router.state == ZIKRouterStateRouted);
                    [destination didMoveToParentViewController:source];
                    [expectation fulfill];
                    self.strongRouter = nil;
                    [self leaveTest];
                }];
            }];
            self.router = router;
            self.strongRouter = router;
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
            ZIKAnyViewRouter *router = [ZIKRouterToView(AViewInput) performFromSource:source routeType:self.routeType completion:^(BOOL success, UIViewController<AViewInput> *_Nullable destination, ZIKRouteAction  _Nonnull routeAction, NSError * _Nullable error) {
                XCTAssertTrue(success);
                XCTAssertNil(error);
                
                [[self class] addChildToParentView:source.view childView:destination.view completion:^{
                    XCTAssert(self.router.state == ZIKRouterStateRouted);
                    [self.router removeRouteWithSuccessHandler:^{
                        XCTAssert(self.router.state == ZIKRouterStateRemoved);
                        [self.router performRouteWithCompletion:^(BOOL success, UIViewController *_Nullable destination, ZIKRouteAction  _Nonnull routeAction, NSError * _Nullable error) {
                            XCTAssert(self.router.state == ZIKRouterStateRouted);
                            XCTAssertTrue(success);
                            XCTAssertNil(error);
                            [[self class] addChildToParentView:source.view childView:destination.view completion:^{
                                [destination didMoveToParentViewController:source];
                                [expectation fulfill];
                                self.strongRouter = nil;
                                [self leaveTest];
                            }];
                        }];
                        
                    } errorHandler:nil];
                }];
            }];
            self.router = router;
            self.strongRouter = router;
        }];
    }
    
    [self waitForExpectationsWithTimeout:500 handler:^(NSError * _Nullable error) {
        !error? : NSLog(@"%@", error);
    }];
}

- (void)testPerformRouteWithErrorCompletion {
    XCTestExpectation *expectation = [self expectationWithDescription:@"completionHandler"];
    expectation.assertForOverFulfill = YES;
    {
        [self enterTest:^(UIViewController *source) {
            ZIKAnyViewRouter *router = [ZIKRouterToView(AViewInput) performFromSource:source routeType:self.routeType completion:^(BOOL success, UIViewController<AViewInput> *_Nullable destination, ZIKRouteAction  _Nonnull routeAction, NSError * _Nullable error) {
                XCTAssertTrue(success);
                [[self class] addChildToParentView:source.view childView:destination.view completion:^{
                    XCTAssert(self.router.state == ZIKRouterStateRouted);
                    [self.router performRouteWithCompletion:^(BOOL success, id  _Nullable destination, ZIKRouteAction  _Nonnull routeAction, NSError * _Nullable error) {
                        XCTAssert(self.router.state == ZIKRouterStateRouted);
                        XCTAssertFalse(success);
                        XCTAssertNotNil(error);
                        [expectation fulfill];
                        self.strongRouter = nil;
                        [self leaveTest];
                    }];
                }];
            }];
            self.router = router;
            self.strongRouter = router;
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
            ZIKAnyViewRouter *router;
            router = [ZIKRouterToView(AViewInput) performFromSource:source configuring:^(ZIKViewRouteConfiguration * _Nonnull config) {
                config.routeType = self.routeType;
                config.successHandler = ^(UIViewController * _Nonnull destination) {
                    XCTAssertNotNil(destination);
                    [[self class] addChildToParentView:source.view childView:destination.view completion:^{
                        XCTAssert(self.router.state == ZIKRouterStateRouted);
                        [destination didMoveToParentViewController:source];
                        [expectation fulfill];
                        self.strongRouter = nil;
                        [self leaveTest];
                    }];
                };
            }];
            self.router = router;
            self.strongRouter = router;
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
            ZIKAnyViewRouter *router = [ZIKRouterToView(AViewInput) performFromSource:source configuring:^(ZIKViewRouteConfiguration * _Nonnull config) {
                [self configRouteConfiguration:config source:source];
                config.routeType = self.routeType;
                config.successHandler = ^(id  _Nonnull destination) {
                    XCTAssertNotNil(destination);
                    [successHandlerExpectation fulfill];
                };
                config.performerSuccessHandler = ^(UIViewController * _Nonnull destination) {
                    XCTAssertNotNil(destination);
                    [performerSuccessHandlerExpectation fulfill];
                    [[self class] addChildToParentView:source.view childView:destination.view completion:^{
                        XCTAssert(self.router.state == ZIKRouterStateRouted);
                        [self.router removeRouteWithSuccessHandler:^{
                            XCTAssert(self.router.state == ZIKRouterStateRemoved);
                            [self.router performRouteWithSuccessHandler:^(UIViewController<AViewInput> *_Nonnull destination) {
                                XCTAssert(self.router.state == ZIKRouterStateRouted);
                                XCTAssertNotNil(destination);
                                [[self class] addChildToParentView:source.view childView:destination.view completion:^{
                                    [destination didMoveToParentViewController:source];
                                    self.strongRouter = nil;
                                    [self leaveTest];
                                }];
                            } errorHandler:^(ZIKRouteAction  _Nonnull routeAction, NSError * _Nonnull error) {
                                
                            }];
                            
                        } errorHandler:nil];
                    }];
                };
            }];
            self.router = router;
            self.strongRouter = router;
        }];
    }
    
    [self waitForExpectationsWithTimeout:500 handler:^(NSError * _Nullable error) {
        !error? : NSLog(@"%@", error);
    }];
}

- (void)testPerformWithError {
    XCTestExpectation *providerErrorExpectation = [self expectationWithDescription:@"providerErrorHandler"];
    XCTestExpectation *performerErrorExpectation = [self expectationWithDescription:@"performerErrorHandler"];
    {
        [self enterTest:^(UIViewController *source) {
            self.router = [ZIKRouterToView(AViewInput) performFromSource:nil configuring:^(ZIKViewRouteConfiguration * _Nonnull config) {
                [self configRouteConfiguration:config source:source];
                config.routeType = self.routeType;
                config.successHandler = ^(id  _Nonnull destination) {
                    XCTAssert(NO, @"successHandler should not be called");
                };
                config.performerSuccessHandler = ^(id  _Nonnull destination) {
                    XCTAssert(NO, @"successHandler should not be called");
                };
                config.errorHandler = ^(ZIKRouteAction  _Nonnull routeAction, NSError * _Nonnull error) {
                    XCTAssert(self.router.state == ZIKRouterStateUnrouted);
                    XCTAssertNotNil(error);
                    [providerErrorExpectation fulfill];
                };
                config.performerErrorHandler = ^(ZIKRouteAction  _Nonnull routeAction, NSError * _Nonnull error) {
                    XCTAssert(self.router.state == ZIKRouterStateUnrouted);
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
            ZIKAnyViewRouter *router;
            router = [ZIKRouterToView(AViewInput)
                           performFromSource:source
                           strictConfiguring:^(ZIKViewRouteConfiguration * _Nonnull config,
                                               void (^prepareDest)(void (^)(id<AViewInput> destination)),
                                               void (^prepareModule)(void (^)(ZIKViewRouteConfig *config))) {
                               [self configRouteConfiguration:config source:source];
                               config.routeType = self.routeType;
                               prepareDest(^(id<AViewInput> destination) {
                                   destination.title = @"test title";
                               });
                               config.successHandler = ^(UIViewController<AViewInput> * _Nonnull destination) {
                                   XCTAssertNotNil(destination);
                                   XCTAssert([destination.title isEqualToString:@"test title"]);
                                   [[self class] addChildToParentView:source.view childView:destination.view completion:^{
                                       XCTAssert(self.router.state == ZIKRouterStateRouted);
                                       [destination didMoveToParentViewController:source];
                                       [expectation fulfill];
                                       self.strongRouter = nil;
                                       [self leaveTest];
                                   }];
                               };
                           }];
            self.router = router;
            self.strongRouter = router;
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
            ZIKAnyViewRouter *router;
            router = [ZIKRouterToView(AViewInput)
                           performFromSource:source
                           strictConfiguring:^(ZIKViewRouteConfiguration * _Nonnull config,
                                               void (^prepareDest)(void (^)(id<AViewInput> destination)),
                                               void (^prepareModule)(void (^)(ZIKViewRouteConfig *config))) {
                               [self configRouteConfiguration:config source:source];
                               config.routeType = self.routeType;
                               config.completionHandler = ^(BOOL success, UIViewController *_Nullable destination, ZIKRouteAction  _Nonnull routeAction, NSError * _Nullable error) {
                                   XCTAssertTrue(success);
                                   XCTAssertNil(error);
                                   [[self class] addChildToParentView:source.view childView:destination.view completion:^{
                                       XCTAssert(self.router.state == ZIKRouterStateRouted);
                                       [destination didMoveToParentViewController:source];
                                       [expectation fulfill];
                                       self.strongRouter = nil;
                                       [self leaveTest];
                                   }];
                               };
                           }];
            self.router = router;
            self.strongRouter = router;
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
                               [self configRouteConfiguration:config source:source];
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
            ZIKAnyViewRouter *router;
            router = [ZIKRouterToView(AViewInput)
                           performFromSource:source
                           strictConfiguring:^(ZIKViewRouteConfiguration * _Nonnull config,
                                               void (^prepareDest)(void (^)(id<AViewInput> destination)),
                                               void (^prepareModule)(void (^)(ZIKViewRouteConfig *config))) {
                               [self configRouteConfiguration:config source:source];
                               config.routeType = self.routeType;
                               config.successHandler = ^(UIViewController *_Nonnull destination) {
                                   XCTAssertNotNil(destination);
                                   [[self class] addChildToParentView:source.view childView:destination.view completion:^{
                                       XCTAssert(self.router.state == ZIKRouterStateRouted);
                                       [destination didMoveToParentViewController:source];
                                       [expectation fulfill];
                                       self.strongRouter = nil;
                                       [self leaveTest];
                                   }];
                               };
                           }];
            self.router = router;
            self.strongRouter = router;
        }];
    }
    
    [self waitForExpectationsWithTimeout:500 handler:^(NSError * _Nullable error) {
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
            ZIKAnyViewRouter *router;
            router = [ZIKRouterToView(AViewInput)
                           performFromSource:source
                           strictConfiguring:^(ZIKViewRouteConfiguration * _Nonnull config,
                                               void (^prepareDest)(void (^)(id<AViewInput> destination)),
                                               void (^prepareModule)(void (^)(ZIKViewRouteConfig *config))) {
                               [self configRouteConfiguration:config source:source];
                               config.routeType = self.routeType;
                               config.successHandler = ^(id  _Nonnull destination) {
                                   XCTAssertNotNil(destination);
                                   [successHandlerExpectation fulfill];
                               };
                               config.performerSuccessHandler = ^(UIViewController * _Nonnull destination) {
                                   XCTAssertNotNil(destination);
                                   [performerSuccessHandlerExpectation fulfill];
                                   
                                   [[self class] addChildToParentView:source.view childView:destination.view completion:^{
                                       XCTAssert(self.router.state == ZIKRouterStateRouted);
                                       [self.router removeRouteWithSuccessHandler:^{
                                           XCTAssert(self.router.state == ZIKRouterStateRemoved);
                                           [self.router performRouteWithSuccessHandler:^(UIViewController<AViewInput> *_Nonnull destination) {
                                               XCTAssert(self.router.state == ZIKRouterStateRouted);
                                               XCTAssertNotNil(destination);
                                               [[self class] addChildToParentView:source.view childView:destination.view completion:^{
                                                   [destination didMoveToParentViewController:source];
                                                   self.strongRouter = nil;
                                                   [self leaveTest];
                                               }];
                                           } errorHandler:^(ZIKRouteAction  _Nonnull routeAction, NSError * _Nonnull error) {
                                               
                                           }];
                                           
                                       } errorHandler:nil];
                                   }];
                               };
                           }];
            self.router = router;
            self.strongRouter = router;
        }];
    }
    
    [self waitForExpectationsWithTimeout:500 handler:^(NSError * _Nullable error) {
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
                               [self configRouteConfiguration:config source:source];
                               config.routeType = self.routeType;
                               config.successHandler = ^(id  _Nonnull destination) {
                                   XCTAssert(NO, @"successHandler should not be called");
                               };
                               config.performerSuccessHandler = ^(id  _Nonnull destination) {
                                   XCTAssert(NO, @"successHandler should not be called");
                               };
                               config.errorHandler = ^(ZIKRouteAction  _Nonnull routeAction, NSError * _Nonnull error) {
                                   XCTAssert(self.router.state == ZIKRouterStateUnrouted);
                                   XCTAssertNotNil(error);
                                   [providerErrorExpectation fulfill];
                               };
                               config.performerErrorHandler = ^(ZIKRouteAction  _Nonnull routeAction, NSError * _Nonnull error) {
                                   XCTAssert(self.router.state == ZIKRouterStateUnrouted);
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

@interface ZIKViewRouterPerformAddAsChildWithoutAnimationTests : ZIKViewRouterPerformAddAsChildTests

@end

@implementation ZIKViewRouterPerformAddAsChildWithoutAnimationTests

+ (void)addChildToParentView:(UIView *)parentView childView:(UIView *)childView completion:(void(^)(void))completion {
    childView.frame = parentView.frame;
    childView.backgroundColor = [UIColor redColor];
    [parentView addSubview:childView];
    dispatch_async(dispatch_get_main_queue(), ^{
        if (completion) {
            completion();
        }
    });
}

@end
