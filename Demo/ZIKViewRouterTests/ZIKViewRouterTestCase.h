//
//  ZIKViewRouterTestCase.h
//  ZIKRouterDemo
//
//  Created by zuik on 2018/4/16.
//  Copyright © 2018 zuik. All rights reserved.
//

#import <XCTest/XCTest.h>
@import ZIKRouter;
#import "AViewInput.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZIKViewRouterTestCase : XCTestCase

@property (nonatomic, weak, nullable) ZIKAnyViewRouter *router;
@property (nonatomic) ZIKViewRouteType routeType;

- (void)enterTest:(void(^)(UIViewController *source))testBlock;
- (void)enterSourceViewWithSuccess:(void(^)(UIViewController *source))successHandler;
- (void)leaveSourceView;
- (void)leaveTestViewWithCompletion:(void(^)(BOOL success, ZIKRouteAction  _Nonnull routeAction, NSError * _Nullable error))completion;
- (void)leaveTest;

- (ZIKViewRoutePath *)pathFromSource:(UIViewController *)source;

#pragma mark Override

+ (BOOL)allowLeaveTestViewFailing;

/// If the router complete synchronously, self.router is not set when completion handler is called, then access self.router in handler block will fail. Use this to access self.router in block.
- (void)handle:(void(^)(void))block;

#pragma mark Private

@property (nonatomic, strong, nullable) ZIKAnyViewRouter *strongRouter;
@property (nonatomic, strong, readonly) XCTestExpectation *leaveTestViewExpectation;

@end

NS_ASSUME_NONNULL_END
