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
@import ZIKRouter.Internal;

@interface ZIKViewRouterTestCase()
@property (nonatomic, strong) UIViewController *masterViewController;
@property (nonatomic, strong) SourceViewRouter *sourceRouter;
@property (nonatomic, strong) XCTestExpectation *leaveSourceViewExpectation;
@property (nonatomic, strong) XCTestExpectation *leaveTestViewExpectation;
@end

@implementation ZIKViewRouterTestCase

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
    ZIKViewRouter.globalErrorHandler = ^(__kindof ZIKViewRouter * _Nullable router,
                                         ZIKRouteAction  _Nonnull action,
                                         NSError * _Nonnull error) {
        NSLog(@"❌ZIKRouter Error: router's action (%@) catch error! code:%@, description: %@,\nrouter:(%@)", action, @(error.code), error.localizedDescription,router);
    };
}

- (void)tearDown {
    [super tearDown];
    NSAssert(self.sourceRouter == nil, @"Didn't leave source view controler");
    NSAssert(self.router == nil, @"Didn't leave test view");
    self.sourceRouter = nil;
    self.router = nil;
    self.strongRouter = nil;
    self.leaveSourceViewExpectation = nil;
    self.leaveTestViewExpectation = nil;
    ZIKViewRouter.globalErrorHandler = nil;
}

- (void)setRouter:(ZIKAnyViewRouter *)router {
    _router = router;
    self.strongRouter = router;
}

- (void)handle:(void(^)(void))block {
    if (block == nil) {
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        block();
    });
}

- (ZIKViewRoutePath *)pathFromSource:(UIViewController *)source {
    id<ZIKViewRouteSource> s = source;
    if (self.routeType == ZIKViewRouteTypeAddAsSubview) {
        s = source.view;
    }
    return [[ZIKViewRoutePath alloc] initWithRouteType:self.routeType source:s];
}

- (void)enterTest:(void(^)(UIViewController *source))testBlock {
    self.leaveSourceViewExpectation = [self expectationWithDescription:@"Remove source View Controller"];
    self.leaveSourceViewExpectation.assertForOverFulfill = NO;
    [self enterSourceViewWithSuccess:testBlock];
}

- (void)enterSourceViewWithSuccess:(void(^)(UIViewController *source))successHandler {
    self.sourceRouter = [SourceViewRouter performPath:ZIKViewRoutePath.pushFrom(self.masterViewController) configuring:^(ZIKViewRouteConfig * _Nonnull config) {
        config.animated = NO;
        config.successHandler = ^(id  _Nonnull destination) {
            NSLog(@"%@: enterSourceView succeed", destination);
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
        config.errorHandler = ^(ZIKRouteAction  _Nonnull routeAction, NSError * _Nonnull error) {
            NSLog(@"LeaveTestView failed");
            if ([[self class] allowLeaveTestViewFailing]) {
                [self.leaveTestViewExpectation fulfill];
            }
        };
        config.completionHandler = completion;
    }];
    self.strongRouter = nil;
}

+ (BOOL)allowLeaveTestViewFailing {
    return NO;
}

- (void)leaveTest {
    if (self.router == nil) {
        self.strongRouter = nil;
        [self.leaveTestViewExpectation fulfill];
        [self leaveSourceView];
        return;
    }
    if (self.router.state == ZIKRouterStateUnrouted || self.router.state == ZIKRouterStateRemoved) {
        self.strongRouter = nil;
        [self.leaveTestViewExpectation fulfill];
        [self leaveSourceView];
        return;
    }
    [self leaveTestViewWithCompletion:^(BOOL success, ZIKRouteAction  _Nonnull routeAction, NSError * _Nullable error) {
        [self leaveSourceView];
    }];
}

@end
