//
//  ZIKViewRouterPrivate.h
//  ZIKRouter
//
//  Created by zuik on 2017/10/21.
//  Copyright © 2017 zuik. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "ZIKViewRouter.h"
#import "ZIKClassCapabilities.h"

NS_ASSUME_NONNULL_BEGIN

/// Private methods.
@interface ZIKViewRouter<__covariant Destination: id, __covariant RouteConfig: ZIKViewRouteConfiguration *> (Private)

#pragma mark Internal Initializer

+ (instancetype)routerFromSegueIdentifier:(NSString *)identifier sender:(nullable id)sender destination:(XXViewController *)destination source:(XXViewController *)source;
+ (instancetype)routerFromSegueIdentifier:(NSString *)identifier sender:(nullable id)sender destination:(XXViewController *)destination source:(XXViewController *)source configuring:(void(^ _Nullable)(__kindof ZIKViewRouteConfiguration *config))configBuilder;
+ (instancetype)routerFromView:(XXView *)destination source:(XXView *)source;
+ (instancetype)routerFromView:(XXView *)destination source:(XXView *)source configuring:(void(^ _Nullable)(__kindof ZIKViewRouteConfiguration *config))configBuilder;

@end

NS_ASSUME_NONNULL_END
