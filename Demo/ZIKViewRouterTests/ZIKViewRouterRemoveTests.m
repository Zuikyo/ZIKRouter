//
//  ZIKViewRouterRemoveTests.m
//  ZIKViewRouterTests
//
//  Created by zuik on 2018/4/17.
//  Copyright © 2018年 zuik. All rights reserved.
//

#import "ZIKViewRouterTestCase.h"
@import ZIKRouter.Internal;
#import "AViewInput.h"

@interface ZIKViewRouterRemoveTests : ZIKViewRouterTestCase

@end

@implementation ZIKViewRouterRemoveTests

- (void)setUp {
    [super setUp];
    
}

- (void)tearDown {
    [super tearDown];
}

- (void)configRemoveConfiguration:(ZIKViewRemoveConfiguration *)configuration {
    configuration.animated = YES;
}

- (void)testRemoveRoute {
    XCTestExpectation *prepareDestinationExpectation = [self expectationWithDescription:@"prepareDestination"];
    XCTestExpectation *successHandlerExpectation = [self expectationWithDescription:@"successHandler"];
    XCTestExpectation *completionHandlerExpectation = [self expectationWithDescription:@"completionHandler"];
    {
        [self enterTest:^(UIViewController *source) {
            self.router = [ZIKRouterToView(AViewInput) performFromSource:source configuring:^(ZIKViewRouteConfiguration * _Nonnull config) {
                config.routeType = self.routeType;
                
                config.performerSuccessHandler = ^(id  _Nonnull destination) {
                    
                    [self.router removeRoute];
                    
                };
            } removing:^(ZIKViewRemoveConfiguration * _Nonnull config) {
                [self configRemoveConfiguration:config];
                config.prepareDestination = ^(id<AViewInput>  _Nonnull destination) {
                    [prepareDestinationExpectation fulfill];
                };
                config.successHandler = ^{
                    [successHandlerExpectation fulfill];
                };
                config.errorHandler = ^(ZIKRouteAction  _Nonnull routeAction, NSError * _Nonnull error) {
                    XCTAssert(NO, @"errorHandler should not be called");
                };
                config.completionHandler = ^(BOOL success, ZIKRouteAction  _Nonnull routeAction, NSError * _Nullable error) {
                    XCTAssertTrue(success);
                    XCTAssertNil(error);
                    [completionHandlerExpectation fulfill];
                    [self leaveTest];
                };
            }];
        }];
    }
    
    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
        !error? : NSLog(@"%@", error);
    }];
}

- (void)testRemoveRouteWithSuccessHandler {
    XCTestExpectation *performerSuccessHandlerExpectation = [self expectationWithDescription:@"performerSuccessHandler"];
    XCTestExpectation *prepareDestinationExpectation = [self expectationWithDescription:@"prepareDestination"];
    XCTestExpectation *successHandlerExpectation = [self expectationWithDescription:@"successHandler"];
    XCTestExpectation *completionHandlerExpectation = [self expectationWithDescription:@"completionHandler"];
    {
        [self enterTest:^(UIViewController *source) {
            self.router = [ZIKRouterToView(AViewInput) performFromSource:source configuring:^(ZIKViewRouteConfiguration * _Nonnull config) {
                config.routeType = self.routeType;
                
                config.performerSuccessHandler = ^(id  _Nonnull destination) {
                    
                    [self.router removeRouteWithSuccessHandler:^{
                        [performerSuccessHandlerExpectation fulfill];
                    } errorHandler:^(ZIKRouteAction  _Nonnull routeAction, NSError * _Nonnull error) {
                        XCTAssert(NO, @"errorHandler should not be called");
                    }];
                    
                };
            } removing:^(ZIKViewRemoveConfiguration * _Nonnull config) {
                [self configRemoveConfiguration:config];
                config.prepareDestination = ^(id<AViewInput>  _Nonnull destination) {
                    [prepareDestinationExpectation fulfill];
                };
                config.successHandler = ^{
                    [successHandlerExpectation fulfill];
                };
                config.errorHandler = ^(ZIKRouteAction  _Nonnull routeAction, NSError * _Nonnull error) {
                    XCTAssert(NO, @"errorHandler should not be called");
                };
                config.completionHandler = ^(BOOL success, ZIKRouteAction  _Nonnull routeAction, NSError * _Nullable error) {
                    XCTAssertTrue(success);
                    XCTAssertNil(error);
                    [completionHandlerExpectation fulfill];
                    [self leaveTest];
                };
            }];
        }];
    }
    
    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
        !error? : NSLog(@"%@", error);
    }];
}

- (void)testRemoveRouteWithCompletion {
    XCTestExpectation *completionExpectation = [self expectationWithDescription:@"completion"];
    XCTestExpectation *prepareDestinationExpectation = [self expectationWithDescription:@"prepareDestination"];
    XCTestExpectation *successHandlerExpectation = [self expectationWithDescription:@"successHandler"];
    XCTestExpectation *completionHandlerExpectation = [self expectationWithDescription:@"completionHandler"];
    {
        [self enterTest:^(UIViewController *source) {
            self.router = [ZIKRouterToView(AViewInput) performFromSource:source configuring:^(ZIKViewRouteConfiguration * _Nonnull config) {
                config.routeType = self.routeType;
                
                config.performerSuccessHandler = ^(id  _Nonnull destination) {
                    
                    [self.router removeRouteWithCompletion:^(BOOL success, ZIKRouteAction  _Nonnull routeAction, NSError * _Nullable error) {
                        XCTAssertTrue(success);
                        XCTAssertNil(error);
                        [completionExpectation fulfill];
                    }];
                    
                };
            } removing:^(ZIKViewRemoveConfiguration * _Nonnull config) {
                [self configRemoveConfiguration:config];
                config.prepareDestination = ^(id<AViewInput>  _Nonnull destination) {
                    [prepareDestinationExpectation fulfill];
                };
                config.successHandler = ^{
                    [successHandlerExpectation fulfill];
                };
                config.errorHandler = ^(ZIKRouteAction  _Nonnull routeAction, NSError * _Nonnull error) {
                    XCTAssert(NO, @"errorHandler should not be called");
                };
                config.completionHandler = ^(BOOL success, ZIKRouteAction  _Nonnull routeAction, NSError * _Nullable error) {
                    XCTAssertTrue(success);
                    XCTAssertNil(error);
                    [completionHandlerExpectation fulfill];
                    [self leaveTest];
                };
            }];
        }];
    }
    
    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
        !error? : NSLog(@"%@", error);
    }];
}

- (void)testRemoveRouteWithConfiguring {
    XCTestExpectation *prepareDestinationExpectation = [self expectationWithDescription:@"prepareDestination"];
    XCTestExpectation *successHandlerExpectation = [self expectationWithDescription:@"successHandler"];
    XCTestExpectation *performerSuccessHandlerExpectation = [self expectationWithDescription:@"performerSuccessHandler"];
    XCTestExpectation *completionHandlerExpectation = [self expectationWithDescription:@"completionHandler"];
    {
        [self enterTest:^(UIViewController *source) {
            self.router = [ZIKRouterToView(AViewInput) performFromSource:source configuring:^(ZIKViewRouteConfiguration * _Nonnull config) {
                config.routeType = self.routeType;
                
                config.performerSuccessHandler = ^(id  _Nonnull destination) {
                    
                    [self.router removeRouteWithConfiguring:^(ZIKViewRemoveConfiguration * _Nonnull config) {
                        config.prepareDestination = ^(id<AViewInput>  _Nonnull destination) {
                            [prepareDestinationExpectation fulfill];
                        };
                        config.successHandler = ^{
                            [successHandlerExpectation fulfill];
                        };
                        config.performerSuccessHandler = ^{
                            [performerSuccessHandlerExpectation fulfill];
                        };
                        config.completionHandler = ^(BOOL success, ZIKRouteAction  _Nonnull routeAction, NSError * _Nullable error) {
                            XCTAssertTrue(success);
                            XCTAssertNil(error);
                            [completionHandlerExpectation fulfill];
                            [self leaveTest];
                        };
                        config.errorHandler = ^(ZIKRouteAction  _Nonnull routeAction, NSError * _Nonnull error) {
                            XCTAssert(NO, @"errorHandler should not be called");
                        };
                        config.performerErrorHandler = ^(ZIKRouteAction  _Nonnull routeAction, NSError * _Nonnull error) {
                            XCTAssert(NO, @"errorHandler should not be called");
                        };
                    }];
                    
                };
            } removing:^(ZIKViewRemoveConfiguration * _Nonnull config) {
                [self configRemoveConfiguration:config];
                config.prepareDestination = ^(id<AViewInput>  _Nonnull destination) {
                    XCTAssert(NO, @"prepareDestination is overrided");
                };
                config.successHandler = ^{
                    XCTAssert(NO, @"successHandler is overrided");
                };
                config.errorHandler = ^(ZIKRouteAction  _Nonnull routeAction, NSError * _Nonnull error) {
                    XCTAssert(NO, @"errorHandler should not be called");
                };
                config.completionHandler = ^(BOOL success, ZIKRouteAction  _Nonnull routeAction, NSError * _Nullable error) {
                    XCTAssert(NO, @"completionHandler is overrided");
                };
            }];
        }];
    }
    
    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
        !error? : NSLog(@"%@", error);
    }];
}

@end

@interface ZIKViewRouterRemoveWithoutAnimationTests : ZIKViewRouterRemoveTests

@end

@implementation ZIKViewRouterRemoveWithoutAnimationTests

- (void)setUp {
    [super setUp];
    
}

- (void)tearDown {
    [super tearDown];
}

- (void)configRemoveConfiguration:(ZIKViewRemoveConfiguration *)configuration {
    [super configRemoveConfiguration:configuration];
    configuration.animated = NO;
}
@end

@interface ZIKViewRouterRemovePushTests : ZIKViewRouterRemoveTests

@end

@implementation ZIKViewRouterRemovePushTests

- (void)setUp {
    [super setUp];
    self.routeType = ZIKViewRouteTypePush;
}

- (void)tearDown {
    [super tearDown];
}

@end

@interface ZIKViewRouterRemovePushWithoutAnimationTests : ZIKViewRouterRemoveWithoutAnimationTests

@end

@implementation ZIKViewRouterRemovePushWithoutAnimationTests

- (void)setUp {
    [super setUp];
    self.routeType = ZIKViewRouteTypePush;
}

- (void)tearDown {
    [super tearDown];
}

@end

@interface ZIKViewRouterRemoveShowTests : ZIKViewRouterRemoveTests

@end

@implementation ZIKViewRouterRemoveShowTests

- (void)setUp {
    [super setUp];
    self.routeType = ZIKViewRouteTypeShow;
}

- (void)tearDown {
    [super tearDown];
}

@end

@interface ZIKViewRouterRemoveShowWithoutAnimationTests : ZIKViewRouterRemoveWithoutAnimationTests

@end

@implementation ZIKViewRouterRemoveShowWithoutAnimationTests

- (void)setUp {
    [super setUp];
    self.routeType = ZIKViewRouteTypeShow;
}

- (void)tearDown {
    [super tearDown];
}

@end
