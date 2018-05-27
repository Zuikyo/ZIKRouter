//
//  ZIKViewModuleRouterPerformTests.m
//  ZIKViewRouterTests
//
//  Created by zuik on 2018/4/20.
//  Copyright © 2018 zuik. All rights reserved.
//

#import "ZIKViewRouterTestCase.h"
@import ZIKRouter;
#import "AViewModuleInput.h"

@interface ZIKViewModuleRouterPerformTests : ZIKViewRouterTestCase

@end

@implementation ZIKViewModuleRouterPerformTests

- (void)setUp {
    [super setUp];
}

- (void)configRouteConfiguration:(ZIKViewRouteConfiguration *)configuration source:(UIViewController *)source {
    BOOL supportRouteType = [ZIKRouterToViewModule(AViewModuleInput) supportRouteType:self.routeType];
    XCTAssertTrue(supportRouteType);
    configuration.animated = YES;
}

- (void)testPerformWithPrepareDestination {
    XCTestExpectation *expectation = [self expectationWithDescription:@"prepareDestination"];
    {
        [self enterTest:^(UIViewController *source) {
            self.router = [ZIKRouterToViewModule(AViewModuleInput) performPath:[self pathFromSource:source] configuring:^(ZIKViewRouteConfiguration<AViewModuleInput> * _Nonnull config) {
                [self configRouteConfiguration:config source:source];
                config.title = @"test title";
                [config makeDestinationCompletion:^(id<AViewInput> destination) {
                    XCTAssert([destination.title isEqualToString:@"test title"]);
                }];
                config.prepareDestination = ^(id<AViewInput>  _Nonnull destination) {
                    [expectation fulfill];
                };
                config.successHandler = ^(id<AViewInput>  _Nonnull destination) {
                    XCTAssertNotNil(destination);
                    XCTAssert([destination.title isEqualToString:@"test title"]);
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
            self.router = [ZIKRouterToViewModule(AViewModuleInput) performPath:[self pathFromSource:source] configuring:^(ZIKViewRouteConfiguration<AViewModuleInput> * _Nonnull config) {
                [self configRouteConfiguration:config source:source];
                config.title = @"test title";
                [config makeDestinationCompletion:^(id<AViewInput> destination) {
                    XCTAssert([destination.title isEqualToString:@"test title"]);
                }];
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
            self.router = [ZIKRouterToViewModule(AViewModuleInput) performPath:path configuring:^(ZIKViewRouteConfiguration<AViewModuleInput> * _Nonnull config) {
                [self configRouteConfiguration:config source:source];
                config.title = @"test title";
                [config makeDestinationCompletion:^(id<AViewInput> destination) {
                    XCTAssert([destination.title isEqualToString:@"test title"]);
                }];
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

- (void)testPerformWithSuccessCompletion {
    XCTestExpectation *expectation = [self expectationWithDescription:@"completionHandler"];
    {
        [self enterTest:^(UIViewController *source) {
            self.router = [ZIKRouterToViewModule(AViewModuleInput) performPath:[self pathFromSource:source] completion:^(BOOL success, id<AViewInput>  _Nullable destination, ZIKRouteAction  _Nonnull routeAction, NSError * _Nullable error) {
                XCTAssertTrue(success);
                XCTAssertNil(error);
                [expectation fulfill];
                [self handle:^{
                    XCTAssert(self.router.state == ZIKRouterStateRouted);
                    [self leaveTest];
                }];
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
            ZIKViewRoutePath *path = [[ZIKViewRoutePath alloc] initWithRouteType:self.routeType source:nil];
            self.router = [ZIKRouterToViewModule(AViewModuleInput) performPath:path completion:^(BOOL success, id<AViewInput>  _Nullable destination, ZIKRouteAction  _Nonnull routeAction, NSError * _Nullable error) {
                XCTAssertFalse(success);
                XCTAssertNotNil(error);
                [expectation fulfill];
                [self handle:^{
                    XCTAssert(self.router == nil || self.router.state == ZIKRouterStateUnrouted);
                    [self leaveTest];
                }];
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
            self.router = [ZIKRouterToViewModule(AViewModuleInput) performPath:[self pathFromSource:source] completion:^(BOOL success, id<AViewInput>  _Nullable destination, ZIKRouteAction  _Nonnull routeAction, NSError * _Nullable error) {
                XCTAssertTrue(success);
                XCTAssertNil(error);
                
                [self handle:^{
                    XCTAssert(self.router.state == ZIKRouterStateRouted);
                    [self.router removeRouteWithSuccessHandler:^{
                        XCTAssert(self.router.state == ZIKRouterStateRemoved);
                        [self.router performRouteWithCompletion:^(BOOL success, id  _Nullable destination, ZIKRouteAction  _Nonnull routeAction, NSError * _Nullable error) {
                            XCTAssert(self.router.state == ZIKRouterStateRouted);
                            XCTAssertTrue(success);
                            XCTAssertNil(error);
                            [expectation fulfill];
                            [self leaveTest];
                        }];
                        
                    } errorHandler:nil];
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
    {
        [self enterTest:^(UIViewController *source) {
            self.router = [ZIKRouterToViewModule(AViewModuleInput) performPath:[self pathFromSource:source] completion:^(BOOL success, id<AViewInput>  _Nullable destination, ZIKRouteAction  _Nonnull routeAction, NSError * _Nullable error) {
                XCTAssertTrue(success);
                
                [self handle:^{
                    XCTAssert(self.router.state == ZIKRouterStateRouted);
                    [self.router performRouteWithCompletion:^(BOOL success, id  _Nullable destination, ZIKRouteAction  _Nonnull routeAction, NSError * _Nullable error) {
                        XCTAssert(self.router.state == ZIKRouterStateRouted);
                        XCTAssertFalse(success);
                        XCTAssertNotNil(error);
                        [expectation fulfill];
                        [self leaveTest];
                    }];
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
            self.router = [ZIKRouterToViewModule(AViewModuleInput) performPath:[self pathFromSource:source] configuring:^(ZIKViewRouteConfiguration<AViewModuleInput> * _Nonnull config) {
                [self configRouteConfiguration:config source:source];
                config.title = @"test title";
                [config makeDestinationCompletion:^(id<AViewInput> destination) {
                    XCTAssert([destination.title isEqualToString:@"test title"]);
                }];
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
            self.router = [ZIKRouterToViewModule(AViewModuleInput) performPath:[self pathFromSource:source] configuring:^(ZIKViewRouteConfiguration<AViewModuleInput> * _Nonnull config) {
                [self configRouteConfiguration:config source:source];
                config.title = @"test title";
                [config makeDestinationCompletion:^(id<AViewInput> destination) {
                    XCTAssert([destination.title isEqualToString:@"test title"]);
                }];
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
                            [self.router performRouteWithSuccessHandler:^(id<AViewInput>  _Nonnull destination) {
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
            self.router = [ZIKRouterToViewModule(AViewModuleInput) performPath:path configuring:^(ZIKViewRouteConfiguration<AViewModuleInput> * _Nonnull config) {
                [self configRouteConfiguration:config source:source];
                config.title = @"test title";
                [config makeDestinationCompletion:^(id<AViewInput> destination) {
                    XCTAssert([destination.title isEqualToString:@"test title"]);
                }];
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

- (void)testPerformOnDestinationSuccess {
    XCTestExpectation *successHandlerExpectation = [self expectationWithDescription:@"successHandler"];
    XCTestExpectation *performerSuccessHandlerExpectation = [self expectationWithDescription:@"performerSuccessHandler"];
    XCTestExpectation *completionHandlerExpectation = [self expectationWithDescription:@"completionHandler"];
    {
        [self enterTest:^(UIViewController *source) {
            id destination = [ZIKRouterToViewModule(AViewModuleInput) makeDestination];
            self.router = [ZIKRouterToViewModule(AViewModuleInput) performOnDestination:destination path:[self pathFromSource:source] configuring:^(ZIKViewRouteConfiguration<AViewModuleInput> * _Nonnull config) {
                [self configRouteConfiguration:config source:source];
                config.title = @"test title";
                [config makeDestinationCompletion:^(id<AViewInput> destination) {
                    XCTAssert([destination.title isEqualToString:@"test title"]);
                }];
                config.successHandler = ^(id  _Nonnull destination) {
                    [successHandlerExpectation fulfill];
                };
                config.performerSuccessHandler = ^(id  _Nonnull destination) {
                    [performerSuccessHandlerExpectation fulfill];
                };
                config.completionHandler = ^(BOOL success, id  _Nullable destination, ZIKRouteAction  _Nonnull routeAction, NSError * _Nullable error) {
                    XCTAssertTrue(success);
                    [completionHandlerExpectation fulfill];
                    [self handle:^{
                        [self leaveTest];
                    }];
                };
                config.errorHandler = ^(ZIKRouteAction  _Nonnull routeAction, NSError * _Nonnull error) {
                    XCTAssert(NO, @"errorHandler should not be called");
                };
                config.performerErrorHandler = ^(ZIKRouteAction  _Nonnull routeAction, NSError * _Nonnull error) {
                    XCTAssert(NO, @"performerErrorHandler should not be called");
                };
            }];
        }];
    }
    
    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
        !error? : NSLog(@"%@", error);
    }];
}

- (void)testPerformOnDestinationError {
    XCTestExpectation *errorHandlerExpectation = [self expectationWithDescription:@"errorHandler"];
    XCTestExpectation *performerErrorHandlerExpectation = [self expectationWithDescription:@"performerErrorHandler"];
    XCTestExpectation *completionHandlerExpectation = [self expectationWithDescription:@"completionHandler"];
    {
        [self enterTest:^(UIViewController *source) {
            id invalidDestination = nil;
            self.router = [ZIKRouterToViewModule(AViewModuleInput) performOnDestination:invalidDestination path:[self pathFromSource:source] configuring:^(ZIKViewRouteConfiguration<AViewModuleInput> * _Nonnull config) {
                [self configRouteConfiguration:config source:source];
                config.title = @"test title";
                [config makeDestinationCompletion:^(id<AViewInput> destination) {
                    XCTAssert([destination.title isEqualToString:@"test title"]);
                }];
                config.successHandler = ^(id  _Nonnull destination) {
                    XCTAssert(NO, @"successHandler should not be called");
                };
                config.performerSuccessHandler = ^(id  _Nonnull destination) {
                    XCTAssert(NO, @"performerSuccessHandler should not be called");
                };
                config.completionHandler = ^(BOOL success, id  _Nullable destination, ZIKRouteAction  _Nonnull routeAction, NSError * _Nullable error) {
                    XCTAssertFalse(success);
                    XCTAssertNotNil(error);
                    [completionHandlerExpectation fulfill];
                    [self handle:^{
                        [self leaveTest];
                    }];
                };
                config.errorHandler = ^(ZIKRouteAction  _Nonnull routeAction, NSError * _Nonnull error) {
                    [errorHandlerExpectation fulfill];
                };
                config.performerErrorHandler = ^(ZIKRouteAction  _Nonnull routeAction, NSError * _Nonnull error) {
                    [performerErrorHandlerExpectation fulfill];
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
            self.router = [ZIKRouterToViewModule(AViewModuleInput)
                           performPath:[self pathFromSource:source]
                           strictConfiguring:^(ZIKViewRouteStrictConfiguration * _Nonnull config, ZIKViewRouteConfiguration<AViewModuleInput> * _Nonnull module) {
                               [self configRouteConfiguration:config.configuration source:source];
                               module.title = @"test title";
                               [module makeDestinationCompletion:^(id<AViewInput> destination) {
                                   XCTAssert([destination.title isEqualToString:@"test title"]);
                               }];
                               config.successHandler = ^(id<AViewInput>  _Nonnull destination) {
                                   XCTAssertNotNil(destination);
                                   XCTAssert([destination.title isEqualToString:@"test title"]);
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
            self.router = [ZIKRouterToViewModule(AViewModuleInput)
                           performPath:[self pathFromSource:source]
                           strictConfiguring:^(ZIKViewRouteStrictConfiguration * _Nonnull config, ZIKViewRouteConfiguration<AViewModuleInput> * _Nonnull module) {
                               [self configRouteConfiguration:config.configuration source:source];
                               module.title = @"test title";
                               [module makeDestinationCompletion:^(id<AViewInput> destination) {
                                   XCTAssert([destination.title isEqualToString:@"test title"]);
                               }];
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
            self.router = [ZIKRouterToViewModule(AViewModuleInput)
                           performPath:path
                           strictConfiguring:^(ZIKViewRouteStrictConfiguration * _Nonnull config, ZIKViewRouteConfiguration<AViewModuleInput> * _Nonnull module) {
                               [self configRouteConfiguration:config.configuration source:source];
                               module.title = @"test title";
                               [module makeDestinationCompletion:^(id<AViewInput> destination) {
                                   XCTAssert([destination.title isEqualToString:@"test title"]);
                               }];
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
            self.router = [ZIKRouterToViewModule(AViewModuleInput)
                           performPath:[self pathFromSource:source]
                           strictConfiguring:^(ZIKViewRouteStrictConfiguration * _Nonnull config, ZIKViewRouteConfiguration<AViewModuleInput> * _Nonnull module) {
                               [self configRouteConfiguration:config.configuration source:source];
                               module.title = @"test title";
                               [module makeDestinationCompletion:^(id<AViewInput> destination) {
                                   XCTAssert([destination.title isEqualToString:@"test title"]);
                               }];
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
            self.router = [ZIKRouterToViewModule(AViewModuleInput)
                           performPath:[self pathFromSource:source]
                           strictConfiguring:^(ZIKViewRouteStrictConfiguration * _Nonnull config, ZIKViewRouteConfiguration<AViewModuleInput> * _Nonnull module) {
                               [self configRouteConfiguration:config.configuration source:source];
                               module.title = @"test title";
                               [module makeDestinationCompletion:^(id<AViewInput> destination) {
                                   XCTAssert([destination.title isEqualToString:@"test title"]);
                               }];
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
                                           [self.router performRouteWithSuccessHandler:^(id<AViewInput>  _Nonnull destination) {
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
            self.router = [ZIKRouterToViewModule(AViewModuleInput)
                           performPath:path
                           strictConfiguring:^(ZIKViewRouteStrictConfiguration * _Nonnull config, ZIKViewRouteConfiguration<AViewModuleInput> * _Nonnull module) {
                               [self configRouteConfiguration:config.configuration source:source];
                               module.title = @"test title";
                               [module makeDestinationCompletion:^(id<AViewInput> destination) {
                                   XCTAssert([destination.title isEqualToString:@"test title"]);
                               }];
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

- (void)testStrictPerformOnDestinationSuccess {
    XCTestExpectation *successHandlerExpectation = [self expectationWithDescription:@"successHandler"];
    XCTestExpectation *performerSuccessHandlerExpectation = [self expectationWithDescription:@"performerSuccessHandler"];
    XCTestExpectation *completionHandlerExpectation = [self expectationWithDescription:@"completionHandler"];
    {
        [self enterTest:^(UIViewController *source) {
            id destination = [ZIKRouterToViewModule(AViewModuleInput) makeDestination];
            self.router = [ZIKRouterToViewModule(AViewModuleInput)
                           performOnDestination:destination
                           path:[self pathFromSource:source]
                           strictConfiguring:^(ZIKViewRouteStrictConfiguration * _Nonnull config, ZIKViewRouteConfiguration<AViewModuleInput> * _Nonnull module) {
                               [self configRouteConfiguration:config.configuration source:source];
                               module.title = @"test title";
                               [module makeDestinationCompletion:^(id<AViewInput> destination) {
                                   XCTAssert([destination.title isEqualToString:@"test title"]);
                               }];
                               config.successHandler = ^(id  _Nonnull destination) {
                                   [successHandlerExpectation fulfill];
                               };
                               config.performerSuccessHandler = ^(id  _Nonnull destination) {
                                   [performerSuccessHandlerExpectation fulfill];
                               };
                               config.completionHandler = ^(BOOL success, id  _Nullable destination, ZIKRouteAction  _Nonnull routeAction, NSError * _Nullable error) {
                                   XCTAssertTrue(success);
                                   [completionHandlerExpectation fulfill];
                                   [self handle:^{
                                       [self leaveTest];
                                   }];
                               };
                               config.errorHandler = ^(ZIKRouteAction  _Nonnull routeAction, NSError * _Nonnull error) {
                                   XCTAssert(NO, @"errorHandler should not be called");
                               };
                               config.performerErrorHandler = ^(ZIKRouteAction  _Nonnull routeAction, NSError * _Nonnull error) {
                                   XCTAssert(NO, @"performerErrorHandler should not be called");
                               };
                           }];
        }];
    }
    
    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
        !error? : NSLog(@"%@", error);
    }];
}

- (void)testStrictPerformOnDestinationError {
    XCTestExpectation *errorHandlerExpectation = [self expectationWithDescription:@"errorHandler"];
    XCTestExpectation *performerErrorHandlerExpectation = [self expectationWithDescription:@"performerErrorHandler"];
    XCTestExpectation *completionHandlerExpectation = [self expectationWithDescription:@"completionHandler"];
    {
        [self enterTest:^(UIViewController *source) {
            id invalidDestination = nil;
            self.router = [ZIKRouterToViewModule(AViewModuleInput)
                           performOnDestination:invalidDestination
                           path:[self pathFromSource:source]
                           strictConfiguring:^(ZIKViewRouteStrictConfiguration * _Nonnull config, ZIKViewRouteConfiguration<AViewModuleInput> * _Nonnull module) {
                               [self configRouteConfiguration:config.configuration source:source];
                               module.title = @"test title";
                               [module makeDestinationCompletion:^(id<AViewInput> destination) {
                                   XCTAssert([destination.title isEqualToString:@"test title"]);
                               }];
                               config.successHandler = ^(id  _Nonnull destination) {
                                   XCTAssert(NO, @"successHandler should not be called");
                               };
                               config.performerSuccessHandler = ^(id  _Nonnull destination) {
                                   XCTAssert(NO, @"performerSuccessHandler should not be called");
                               };
                               config.completionHandler = ^(BOOL success, id  _Nullable destination, ZIKRouteAction  _Nonnull routeAction, NSError * _Nullable error) {
                                   XCTAssertFalse(success);
                                   XCTAssertNotNil(error);
                                   [completionHandlerExpectation fulfill];
                                   [self handle:^{
                                       [self leaveTest];
                                   }];
                               };
                               config.errorHandler = ^(ZIKRouteAction  _Nonnull routeAction, NSError * _Nonnull error) {
                                   [errorHandlerExpectation fulfill];
                               };
                               config.performerErrorHandler = ^(ZIKRouteAction  _Nonnull routeAction, NSError * _Nonnull error) {
                                   [performerErrorHandlerExpectation fulfill];
                               };
                           }];
        }];
    }
    
    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
        !error? : NSLog(@"%@", error);
    }];
}

@end

@interface ZIKViewModuleRouterPerformWithoutAnimationTests : ZIKViewModuleRouterPerformTests

@end

@implementation ZIKViewModuleRouterPerformWithoutAnimationTests

- (void)configRouteConfiguration:(ZIKViewRouteConfiguration *)configuration source:(UIViewController *)source {
    [super configRouteConfiguration:configuration source:source];
    configuration.animated = NO;
}

@end

@interface ZIKViewModuleRouterPerformPresentAsPopoverTests : ZIKViewModuleRouterPerformTests

@end

@implementation ZIKViewModuleRouterPerformPresentAsPopoverTests

- (void)setUp {
    [super setUp];
    self.routeType = ZIKViewRouteTypePresentAsPopover;
}

- (ZIKViewRoutePath *)pathFromSource:(UIViewController *)source {
    return ZIKViewRoutePath.presentAsPopoverFrom(source, ^(ZIKViewRoutePopoverConfiguration *popoverConfig) {
        popoverConfig.sourceView = source.view;
        popoverConfig.sourceRect = CGRectMake(0, 0, 50, 10);
    });
}

- (void)testPerformWithSuccessCompletion {
    [self leaveTest];
    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
        !error? : NSLog(@"%@", error);
    }];
}

- (void)testPerformRouteWithSuccessCompletion {
    [self leaveTest];
    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
        !error? : NSLog(@"%@", error);
    }];
}

- (void)testPerformRouteWithErrorCompletion {
    XCTestExpectation *expectation = [self expectationWithDescription:@"completionHandler"];
    expectation.assertForOverFulfill = YES;
    {
        [self enterTest:^(UIViewController *source) {
            self.router = [ZIKRouterToViewModule(AViewModuleInput) performPath:[self pathFromSource:source] configuring:^(ZIKViewRouteConfiguration<AViewModuleInput> * _Nonnull config) {
                [self configRouteConfiguration:config source:source];
                config.performerSuccessHandler = ^(id  _Nonnull destination) {
                    [self handle:^{
                        XCTAssert(self.router.state == ZIKRouterStateRouted);
                        [self.router performRouteWithCompletion:^(BOOL success, id  _Nullable destination, ZIKRouteAction  _Nonnull routeAction, NSError * _Nullable error) {
                            XCTAssert(self.router.state == ZIKRouterStateRouted);
                            XCTAssertFalse(success);
                            XCTAssertNotNil(error);
                            [expectation fulfill];
                            [self leaveTest];
                        }];
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

@interface ZIKViewModuleRouterPerformPresentAsPopoverWithoutAnimationTests : ZIKViewModuleRouterPerformPresentAsPopoverTests

@end

@implementation ZIKViewModuleRouterPerformPresentAsPopoverWithoutAnimationTests

- (void)setUp {
    [super setUp];
    self.routeType = ZIKViewRouteTypePresentAsPopover;
}

- (void)configRouteConfiguration:(ZIKViewRouteConfiguration *)configuration source:(UIViewController *)source {
    [super configRouteConfiguration:configuration source:source];
    configuration.animated = NO;
}

@end

@interface ZIKViewModuleRouterPerformPushTests : ZIKViewModuleRouterPerformTests

@end

@implementation ZIKViewModuleRouterPerformPushTests

- (void)setUp {
    [super setUp];
    self.routeType = ZIKViewRouteTypePush;
}

@end

@interface ZIKViewModuleRouterPerformPushWithoutAnimationTests : ZIKViewModuleRouterPerformWithoutAnimationTests

@end

@implementation ZIKViewModuleRouterPerformPushWithoutAnimationTests

- (void)setUp {
    [super setUp];
    self.routeType = ZIKViewRouteTypePush;
}

@end

@interface ZIKViewModuleRouterPerformShowTests : ZIKViewModuleRouterPerformTests

@end

@implementation ZIKViewModuleRouterPerformShowTests

- (void)setUp {
    [super setUp];
    self.routeType = ZIKViewRouteTypeShow;
}

@end

@interface ZIKViewModuleRouterPerformShowDetailTests : ZIKViewModuleRouterPerformTests

@end

@implementation ZIKViewModuleRouterPerformShowDetailTests

- (void)setUp {
    [super setUp];
    self.routeType = ZIKViewRouteTypeShowDetail;
}

+ (BOOL)allowLeaveTestViewFailing {
    if (UIUserInterfaceIdiomPad == UI_USER_INTERFACE_IDIOM()) {
        return YES;
    }
    return NO;
}

- (void)testPerformWithPerformerSuccess {
    [self leaveTest];
    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
        !error? : NSLog(@"%@", error);
    }];
}

- (void)testPerformRouteWithSuccessCompletion {
    [self leaveTest];
    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
        !error? : NSLog(@"%@", error);
    }];
}

- (void)testStrictPerformWithPerformerSuccess {
    [self leaveTest];
    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
        !error? : NSLog(@"%@", error);
    }];
}

@end

@interface ZIKViewModuleRouterPerformCustomTests : ZIKViewModuleRouterPerformTests

@end

@implementation ZIKViewModuleRouterPerformCustomTests

- (void)setUp {
    [super setUp];
    self.routeType = ZIKViewRouteTypeCustom;
}

@end
