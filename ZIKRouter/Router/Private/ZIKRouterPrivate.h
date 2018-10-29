//
//  ZIKRouterPrivate.h
//  ZIKRouter
//
//  Created by zuik on 2018/4/19.
//  Copyright © 2018 zuik. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "ZIKRouter.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZIKRouter () {
    @protected ZIKRemoveRouteConfiguration *_removeConfiguration;
}

+ (ZIKPerformRouteStrictConfiguration *)defaultRouteStrictConfigurationFor:(ZIKPerformRouteConfiguration *)configuration;

+ (ZIKRemoveRouteStrictConfiguration *)defaultRemoveStrictConfigurationFor:(ZIKRemoveRouteConfiguration *)configuration;

#pragma mark Internal Methods

/// Change state.
- (void)notifyRouteState:(ZIKRouterState)state;

/// Call sucessHandler and performerSuccessHandler. You should use `-endPerformRouteWithSuccess` and `-endRemoveRouteWithSuccess` instead of this method, unless you wan't to write custom state control.
- (void)notifySuccessWithAction:(ZIKRouteAction)routeAction;

/// Call errorHandler and performerErrorHandler. You should use `-endPerformRouteWithError:` instead of this method.
- (void)notifyError:(NSError *)error routeAction:(ZIKRouteAction)routeAction;

+ (void)notifyError_invalidProtocolWithAction:(ZIKRouteAction)action errorDescription:(NSString *)format ,...;
- (void)notifyError_invalidConfigurationWithAction:(ZIKRouteAction)action errorDescription:(NSString *)format ,...;
- (void)notifyError_actionFailedWithAction:(ZIKRouteAction)action errorDescription:(NSString *)format ,...;
- (void)notifyError_overRouteWithAction:(ZIKRouteAction)action errorDescription:(NSString *)format ,...;
- (void)notifyError_infiniteRecursionWithAction:(ZIKRouteAction)action errorDescription:(NSString *)format ,...;

@end

NS_ASSUME_NONNULL_END
