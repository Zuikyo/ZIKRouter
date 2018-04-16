//
//  ZIKViewRouterTestCase.m
//  ZIKRouterDemoTests
//
//  Created by zuik on 2018/4/16.
//  Copyright © 2018 zuik. All rights reserved.
//

#import "ZIKViewRouterTestCase.h"
#import "AppRouteRegistry.h"
#import "SourceViewRouter.h"
#import "AViewRouter.h"
@import ZIKRouter.Internal;

@interface ZIKViewRouterTestCase()
@property (nonatomic, strong) UIViewController *masterViewController;
@property (nonatomic, strong) SourceViewRouter *sourceRouter;
@property (nonatomic, strong) XCTestExpectation *leaveSourceViewExpectation;
@property (nonatomic, strong) XCTestExpectation *leaveTestViewExpectation;
@end

@implementation ZIKViewRouterTestCase

#if !AUTO_REGISTER_ROUTERS

+ (void)load {
    [AViewRouter registerRoutableDestination];
    [SourceViewRouter registerRoutableDestination];
}

#endif

- (void)setUp {
    [super setUp];
    NSAssert(self.sourceRouter == nil, @"Last test didn't leave source view controler");
    NSAssert(self.router == nil, @"Last test didn't leave test view");
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
}

- (void)enterTest:(void(^)(UIViewController *source))testBlock {
    [self enterSourceViewWithSuccess:testBlock];
}

- (void)enterSourceViewWithSuccess:(void(^)(UIViewController *source))successHandler {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Show source View Controller"];
    self.leaveSourceViewExpectation = [self expectationWithDescription:@"Remove source View Controller"];
    self.sourceRouter = [SourceViewRouter performFromSource:self.masterViewController configuring:^(ZIKViewRouteConfig * _Nonnull config) {
        config.routeType = ZIKViewRouteTypePush;
        config.animated = NO;
        config.successHandler = ^(id  _Nonnull destination) {
            NSLog(@"%@: enterSourceView succeed", destination);
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
            NSLog(@"LeaveSourceView succeed");
            [self.leaveSourceViewExpectation fulfill];
        };
    }];
    self.sourceRouter = nil;
}

- (void)leaveTestViewWithCompletion:(void(^)(BOOL success, ZIKRouteAction  _Nonnull routeAction, NSError * _Nullable error))completion {
    XCTAssertNotNil(self.router);
    [self.router removeRouteWithConfiguring:^(ZIKViewRemoveConfiguration * _Nonnull config) {
        config.successHandler = ^{
            NSLog(@"LeaveTestView succeed");
            [self.leaveTestViewExpectation fulfill];
        };
        config.completionHandler = completion;
    }];
    self.router = nil;
}

- (void)leaveTest {
    if (self.router == nil) {
        [self.leaveTestViewExpectation fulfill];
        [self leaveSourceView];
        return;
    }
    if (self.router.state == ZIKRouterStateUnrouted || self.router.state == ZIKRouterStateRemoved) {
        [self.leaveTestViewExpectation fulfill];
        [self leaveSourceView];
        return;
    }
    [self leaveTestViewWithCompletion:^(BOOL success, ZIKRouteAction  _Nonnull routeAction, NSError * _Nullable error) {
        [self leaveSourceView];
    }];
}

@end
