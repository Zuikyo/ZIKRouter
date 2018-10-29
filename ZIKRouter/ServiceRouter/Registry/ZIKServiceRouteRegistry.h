//
//  ZIKServiceRouteRegistry.h
//  ZIKRouter
//
//  Created by zuik on 2017/11/16.
//  Copyright © 2017 zuik. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "ZIKRouteRegistry.h"

NS_ASSUME_NONNULL_BEGIN

@class ZIKServiceRoute;

/// Registry for service routers.
@interface ZIKServiceRouteRegistry : ZIKRouteRegistry

/**
 Enumerate all service routers. You can notify custom events to service routers with it.

 @param handler The enumerator gives subclasses of ZIKServiceRouter and ZIKServiceRoute object.
 */
+ (void)enumerateAllServiceRouters:(void(NS_NOESCAPE ^)(Class _Nullable routerClass, ZIKServiceRoute * _Nullable route))handler;

@end

NS_ASSUME_NONNULL_END
