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
#import "ZIKServiceRouterType.h"

NS_ASSUME_NONNULL_BEGIN

///Internal methods for subclass.
@interface ZIKServiceRouter<__covariant Destination: id, __covariant RouteConfig: ZIKPerformRouteConfiguration *> ()

#pragma mark Required Override

///Register the destination class with those +registerXXX: methods. ZIKServiceRouter will call this method before app did finish launch. If a router was not registered with any service class, there'll be an assert failure.
+ (void)registerRoutableDestination;

#pragma mark Optional Override

///Invoked after all registrations are finished when ZIKROUTER_CHECK is enabled, when ZIKROUTER_CHECK is disabled, this won't be invoked. You can override and do some debug checking.
+ (void)_didFinishRegistration;

///Prepare the destination after -prepareDestination is invoked.
- (void)prepareDestination:(Destination)destination configuration:(RouteConfig)configuration;

///Check whether destination is prepared correctly.
- (void)didFinishPrepareDestination:(Destination)destination configuration:(RouteConfig)configuration;

#pragma mark Notify Error

+ (void)notifyGlobalErrorWithRouter:(nullable __kindof ZIKServiceRouter *)router action:(ZIKRouteAction)action error:(NSError *)error;

@end

extern ZIKServiceRouterType *_Nullable _ZIKServiceRouterToService(Protocol *serviceProtocol);

extern ZIKServiceRouterType *_Nullable _ZIKServiceRouterToModule(Protocol *configProtocol);

extern Protocol<ZIKServiceRoutable> *_Nullable _routableServiceProtocolFromObject(id object);

extern Protocol<ZIKServiceModuleRoutable> *_Nullable _routableServiceModuleProtocolFromObject(id object);

NS_ASSUME_NONNULL_END
