//
//  ZIKViewRouteRegistry.h
//  ZIKRouter
//
//  Created by zuik on 2017/11/15.
//  Copyright © 2017 zuik. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#if __has_include("ZIKViewRouter.h")

#import "ZIKRouteRegistry.h"

NS_ASSUME_NONNULL_BEGIN

@class ZIKViewRoute;

/// Registry for view routers.
@interface ZIKViewRouteRegistry : ZIKRouteRegistry

/**
 Enumerate all view routers. You can notify custom events to view routers with it.
 
 @param handler The enumerator gives subclasses of ZIKViewRouter and ZIKViewRoute object.
 */
+ (void)enumerateAllViewRouters:(void(NS_NOESCAPE ^)(Class _Nullable routerClass, ZIKViewRoute * _Nullable route))handler;

@end

NS_ASSUME_NONNULL_END

#endif
