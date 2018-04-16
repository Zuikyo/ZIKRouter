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

@interface ZIKViewRouterTestCase : XCTestCase

@property (nonatomic, weak) ZIKAnyViewRouter *router;
@property (nonatomic) ZIKViewRouteType routeType;

- (void)enterTest:(void(^)(UIViewController *source))testBlock;
- (void)enterSourceViewWithSuccess:(void(^)(UIViewController *source))successHandler;
- (void)leaveSourceView;
- (void)leaveTestViewWithCompletion:(void(^)(BOOL success, ZIKRouteAction  _Nonnull routeAction, NSError * _Nullable error))completion;
- (void)leaveTest;

@end
