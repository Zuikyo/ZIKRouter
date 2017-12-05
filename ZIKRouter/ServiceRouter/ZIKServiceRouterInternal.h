//
//  ZIKServiceRouterInternal.h
//  ZIKRouter
//
//  Created by zuik on 2017/8/9.
//  Copyright © 2017 zuik. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "ZIKServiceRouter.h"

NS_ASSUME_NONNULL_BEGIN

///Internal methods for subclass.
@interface ZIKServiceRouter<__covariant Destination: id, __covariant RouteConfig: ZIKPerformRouteConfiguration *> ()

#pragma mark Required Override

///Register the destination class with those +registerXXX: methods. ZIKServiceRouter will call this method before app did finish launch. If a router was not registered with any service class, there'll be an assert failure.
+ (void)registerRoutableDestination;

#pragma mark Optional Override

///Invoked after auto registration is finished when ZIKROUTER_CHECK is enabled. You can override and validate whether those routable swift protocols used in your module as external dependencies have registered with routers, because we can't enumerate swift protocols at runtime.
+ (void)_autoRegistrationDidFinished;

///Prepare the destination after -prepareDestiantion is invoked.
- (void)prepareDestination:(Destination)destination configuration:(RouteConfig)configuration;

///Check whether destination is preapred correctly.
- (void)didFinishPrepareDestination:(Destination)destination configuration:(RouteConfig)configuration;

#pragma mark State Control

///Maintain the route state when you implement custom route or remove route by overriding -performRouteOnDestination:configuration: or -removeDestination:removeConfiguration:.

///If the router override -performRouteOnDestination:configuration:, the router should maintain the route state with these methods in it.

///Call it when route will perform.
- (void)beginPerformRoute;

///Prepare the destination with the -prepareDestination block in configuration, call -prepareDestination:configuration: and -didFinishPrepareDestination:configuration:.
- (void)prepareForPerformRouteOnDestination:(Destination)destination configuration:(RouteConfig)configuration;

///Call it when route is successfully performed.
- (void)endPerformRouteWithSuccess;
///Call it when route perform failed.
- (void)endPerformRouteWithError:(NSError *)error;

///If the router can remove, override -canRemove, and do removal in -removeDestination:removeConfiguration:, prepare the destination before removing with -prepareDestinationBeforeRemoving.

///Call it when route will remove.
- (void)beginRemoveRoute;
///Prepare the destination with the -prepareDestination block in removeConfiguration before removing the destination when you override -removeDestination:removeConfiguration:.
- (void)prepareDestinationBeforeRemoving;
///Call it when route is successfully removed.
- (void)endRemoveRouteWithSuccess;
///Call it when route remove failed.
- (void)endRemoveRouteWithError:(NSError *)error;

@end

NS_ASSUME_NONNULL_END
