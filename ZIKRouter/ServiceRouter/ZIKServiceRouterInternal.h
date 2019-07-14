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

/// Internal methods for subclass.
@interface ZIKServiceRouter<__covariant Destination: id, __covariant RouteConfig: ZIKPerformRouteConfiguration *> ()

#pragma mark Required Override

/// Register the destination class with those +registerXXX: methods. ZIKServiceRouter will call this method before app did finish launching. You can also initialize your module in it. If a router was not registered with any service class, there'll be an assert failure.
+ (void)registerRoutableDestination;

#pragma mark Optional Override

/// Invoked after all registrations are finished when ZIKROUTER_CHECK is enabled, when ZIKROUTER_CHECK is disabled, this won't be invoked. You can override and do some debug checking.
+ (void)_didFinishRegistration;

/// Prepare the destination. When it's removed and routed again, this method may be called more than once. You should check whether the destination is already prepared to avoid unnecessary preparation.
- (void)prepareDestination:(Destination)destination configuration:(RouteConfig)configuration;

/// Check whether destination is prepared correctly.
- (void)didFinishPrepareDestination:(Destination)destination configuration:(RouteConfig)configuration;

#pragma mark Notify Error

+ (void)notifyGlobalErrorWithRouter:(nullable __kindof ZIKServiceRouter *)router action:(ZIKRouteAction)action error:(NSError *)error;

@end

FOUNDATION_EXTERN ZIKServiceRouterType *_Nullable _ZIKServiceRouterToService(Protocol *serviceProtocol);

FOUNDATION_EXTERN ZIKServiceRouterType *_Nullable _ZIKServiceRouterToModule(Protocol *configProtocol);

FOUNDATION_EXTERN ZIKAnyServiceRouterType *_Nullable _ZIKServiceRouterToIdentifier(NSString *identifier);

FOUNDATION_EXTERN Protocol<ZIKServiceRoutable> *_Nullable _routableServiceProtocolFromObject(id object);

FOUNDATION_EXTERN Protocol<ZIKServiceModuleRoutable> *_Nullable _routableServiceModuleProtocolFromObject(id object);

typedef id  _Nullable (^ZIKServiceFactoryBlock)(ZIKPerformRouteConfiguration * _Nonnull);

FOUNDATION_EXTERN void _registerServiceProtocolWithSwiftFactory(Protocol<ZIKServiceRoutable> *serviceProtocol, Class serviceClass, ZIKServiceFactoryBlock block);

FOUNDATION_EXTERN void _registerServiceModuleProtocolWithSwiftFactory(Protocol<ZIKServiceModuleRoutable> *serviceProtocol, Class serviceClass, id(^block)(void));

FOUNDATION_EXTERN void _registerServiceIdentifierWithSwiftFactory(NSString *identifier, Class serviceClass, ZIKServiceFactoryBlock block);

FOUNDATION_EXTERN void _registerServiceModuleIdentifierWithSwiftFactory(NSString *identifier, Class serviceClass, id(^block)(void));

NS_ASSUME_NONNULL_END
