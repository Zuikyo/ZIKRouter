//
//  ZIKRouterTests.m
//  ZIKRouterTests
//
//  Created by zuik on 2018/4/11.
//  Copyright © 2018年 zuik. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "AppRouteRegistry.h"
@import ZIKRouter;
@import ZIKRouter.Internal;
#import "SourceViewRouter.h"
#import "AViewInput.h"
#import "AViewRouter.h"

@interface ZIKRouterTests : XCTestCase
@property (nonatomic, strong) UIViewController *masterViewController;
@property (nonatomic, strong) SourceViewRouter *sourceRouter;
@property (nonatomic, strong) XCTestExpectation *leaveSourceViewExpectation;
@property (nonatomic, strong) XCTestExpectation *leaveTestViewExpectation;
@property (nonatomic, weak) ZIKDestinationViewRouter(id<AViewInput>) *router;
@property (nonatomic) ZIKViewRouteType routeType;
@end

@implementation ZIKRouterTests

#if !AUTO_REGISTER_ROUTERS

+ (void)load {
    [AViewRouter registerRoutableDestination];
    [SourceViewRouter registerRoutableDestination];
}

#endif

- (void)setUp {
    [super setUp];
    if (self.masterViewController == nil) {
        UISplitViewController *root = (UISplitViewController *)[UIApplication sharedApplication].keyWindow.rootViewController;
        XCTAssertTrue([root isKindOfClass:[UISplitViewController class]]);
        UINavigationController *navigationController = [root.viewControllers firstObject];
        XCTAssertTrue([navigationController isKindOfClass:[UINavigationController class]]);
        self.masterViewController = [navigationController.viewControllers firstObject];
    }
    
    self.routeType = ZIKViewRouteTypePresentModally;
    self.leaveTestViewExpectation = [self expectationWithDescription:@"Remove test View Controller"];
}

- (void)tearDown {
    [super tearDown];
    self.leaveSourceViewExpectation = nil;
    self.leaveTestViewExpectation = nil;
    self.sourceRouter = nil;
    self.router = nil;
}

- (void)enterSourceViewWithSuccess:(void(^)(UIViewController *source))successHandler {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Show source View Controller"];
    self.leaveSourceViewExpectation = [self expectationWithDescription:@"Remove source View Controller"];
    self.sourceRouter = [SourceViewRouter performFromSource:self.masterViewController configuring:^(ZIKViewRouteConfig * _Nonnull config) {
        config.routeType = ZIKViewRouteTypePush;
        config.animated = NO;
        config.successHandler = ^(id  _Nonnull destination) {
            [expectation fulfill];
            if (successHandler) {
                successHandler(destination);
            }
        };
    }];
}

- (void)leaveSourceView {
    [self.sourceRouter removeRouteWithConfiguring:^(ZIKViewRemoveConfiguration * _Nonnull config) {
        config.animated = NO;
        config.successHandler = ^{
            [self.leaveSourceViewExpectation fulfill];
        };
    }];
    self.sourceRouter = nil;
}

- (void)leaveTestViewWithSuccess:(void(^)(void))successHandler {
    XCTAssertNotNil(self.router);
    [self.router removeRouteWithSuccessHandler:^{
        XCTAssertNil(self.router);
        [self.leaveTestViewExpectation fulfill];
        if (successHandler) {
            successHandler();
        }
    } errorHandler:nil];
    self.router = nil;
}

- (void)leaveTest {
    [self leaveTestViewWithSuccess:^{
        [self leaveSourceView];
    }];
}

- (void)testPerformWithCompletionHandler {
    XCTestExpectation *expectation = [self expectationWithDescription:@"completionHandler"];
    {
        [self enterSourceViewWithSuccess:^(UIViewController *source) {
            self.router = [ZIKRouterToView(AViewInput) performFromSource:source configuring:^(ZIKViewRouteConfiguration * _Nonnull config) {
                config.routeType = self.routeType;
                config.completionHandler = ^(BOOL success, id  _Nullable destination, ZIKRouteAction  _Nonnull routeAction, NSError * _Nullable error) {
                    XCTAssertTrue(success);
                    if (success) {
                        [expectation fulfill];
                    }
                    [self leaveTest];
                };
            }];
        }];
    }
    
    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
        
    }];
}

- (void)testPerformWithSuccess {
    XCTestExpectation *expectation = [self expectationWithDescription:@"completionHandler"];
    {
        [self enterSourceViewWithSuccess:^(UIViewController *source) {
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
        
    }];
}

- (void)testPerformWithPrepareDestination {
    XCTestExpectation *expectation = [self expectationWithDescription:@"completionHandler"];
    {
        [self enterSourceViewWithSuccess:^(UIViewController *source) {
            self.router = [ZIKRouterToView(AViewInput) performFromSource:source configuring:^(ZIKViewRouteConfiguration * _Nonnull config) {
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
        
    }];
}

@end
