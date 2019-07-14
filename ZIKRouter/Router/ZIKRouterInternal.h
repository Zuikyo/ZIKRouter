//
//  ZIKRouterInternal.h
//  ZIKRouter
//
//  Created by zuik on 2017/5/24.
//  Copyright © 2017 zuik. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "ZIKRouter.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZIKRouteConfiguration ()
/**
 Prepare the destination from the router internal before `prepareDestination:configuration:`.
 
 When it's removed and routed again, this method may be called more than once. You should check whether the destination is already prepared to avoid unnecessary preparation.
 */
@property (nonatomic, copy, nullable) void(^_prepareDestination)(id destination);
@end

@interface ZIKServiceMakeableConfiguration<__covariant Destination> ()
/**
 Prepare the destination from the router internal before `prepareDestination:configuration:`.
 
 When it's removed and routed again, this method may be called more than once. You should check whether the destination is already prepared to avoid unnecessary preparation.
 */
@property (nonatomic, copy, nullable) void(^_prepareDestination)(Destination destination);
@end

#define ZIX_ADD_CATEGORY(CLASS, Protocol)    \
@interface CLASS (Protocol) <Protocol>    \
@end    \
@implementation CLASS (Protocol) \
@end    \

/// Internal methods for subclass.
@interface ZIKRouter<__covariant Destination: id, __covariant RouteConfig: ZIKPerformRouteConfiguration *, __covariant RemoveConfig: ZIKRemoveRouteConfiguration *> ()
/// Previous state.
@property (nonatomic, readonly, assign) ZIKRouterState preState;
/// Subclass can get the real configuration to avoid unnecessary copy.
@property (nonatomic, readonly, copy) RouteConfig original_configuration;
@property (nonatomic, readonly, copy) RemoveConfig original_removeConfiguration;
/// Destination after performed. The router only keeps weak reference to the destination, the performer is responsible for holding it if needed.
@property (nonatomic, readonly, weak, nullable) Destination destination;

#pragma mark Required Override
/// Methods for ZIKRouter subclass.

/// Create destination and initialize it with configuration. If the configuration is invalid, return nil to make this route failed.
- (nullable Destination)destinationWithConfiguration:(RouteConfig)configuration;

#pragma mark Optional Override

/// If the router use a custom configuration, override this and return the configuration.
+ (RouteConfig)defaultRouteConfiguration;

/// If the router use a custom configuration, override this and return the configuration.
+ (RemoveConfig)defaultRemoveConfiguration;

#pragma mark Advanced Override

/**
 If a router need to perform on a specific thread, override this and call [super performWithConfiguration:configuration] in that thread.
 
 If the destination should be create asynchronously, override this and then:
 
 1. Use -destinationWithConfiguration: to create destination
 2. Check destination for nil, if destination is nil, end perform with DestinationUnavailable error
 3. Attach destination to router with -attachDestination:
 4. Call -performRouteOnDestination:configuration:
 */
- (void)performWithConfiguration:(RouteConfig)configuration;

/**
 Perform custom route action.
 
 Steps to use custom route action:
 
 1. Override `-performRouteOnDestination:configuration:`
 
 2. Before performing custom action, call `prepareDestinationForPerforming` to prepare the destination
 
 3. After performing custom action, call `endPerformRouteWithSuccess` or `endPerformRouteWithError` to change router's state
 */
- (void)performRouteOnDestination:(nullable Destination)destination configuration:(RouteConfig)configuration;

/// Check whether can remove route. If can't, return the error message.
- (nullable NSString *)checkCanRemove NS_REQUIRES_SUPER;

/**
 Do custom removing action. If you can undo your route action, such as dismiss a routed view, do removing in this.
 
 Steps to use custom removing action:
 
 1. Override `canRemove` or `canRemoveCustomRoute`, if the service can be removed, return true
 
 2. Override `-removeDestination:removeConfiguration:`, check whether the destination exists, and do unload action
 
 3. Before removing, call `-prepareDestinationBeforeRemoving` to let the performer prepare the destination
 
 4. After removing, call `endRemoveRouteWithSuccess` or `endRemoveRouteWithError:` to change router's state
 */
- (void)removeDestination:(nullable Destination)destination removeConfiguration:(RemoveConfig)removeConfiguration;

/// Whether this router is an abstract router. If a router class is not abstract, there must be a destination class registered with it.
+ (BOOL)isAbstractRouter;

/// Whether this router is an adapter for another router.
+ (BOOL)isAdapter;

#pragma mark Custom Route State Control

/// Maintain the route state when you implement custom route or remove route by overriding -performRouteOnDestination:configuration: or -removeDestination:removeConfiguration:.

/// Prepare the destination before really performing. Use the -prepareDestination block in configuration, and call -prepareDestination:configuration: and -didFinishPrepareDestination:configuration:.
- (void)prepareDestinationForPerforming;

/// Call it when route is successfully performed.
- (void)endPerformRouteWithSuccess;
/// Call it when route perform failed.
- (void)endPerformRouteWithError:(NSError *)error;

/// If the router can remove, override -canRemove, and do removal in -removeDestination:removeConfiguration:, prepare the destination before removing with -prepareDestinationForRemoving.

/// Prepare the destination with the -prepareDestination block in removeConfiguration before really removing the destination when you override -removeDestination:removeConfiguration:.
- (void)prepareDestinationForRemoving;
/// Call it when route is successfully removed.
- (void)endRemoveRouteWithSuccess;
/// Call it when route remove failed.
- (void)endRemoveRouteWithError:(NSError *)error;

/// Attach a destination not created from router. The destination class should be registered with this router.
- (void)attachDestination:(nullable Destination)destination;

#pragma mark Error Handle

/// error from ZIKRouteErrorDomain.
+ (NSError *)routeErrorWithCode:(ZIKRouteError)code localizedDescription:(NSString *)description;
/// error from ZIKRouteErrorDomain.
+ (NSError *)routeErrorWithCode:(ZIKRouteError)code localizedDescriptionFormat:(NSString *)format ,...;
/// error with domain from +errorDomain.
+ (NSError *)errorWithCode:(NSInteger)code userInfo:(nullable NSDictionary *)userInfo;
/// error with domain from +errorDomain.
+ (NSError *)errorWithCode:(NSInteger)code localizedDescription:(NSString *)description;
/// error with domain from +errorDomain.
+ (NSError *)errorWithCode:(NSInteger)code localizedDescriptionFormat:(NSString *)format ,...;

+ (NSString *)errorDomain;

@end

NS_ASSUME_NONNULL_END
