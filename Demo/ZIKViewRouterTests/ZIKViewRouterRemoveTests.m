//
//  ZIKViewRouterRemoveTests.m
//  ZIKViewRouterTests
//
//  Created by zuik on 2018/4/17.
//  Copyright © 2018 zuik. All rights reserved.
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

- (void)configRouteConfiguration:(ZIKViewRouteConfiguration *)configuration source:(UIViewController *)source {
    configuration.animated = NO;
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
            self.router = [ZIKRouterToView(AViewInput) performPath:[self pathFromSource:source] configuring:^(ZIKViewRouteConfiguration * _Nonnull config) {
                [self configRouteConfiguration:config source:source];
                
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
            self.router = [ZIKRouterToView(AViewInput) performPath:[self pathFromSource:source] configuring:^(ZIKViewRouteConfiguration * _Nonnull config) {
                [self configRouteConfiguration:config source:source];
                
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
            self.router = [ZIKRouterToView(AViewInput) performPath:[self pathFromSource:source] configuring:^(ZIKViewRouteConfiguration * _Nonnull config) {
                [self configRouteConfiguration:config source:source];
                
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
            self.router = [ZIKRouterToView(AViewInput) performPath:[self pathFromSource:source] configuring:^(ZIKViewRouteConfiguration * _Nonnull config) {
                [self configRouteConfiguration:config source:source];
                
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

@interface ZIKViewRouterRemovePresentAsPopoverTests : ZIKViewRouterRemoveTests

@end

@implementation ZIKViewRouterRemovePresentAsPopoverTests

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

@end

@interface ZIKViewRouterRemovePresentAsPopoverWithoutAnimationTests : ZIKViewRouterRemoveWithoutAnimationTests

@end

@implementation ZIKViewRouterRemovePresentAsPopoverWithoutAnimationTests

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

@end

@interface ZIKViewRouterRemovePushTests : ZIKViewRouterRemoveTests

@end

@implementation ZIKViewRouterRemovePushTests

- (void)setUp {
    [super setUp];
    self.routeType = ZIKViewRouteTypePush;
}

@end

@interface ZIKViewRouterRemovePushWithoutAnimationTests : ZIKViewRouterRemoveWithoutAnimationTests

@end

@implementation ZIKViewRouterRemovePushWithoutAnimationTests

- (void)setUp {
    [super setUp];
    self.routeType = ZIKViewRouteTypePush;
}

@end

@interface ZIKViewRouterRemoveShowTests : ZIKViewRouterRemoveTests

@end

@implementation ZIKViewRouterRemoveShowTests

- (void)setUp {
    [super setUp];
    self.routeType = ZIKViewRouteTypeShow;
}

@end

@interface ZIKViewRouterRemoveShowDetailTests : ZIKViewRouterRemoveTests

@end

@implementation ZIKViewRouterRemoveShowDetailTests

- (void)setUp {
    [super setUp];
    self.routeType = ZIKViewRouteTypeShowDetail;
    if (UIUserInterfaceIdiomPad == UI_USER_INTERFACE_IDIOM()) {
        //Can't remove show detail in iPad, don't need to test
        self.routeType = ZIKViewRouteTypeShow;
    }
}

+ (BOOL)allowLeaveTestViewFailing {
    if (UIUserInterfaceIdiomPad == UI_USER_INTERFACE_IDIOM()) {
        return YES;
    }
    return NO;
}

@end

@interface ZIKViewRouterRemoveCustomTests : ZIKViewRouterRemoveTests

@end

@implementation ZIKViewRouterRemoveCustomTests

- (void)setUp {
    [super setUp];
    self.routeType = ZIKViewRouteTypeCustom;
}

@end
