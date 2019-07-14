//
//  ZIKRouter.m
//  ZIKRouter
//
//  Created by zuik on 2017/3/2.
//  Copyright © 2017 zuik. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "ZIKRouter.h"
#import "ZIKRouterInternal.h"
#import "ZIKRouterPrivate.h"
#import "ZIKRouteConfigurationPrivate.h"
#import <objc/runtime.h>

ZIKRouteAction const ZIKRouteActionInit = @"ZIKRouteActionInit";
ZIKRouteAction const ZIKRouteActionPerformRoute = @"ZIKRouteActionPerformRoute";
ZIKRouteAction const ZIKRouteActionRemoveRoute = @"ZIKRouteActionRemoveRoute";

NSErrorDomain const ZIKRouteErrorDomain = @"ZIKRouteErrorDomain";

@interface ZIKRouter () {
    dispatch_semaphore_t _stateSema;
    __weak id _destination;
    ZIKRouterState _preState;
}
@property (nonatomic, assign) ZIKRouterState state;
@property (nonatomic, strong, nullable) NSError *error;
@property (nonatomic, copy) ZIKPerformRouteConfiguration *configuration;
@property (nonatomic, copy, nullable) ZIKRemoveRouteConfiguration *removeConfiguration;
@end

@implementation ZIKRouter
@dynamic globalErrorHandler;

- (instancetype)initWithConfiguration:(ZIKPerformRouteConfiguration *)configuration removeConfiguration:(nullable ZIKRemoveRouteConfiguration *)removeConfiguration {
    NSParameterAssert(configuration || [[self class] isAbstractRouter]);
    
    if (self = [super init]) {
        _state = ZIKRouterStateUnrouted;
        _configuration = configuration;
        _removeConfiguration = removeConfiguration;
        _stateSema = dispatch_semaphore_create(1);
    }
    return self;
}

- (instancetype)initWithConfiguring:(void(NS_NOESCAPE ^)(ZIKPerformRouteConfiguration *configuration))configBuilder removing:(void(NS_NOESCAPE ^ _Nullable)(ZIKRemoveRouteConfiguration *configuration))removeConfigBuilder {
    NSParameterAssert(configBuilder);
    ZIKPerformRouteConfiguration *configuration = [[self class] defaultRouteConfiguration];
    if (configBuilder) {
        configBuilder(configuration);
        if (configuration.injected) {
            configuration = configuration.injected;
        }
    }
    _configuration = configuration;
    
    ZIKRemoveRouteConfiguration *removeConfiguration;
    if (removeConfigBuilder) {
        removeConfiguration = self.original_removeConfiguration;
        removeConfigBuilder(removeConfiguration);
        if (removeConfiguration.injected) {
            removeConfiguration = removeConfiguration.injected;
        }
    }
    return [self initWithConfiguration:configuration removeConfiguration:removeConfiguration];
}

- (instancetype)initWithStrictConfiguring:(void (NS_NOESCAPE ^)(ZIKPerformRouteStrictConfiguration<id> * _Nonnull, ZIKPerformRouteConfiguration * _Nonnull))configBuilder
                           strictRemoving:(void (NS_NOESCAPE ^)(ZIKRemoveRouteStrictConfiguration<id> * _Nonnull))removeConfigBuilder {
    NSParameterAssert(configBuilder);
    ZIKPerformRouteConfiguration *configuration = [[self class] defaultRouteConfiguration];
    if (configBuilder) {
        ZIKPerformRouteStrictConfiguration *strictConfig = [[self class] defaultRouteStrictConfigurationFor:configuration];
        configBuilder(strictConfig, configuration);
        if (configuration.injected) {
            configuration = configuration.injected;
        }
    }
    _configuration = configuration;
    
    ZIKRemoveRouteConfiguration *removeConfiguration;
    if (removeConfigBuilder) {
        removeConfiguration = self.original_removeConfiguration;
        ZIKRemoveRouteStrictConfiguration *strictConfig = [[self class] defaultRemoveStrictConfigurationFor:removeConfiguration];
        removeConfigBuilder(strictConfig);
        if (removeConfiguration.injected) {
            removeConfiguration = removeConfiguration.injected;
        }
    }
    return [self initWithConfiguration:configuration removeConfiguration:removeConfiguration];
}

- (void)attachDestination:(id)destination {
    [self willChangeValueForKey:@"destination"];
    _destination = destination;
    [self didChangeValueForKey:@"destination"];
}

- (void)notifyRouteState:(ZIKRouterState)state {
    dispatch_semaphore_wait(_stateSema, DISPATCH_TIME_FOREVER);
    ZIKRouterState oldState = self.state;
    if (oldState == state) {
        dispatch_semaphore_signal(_stateSema);
        return;
    }
    if (state == ZIKRouterStateRouting || state == ZIKRouterStateRemoving) {
        [[self class] increaseRecursiveDepth];
    } else if (state == ZIKRouterStateRemoved) {
        [_configuration removeUserInfo];
    }
    
    [self willChangeValueForKey:@"preState"];
    _preState = oldState;
    [self didChangeValueForKey:@"preState"];
    self.state = state;
    
    if (self.original_configuration.stateNotifier) {
        self.original_configuration.stateNotifier(oldState, state);
    }
    if (state != ZIKRouterStateRouting && state != ZIKRouterStateRemoving) {
        [[self class] decreaseRecursiveDepth];
    }
    dispatch_semaphore_signal(_stateSema);
}

#pragma mark Perform

- (BOOL)canPerform {
    ZIKRouterState state = self.state;
    if (state == ZIKRouterStateUnrouted) {
        return YES;
    } else if (state == ZIKRouterStateRouted) {
        if (self.destination == nil) {
            return YES;
        }
        return ![self shouldRemoveBeforePerform];
    }
    return NO;
}

- (void)performWithConfiguration:(ZIKPerformRouteConfiguration *)configuration {
    NSAssert(self.state == ZIKRouterStateRouting, @"State should be routing in -performWithConfiguration:");
    NSAssert([configuration isKindOfClass:[[[self class] defaultRouteConfiguration] class]], @"When using custom configuration class，you must override +defaultRouteConfiguration to return your custom configuration instance.");
    id destination;
    if ([configuration conformsToProtocol:@protocol(ZIKConfigurationSyncMakeable)]) {
        id<ZIKConfigurationSyncMakeable> makeableConfiguration = (id<ZIKConfigurationSyncMakeable>)configuration;
        id makedDestination = makeableConfiguration.makedDestination;
        if (makedDestination) {
            destination = makedDestination;
        }
    }
    if (destination == nil) {
        destination = [self destinationWithConfiguration:configuration];
    }
    [self attachDestination:destination];
    if (destination == nil) {
        [self endPerformRouteWithError:[ZIKRouter errorWithCode:ZIKRouteErrorDestinationUnavailable localizedDescriptionFormat:@"Destination from router is nil. Maybe your configuration is invalid (%@), or there is a bug in the router.", configuration]];
        return;
    }
    [self performRouteOnDestination:destination configuration:configuration];
}

- (void)performRoute {
    [self performRouteWithSuccessHandler:nil errorHandler:nil];
}

- (void)performRouteWithSuccessHandler:(void(^)(id destination))performerSuccessHandler
                          errorHandler:(void(^)(ZIKRouteAction routeAction, NSError *error))performerErrorHandler {
    NSAssert(self.original_configuration, @"router must has configuration");
    ZIKRouterState state = self.state;
    if (state == ZIKRouterStateRouted && self.destination != nil && [self shouldRemoveBeforePerform]) {
        ZIKRouteAction action = ZIKRouteActionPerformRoute;
        NSString *description = [NSString stringWithFormat:@"%@ 's state is routed, can't perform route before it's removed",self];
        NSError *error = [ZIKRouter errorWithCode:ZIKRouteErrorActionFailed localizedDescription:description];
        [self notifyError_actionFailedWithAction:action errorDescription:@"%@", description];
        if (performerErrorHandler) {
            performerErrorHandler(action,error);
        }
        return;
    } else if (state == ZIKRouterStateRouting) {
        ZIKRouteAction action = ZIKRouteActionPerformRoute;
        NSError *error = [ZIKRouter errorWithCode:ZIKRouteErrorOverRoute localizedDescriptionFormat:@"%@ is routing, can't perform route again",self];
        if (performerErrorHandler) {
            performerErrorHandler(action,error);
        }
        [[self class] notifyGlobalErrorWithRouter:self action:action error:error];
        return;
    } else if (state == ZIKRouterStateRemoving) {
        ZIKRouteAction action = ZIKRouteActionPerformRoute;
        NSError *error = [ZIKRouter errorWithCode:ZIKRouteErrorActionFailed localizedDescriptionFormat:@"%@ 's state is removing, can't perform route again",self];
        if (performerErrorHandler) {
            performerErrorHandler(action,error);
        }
        [[self class] notifyGlobalErrorWithRouter:self action:action error:error];
        return;
    }
    if ([[self class] _validateInfiniteRecursion] == NO) {
        ZIKRouteAction action = ZIKRouteActionPerformRoute;
        NSString *description = [NSString stringWithFormat:@"Infinite recursion for performing route detected. There may be cycle dependencies. Recursive call stack:\n%@",[NSThread callStackSymbols]];
        NSError *error = [ZIKRouter errorWithCode:ZIKRouteErrorInfiniteRecursion localizedDescription:description];
        [self notifyError_infiniteRecursionWithAction:ZIKRouteActionPerformRoute errorDescription:@"%@", description];
        [[self class] decreaseRecursiveDepth];
        if (performerErrorHandler) {
            performerErrorHandler(action,error);
        }
        return;
    }
    [self notifyRouteState:ZIKRouterStateRouting];
    ZIKPerformRouteConfiguration *configuration = self.original_configuration;
    if (performerSuccessHandler) {
        void(^ori_performerSuccessHandler)(id) = configuration.performerSuccessHandler;
        if (ori_performerSuccessHandler) {
            performerSuccessHandler = ^(id destination) {
                ori_performerSuccessHandler(destination);
                performerSuccessHandler(destination);
            };
        }
        configuration.performerSuccessHandler = performerSuccessHandler;
    }
    if (performerErrorHandler) {
        ZIKRouteErrorHandler ori_performerErrorHandler = configuration.performerErrorHandler;
        if (ori_performerErrorHandler) {
            performerErrorHandler = ^(ZIKRouteAction routeAction, NSError *error) {
                ori_performerErrorHandler(routeAction, error);
                performerErrorHandler(routeAction, error);
            };
        }
        configuration.performerErrorHandler = performerErrorHandler;
    }
    [self performWithConfiguration:configuration];
}

- (void)performRouteWithCompletion:(void(^)(BOOL success, id _Nullable destination, ZIKRouteAction routeAction, NSError *_Nullable error))performerCompletion {
    [self performRouteWithSuccessHandler:^(id  _Nonnull destination) {
        if (performerCompletion) {
            performerCompletion(YES, destination, ZIKRouteActionPerformRoute, nil);
        }
    } errorHandler:^(ZIKRouteAction  _Nonnull routeAction, NSError * _Nonnull error) {
        if (performerCompletion) {
            performerCompletion(NO, nil, routeAction, error);
        }
    }];
}

+ (instancetype)performRoute {
    return [self performWithConfiguring:^(ZIKPerformRouteConfiguration *configuration) {
        
    } removing:nil];
}

+ (instancetype)performWithSuccessHandler:(void(^ _Nullable)(id destination))performerSuccessHandler
                             errorHandler:(void(^ _Nullable)(ZIKRouteAction routeAction, NSError *error))performerErrorHandler {
    return [self performWithConfiguring:^(ZIKPerformRouteConfiguration * _Nonnull config) {
        if (performerSuccessHandler) {
            void(^successHandler)(id) = config.performerSuccessHandler;
            if (successHandler) {
                successHandler = ^(id destination) {
                    successHandler(destination);
                    performerSuccessHandler(destination);
                };
            } else {
                successHandler = performerSuccessHandler;
            }
            config.performerSuccessHandler = successHandler;
        }
        if (performerErrorHandler) {
            void(^errorHandler)(ZIKRouteAction, NSError *) = config.performerErrorHandler;
            if (errorHandler) {
                errorHandler = ^(ZIKRouteAction routeAction, NSError *error) {
                    errorHandler(routeAction, error);
                    performerErrorHandler(routeAction, error);
                };
            } else {
                errorHandler = performerErrorHandler;
            }
            config.performerErrorHandler = errorHandler;
        }
    }];
}

+ (nullable instancetype)performWithCompletion:(void(^)(BOOL success, id _Nullable destination, ZIKRouteAction routeAction, NSError *_Nullable error))performerCompletion {
    return [self performWithSuccessHandler:^(id  _Nonnull destination) {
        if (performerCompletion) {
            performerCompletion(YES, destination, ZIKRouteActionPerformRoute, nil);
        }
    } errorHandler:^(ZIKRouteAction  _Nonnull routeAction, NSError * _Nonnull error) {
        if (performerCompletion) {
            performerCompletion(NO, nil, routeAction, error);
        }
    }];
}

+ (nullable instancetype)performWithPreparation:(void(^)(id destination))prepare {
    return [self performWithConfiguring:^(ZIKPerformRouteConfiguration * _Nonnull config) {
        config.prepareDestination = prepare;
    }];
}

+ (instancetype)performWithConfiguring:(void(NS_NOESCAPE ^)(ZIKPerformRouteConfiguration *configuration))configBuilder {
    return [self performWithConfiguring:configBuilder removing:nil];
}

+ (instancetype)performWithConfiguring:(void(NS_NOESCAPE ^)(ZIKPerformRouteConfiguration *configuration))configBuilder removing:(void(NS_NOESCAPE ^)(ZIKRemoveRouteConfiguration *configuration))removeConfigBuilder {
    NSParameterAssert(configBuilder);
    ZIKRouter *router = [[self alloc] initWithConfiguring:configBuilder removing:removeConfigBuilder];
    [router performRoute];
    return router;
}

+ (instancetype)performWithStrictConfiguring:(void (NS_NOESCAPE ^)(ZIKPerformRouteStrictConfiguration<id> * _Nonnull, ZIKPerformRouteConfiguration * _Nonnull))configBuilder {
    return [self performWithStrictConfiguring:configBuilder strictRemoving:nil];
}

+ (instancetype)performWithStrictConfiguring:(void (NS_NOESCAPE ^)(ZIKPerformRouteStrictConfiguration<id> * _Nonnull, ZIKPerformRouteConfiguration * _Nonnull))configBuilder
                              strictRemoving:(void (NS_NOESCAPE ^)(ZIKRemoveRouteStrictConfiguration<id> * _Nonnull))removeConfigBuilder {
    NSParameterAssert(configBuilder);
    ZIKRouter *router = [[self alloc] initWithStrictConfiguring:configBuilder strictRemoving:removeConfigBuilder];
    [router performRoute];
    return router;
}

#pragma mark Remove

- (BOOL)shouldRemoveBeforePerform {
    return NO;
}

- (BOOL)canRemove {
    return [self checkCanRemove] == nil;
}

- (NSString *)checkCanRemove {
    if (!self.destination) {
        if (self.state != ZIKRouterStateRemoved) {
            [self notifyRouteState:ZIKRouterStateRemoved];
        }
        return [NSString stringWithFormat:@"Router can't remove, destination is dealloced. router:%@",self];
    }
    if (self.state != ZIKRouterStateRouted || !self.original_configuration) {
        return [NSString stringWithFormat:@"Router can't remove, it's not performed, current state:%ld router:%@",(long)self.state,self];
    }
    return nil;
}

- (void)removeRoute {
    [self removeRouteWithSuccessHandler:nil errorHandler:nil];
}

- (void)removeRouteWithSuccessHandler:(void(^)(void))performerSuccessHandler
                         errorHandler:(void(^)(ZIKRouteAction routeAction, NSError *error))performerErrorHandler {
    if (self.state != ZIKRouterStateRouted || !self.original_configuration) {
        ZIKRouteAction action = ZIKRouteActionRemoveRoute;
        NSError *error = [ZIKRouter errorWithCode:ZIKRouteErrorActionFailed localizedDescriptionFormat:@"State should be ZIKRouterStateRouted when removeRoute, current state:%ld, configuration:%@",self.state,self.original_configuration];
        if (performerErrorHandler) {
            performerErrorHandler(action,error);
        }
        [[self class] notifyGlobalErrorWithRouter:self action:action error:error];
        return;
    }
    NSString *errorMessage = [self checkCanRemove];
    if (errorMessage != nil) {
        NSString *description = [NSString stringWithFormat:@"%@, configuration:%@",errorMessage,self.original_configuration];
        [self notifyError_actionFailedWithAction:ZIKRouteActionRemoveRoute
                                errorDescription:description];
        if (performerErrorHandler) {
            performerErrorHandler(ZIKRouteActionRemoveRoute,[ZIKRouter errorWithCode:ZIKRouteErrorActionFailed localizedDescription:description]);
        }
        return;
    }
    [self notifyRouteState:ZIKRouterStateRemoving];
    ZIKRemoveRouteConfiguration *configuration = self.original_removeConfiguration;
    if (performerSuccessHandler) {
        void(^ori_performerSuccessHandler)(void) = configuration.performerSuccessHandler;
        if (ori_performerSuccessHandler) {
            performerSuccessHandler = ^{
                ori_performerSuccessHandler();
                performerSuccessHandler();
            };
        }
        configuration.performerSuccessHandler = performerSuccessHandler;
    }
    if (performerErrorHandler) {
        void(^ori_performerErrorHandler)(ZIKRouteAction routeAction, NSError *error) = configuration.performerErrorHandler;
        if (ori_performerErrorHandler) {
            performerErrorHandler = ^(ZIKRouteAction routeAction, NSError *error){
                ori_performerErrorHandler(routeAction, error);
                performerErrorHandler(routeAction, error);
            };
        }
        configuration.performerErrorHandler = performerErrorHandler;
    }
    [self removeDestination:self.destination removeConfiguration:configuration];
}

- (void)removeRouteWithCompletion:(void(^)(BOOL success, ZIKRouteAction routeAction, NSError *_Nullable error))performerCompletion {
    [self removeRouteWithSuccessHandler:^{
        if (performerCompletion) {
            performerCompletion(YES, ZIKRouteActionRemoveRoute, nil);
        }
    } errorHandler:^(ZIKRouteAction routeAction, NSError *error) {
        if (performerCompletion) {
            performerCompletion(NO, routeAction, error);
        }
    }];
}

- (void)removeRouteWithConfiguring:(void(NS_NOESCAPE ^)(ZIKRemoveRouteConfiguration *config))removeConfigBuilder {
    if (self.state != ZIKRouterStateRouted || !self.original_configuration) {
        ZIKRouteAction action = ZIKRouteActionRemoveRoute;
        NSError *error = [ZIKRouter errorWithCode:ZIKRouteErrorActionFailed localizedDescriptionFormat:@"State should be ZIKRouterStateRouted when removeRoute, current state:%ld, configuration:%@",self.state,self.original_configuration];
        [[self class] notifyGlobalErrorWithRouter:self action:action error:error];
        if (removeConfigBuilder) {
            ZIKRemoveRouteConfiguration *configuration = self.original_removeConfiguration;
            removeConfigBuilder(configuration);
            if (configuration.errorHandler) {
                configuration.errorHandler(action, error);
            }
            if (configuration.performerErrorHandler) {
                configuration.performerErrorHandler(action, error);
            }
            if (configuration.completionHandler) {
                configuration.completionHandler(NO, action, error);
            }
        }
        return;
    }
    NSString *errorMessage = [self checkCanRemove];
    if (errorMessage != nil) {
        ZIKRouteAction action = ZIKRouteActionRemoveRoute;
        NSString *description = [NSString stringWithFormat:@"%@, configuration:%@",errorMessage,self.original_configuration];
        [self notifyError_actionFailedWithAction:action
                                errorDescription:description];
        if (removeConfigBuilder) {
            NSError *error = [ZIKRouter errorWithCode:ZIKRouteErrorActionFailed localizedDescription:description];
            ZIKRemoveRouteConfiguration *configuration = self.original_removeConfiguration;
            removeConfigBuilder(configuration);
            if (configuration.errorHandler) {
                configuration.errorHandler(action, error);
            }
            if (configuration.performerErrorHandler) {
                configuration.performerErrorHandler(action, error);
            }
            if (configuration.completionHandler) {
                configuration.completionHandler(NO, action, error);
            }
        }
        return;
    }
    [self notifyRouteState:ZIKRouterStateRemoving];
    ZIKRemoveRouteConfiguration *configuration = self.original_removeConfiguration;
    if (removeConfigBuilder) {
        removeConfigBuilder(configuration);
    }
    [self removeDestination:self.destination removeConfiguration:configuration];
}

- (void)removeRouteWithStrictConfiguring:(void (NS_NOESCAPE ^)(ZIKRemoveRouteStrictConfiguration<id> * _Nonnull))removeConfigBuilder {
    if (self.state != ZIKRouterStateRouted || !self.original_configuration) {
        ZIKRouteAction action = ZIKRouteActionRemoveRoute;
        NSError *error = [ZIKRouter errorWithCode:ZIKRouteErrorActionFailed localizedDescriptionFormat:@"State should be ZIKRouterStateRouted when removeRoute, current state:%ld, configuration:%@",self.state,self.original_configuration];
        [[self class] notifyGlobalErrorWithRouter:self action:action error:error];
        return;
    }
    NSString *errorMessage = [self checkCanRemove];
    if (errorMessage != nil) {
        NSString *description = [NSString stringWithFormat:@"%@, configuration:%@",errorMessage,self.original_configuration];
        [self notifyError_actionFailedWithAction:ZIKRouteActionRemoveRoute
                                errorDescription:description];
        return;
    }
    [self notifyRouteState:ZIKRouterStateRemoving];
    ZIKRemoveRouteConfiguration *configuration = self.original_removeConfiguration;
    if (removeConfigBuilder) {
        ZIKRemoveRouteStrictConfiguration *strictConfig = [[self class] defaultRemoveStrictConfigurationFor:configuration];
        removeConfigBuilder(strictConfig);
    }
    [self removeDestination:self.destination removeConfiguration:configuration];
}

#pragma mark Make Destination

+ (BOOL)canMakeDestination {
    return [self canMakeDestinationSynchronously];
}

+ (nullable id)makeDestinationWithPreparation:(void(^ _Nullable)(id destination))prepare {
    return [self makeDestinationWithConfiguring:^(ZIKPerformRouteConfiguration * _Nonnull config) {
        if (prepare) {
            config.prepareDestination = prepare;
        }
    }];
}

+ (nullable id)makeDestinationWithConfiguring:(void(NS_NOESCAPE ^ _Nullable)(ZIKPerformRouteConfiguration *config))configBuilder {
    NSAssert(self != [ZIKRouter class], @"Only get destination from router subclass");
    if (![self canMakeDestination]) {
        NSAssert1(NO, @"+canMakeDestination return NO, the router (%@) can't makeDestination",self);
        return nil;
    }
    __block id dest;
    ZIKRouter *router = [[self alloc] initWithConfiguring:^(ZIKPerformRouteConfiguration * _Nonnull config) {
        if (configBuilder) {
            configBuilder(config);
        }
        if (config.injected) {
            config = config.injected;
        }
        void(^successHandler)(id destination) = config.performerSuccessHandler;
        config.performerSuccessHandler = ^(id  _Nonnull destination) {
            if (successHandler) {
                successHandler(destination);
            }
            dest = destination;
        };
    } removing:NULL];
    [router performRoute];
    return dest;
}

+ (nullable id)makeDestinationWithStrictConfiguring:(void (NS_NOESCAPE ^)(ZIKPerformRouteStrictConfiguration<id> * _Nonnull, ZIKPerformRouteConfiguration * _Nonnull))configBuilder {
    NSAssert(self != [ZIKRouter class], @"Only get destination from router subclass");
    if (![self canMakeDestination]) {
        NSAssert1(NO, @"+canMakeDestination return NO, the router (%@) can't makeDestination",self);
        return nil;
    }
    __block id dest;
    ZIKRouter *router = [[self alloc] initWithStrictConfiguring:^(ZIKPerformRouteStrictConfiguration *strictConfig, ZIKPerformRouteConfiguration *config) {
        if (configBuilder) {
            configBuilder(strictConfig, config);
        }
        if (config.injected) {
            config = config.injected;
        }
        void(^successHandler)(id destination) = config.performerSuccessHandler;
        config.performerSuccessHandler = ^(id  _Nonnull destination) {
            if (successHandler) {
                successHandler(destination);
            }
            dest = destination;
        };
    } strictRemoving:nil];
    [router performRoute];
    return dest;
}

+ (nullable id)makeDestination {
    return [self makeDestinationWithPreparation:nil];
}

#pragma mark ZIKRouterSubclass

+ (BOOL)isAbstractRouter {
    return self == [ZIKRouter class];
}

+ (BOOL)isAdapter {
    return NO;
}

- (void)performRouteOnDestination:(id)destination configuration:(ZIKPerformRouteConfiguration *)configuration {
    NSAssert(NO, @"Router: %@ must override %@!",[self class],NSStringFromSelector(_cmd));
    [self prepareDestinationForPerforming];
    // Do perform action
    [self endPerformRouteWithSuccess];
}

- (void)removeDestination:(id)destination removeConfiguration:(ZIKRemoveRouteConfiguration *)removeConfiguration {
    NSAssert(NO, @"Router: %@ must override %@!",[self class],NSStringFromSelector(_cmd));
    [self prepareDestinationForRemoving];
    // Do remove action
    [self endRemoveRouteWithSuccess];
}

- (id)destinationWithConfiguration:(ZIKPerformRouteConfiguration *)configuration {
    NSAssert(NO, @"Router: %@ must override %@!",[self class],NSStringFromSelector(_cmd));
    return nil;
}

- (void)prepareDestination:(id)destination configuration:(ZIKPerformRouteConfiguration *)configuration {
    NSAssert([self class] != [ZIKRouter class], @"Prepare destination with its router.");
}

- (void)didFinishPrepareDestination:(id)destination configuration:(ZIKPerformRouteConfiguration *)configuration {
    NSAssert([self class] != [ZIKRouter class], @"Prepare destination with its router.");
}

+ (ZIKPerformRouteConfiguration *)defaultRouteConfiguration {
    NSAssert(NO, @"Router: %@ must override %@!",[self class],NSStringFromSelector(_cmd));
    return nil;
}

+ (ZIKRemoveRouteConfiguration *)defaultRemoveConfiguration {
    NSAssert(NO, @"Router: %@ must override %@!",[self class],NSStringFromSelector(_cmd));
    return nil;
}

+ (ZIKPerformRouteStrictConfiguration *)defaultRouteStrictConfigurationFor:(ZIKPerformRouteConfiguration *)configuration {
    return [[ZIKPerformRouteStrictConfiguration alloc] initWithConfiguration:configuration];
}

+ (ZIKRemoveRouteStrictConfiguration *)defaultRemoveStrictConfigurationFor:(ZIKRemoveRouteConfiguration *)configuration {
    return [[ZIKRemoveRouteStrictConfiguration alloc] initWithConfiguration:configuration];
}

+ (BOOL)canMakeDestinationSynchronously {
    return YES;
}

#pragma mark State Control

- (void)prepareDestinationForPerforming {
    NSAssert(self.destination, @"Destination should not be nil when prepare it.");
    id destination = self.destination;
    if (destination == nil) {
        return;
    }
    ZIKPerformRouteConfiguration *configuration = self.original_configuration;
    if (configuration.prepareDestination) {
        configuration.prepareDestination(destination);
    }
    BOOL hasMakedDestination = NO;
    if ([configuration conformsToProtocol:@protocol(ZIKConfigurationSyncMakeable)]) {
        id<ZIKConfigurationSyncMakeable> makeableConfiguration = (id<ZIKConfigurationSyncMakeable>)configuration;
        if (makeableConfiguration.makedDestination == destination) {
            hasMakedDestination = YES;            
        }
    }
    if (configuration._prepareDestination) {
        configuration._prepareDestination(destination);
    }
    [self prepareDestination:destination configuration:configuration];
    [self didFinishPrepareDestination:destination configuration:configuration];
    if ([configuration conformsToProtocol:@protocol(ZIKConfigurationAsyncMakeable)] && [configuration respondsToSelector:@selector(didMakeDestination)]) {
        id<ZIKConfigurationAsyncMakeable> makeableConfig = (id)configuration;
        void(^didMakeDestination)(id) = makeableConfig.didMakeDestination;
        if (didMakeDestination) {
            makeableConfig.didMakeDestination = nil;
            didMakeDestination(destination);
        }
    }
    if (hasMakedDestination) {
        id<ZIKConfigurationSyncMakeable> makeableConfiguration = (id<ZIKConfigurationSyncMakeable>)configuration;
        makeableConfiguration.makedDestination = nil;
    }
}

- (void)endPerformRouteWithSuccess {
    NSAssert(self.state == ZIKRouterStateRouting, @"state should be routing when end to route.");
    [self notifyRouteState:ZIKRouterStateRouted];
    [self notifySuccessWithAction:ZIKRouteActionPerformRoute];
}

- (void)endPerformRouteWithError:(NSError *)error {
    NSAssert(self.state == ZIKRouterStateRouting, @"state should be routing when end to route.");
    [self notifyRouteState:self.preState];
    [self notifyError:error routeAction:ZIKRouteActionPerformRoute];
}

- (void)prepareDestinationForRemoving {
    NSAssert(self.destination, @"Destination should not be nil when prepare it.");
    id destination = self.destination;
    if (destination == nil) {
        return;
    }
    ZIKRemoveRouteConfiguration *configuration = self.original_removeConfiguration;
    if (configuration.prepareDestination && destination) {
        configuration.prepareDestination(destination);
    }
    if (configuration._prepareDestination && destination) {
        configuration._prepareDestination(destination);
    }
}

- (void)endRemoveRouteWithSuccess {
    NSAssert(self.state == ZIKRouterStateRemoving, @"state should be removing when end remove route.");
    [self notifyRouteState:ZIKRouterStateRemoved];
    [self notifySuccessWithAction:ZIKRouteActionRemoveRoute];
}

- (void)endRemoveRouteWithError:(NSError *)error {
    NSAssert(self.state == ZIKRouterStateRemoving, @"state should be removing when end remove route.");
    [self notifyRouteState:self.preState];
    [self notifyError:error routeAction:ZIKRouteActionRemoveRoute];
}

#pragma mark Error Handle

+ (NSString *)errorDomain {
    return ZIKRouteErrorDomain;
}

+ (NSError *)routeErrorWithCode:(ZIKRouteError)code localizedDescription:(NSString *)description {
    if (description == nil) {
        description = @"";
    }
    return [NSError errorWithDomain:ZIKRouteErrorDomain code:code userInfo:@{NSLocalizedDescriptionKey:description}];
}

+ (NSError *)routeErrorWithCode:(ZIKRouteError)code localizedDescriptionFormat:(NSString *)format ,... {
    va_list argList;
    va_start(argList, format);
    NSString *description = [[NSString alloc] initWithFormat:format arguments:argList];
    va_end(argList);
    return [self routeErrorWithCode:code localizedDescription:description];
}

+ (NSError *)errorWithCode:(NSInteger)code userInfo:(nullable NSDictionary *)userInfo {
    return [NSError errorWithDomain:[self errorDomain] code:code userInfo:userInfo];
}

+ (NSError *)errorWithCode:(NSInteger)code localizedDescription:(NSString *)description {
    NSParameterAssert(description);
    if (description == nil) {
        description = @"";
    }
    return [NSError errorWithDomain:[self errorDomain] code:code userInfo:@{NSLocalizedDescriptionKey:description}];
}

+ (NSError *)errorWithCode:(NSInteger)code localizedDescriptionFormat:(NSString *)format ,... {
    va_list argList;
    va_start(argList, format);
    NSString *description = [[NSString alloc] initWithFormat:format arguments:argList];
    va_end(argList);
    return [self errorWithCode:code localizedDescription:description];
}

- (void)notifySuccessWithAction:(ZIKRouteAction)routeAction {
    [self notifySuccessToProviderWithAction:routeAction];
    [self notifySuccessToPerformerWithAction:routeAction];
}

- (void)notifyError:(NSError *)error routeAction:(ZIKRouteAction)routeAction {
    NSAssert(self.state != ZIKRouterStateRouting && self.state != ZIKRouterStateRemoving, @"State should not be routing or removing when action failed.");
    [self notifyErrorToProvider:error routeAction:routeAction];
    [self notifyErrorToPerformer:error routeAction:routeAction];
    [[self class] notifyGlobalErrorWithRouter:self action:routeAction error:error];
}

- (void)notifySuccessToProviderWithAction:(ZIKRouteAction)routeAction {
    NSParameterAssert(routeAction);
    NSParameterAssert(self.destination);
    if ([routeAction isEqualToString:ZIKRouteActionRemoveRoute]) {
        if (self.original_removeConfiguration.successHandler) {
            self.original_removeConfiguration.successHandler();
        }
        if (self.original_removeConfiguration.completionHandler) {
            self.original_removeConfiguration.completionHandler(YES, routeAction, nil);
        }
        return;
    }
    if (self.original_configuration.successHandler) {
        self.original_configuration.successHandler(self.destination);
    }
    if (self.original_configuration.completionHandler) {
        self.original_configuration.completionHandler(YES, self.destination, routeAction, nil);
    }
}

- (void)notifyErrorToProvider:(NSError *)error routeAction:(ZIKRouteAction)routeAction {
    NSParameterAssert(error);
    NSParameterAssert(routeAction);
    self.error = error;
    if ([routeAction isEqualToString:ZIKRouteActionRemoveRoute]) {
        if (self.original_removeConfiguration.errorHandler) {
            self.original_removeConfiguration.errorHandler(routeAction, error);
        }
        if (self.original_removeConfiguration.completionHandler) {
            self.original_removeConfiguration.completionHandler(NO, routeAction, error);
        }
        return;
    }
    if (self.original_configuration.errorHandler) {
        self.original_configuration.errorHandler(routeAction, error);
    }
    if (self.original_configuration.completionHandler) {
        self.original_configuration.completionHandler(NO, self.destination, routeAction, error);
    }
}

- (void)notifySuccessToPerformerWithAction:(ZIKRouteAction)routeAction {
    NSParameterAssert(routeAction);
    NSParameterAssert(self.destination);
    if ([routeAction isEqualToString:ZIKRouteActionRemoveRoute]) {
        ZIKRemoveRouteConfiguration *configuration = self.original_removeConfiguration;
        if (configuration.performerErrorHandler) {
            configuration.performerErrorHandler = nil;
        }
        void(^performerSuccessHandler)(void) = configuration.performerSuccessHandler;
        if (performerSuccessHandler) {
            configuration.performerSuccessHandler = nil;
            performerSuccessHandler();
        }
        return;
    }
    ZIKPerformRouteConfiguration *configuration = self.original_configuration;
    if (configuration.performerErrorHandler) {
        configuration.performerErrorHandler = nil;
    }
    void(^performerSuccessHandler)(id) = configuration.performerSuccessHandler;
    if (performerSuccessHandler) {
        configuration.performerSuccessHandler = nil;
        performerSuccessHandler(self.destination);
    }
}

- (void)notifyErrorToPerformer:(NSError *)error routeAction:(ZIKRouteAction)routeAction {
    NSParameterAssert(error);
    NSParameterAssert(routeAction);
    
    self.error = error;
    if (([routeAction isEqualToString:ZIKRouteActionRemoveRoute])) {
        ZIKRemoveRouteConfiguration *configuration = self.original_removeConfiguration;
        if (configuration.performerSuccessHandler) {
            configuration.performerSuccessHandler = nil;
        }
        ZIKRouteErrorHandler performerErrorHandler = configuration.performerErrorHandler;
        if (performerErrorHandler) {
            configuration.performerErrorHandler = nil;
            performerErrorHandler(routeAction, error);
        }
    } else {
        ZIKPerformRouteConfiguration *configuration = self.original_configuration;
        if (configuration.performerSuccessHandler) {
            configuration.performerSuccessHandler = nil;
        }
        ZIKRouteErrorHandler performerErrorHandler = configuration.performerErrorHandler;
        if (performerErrorHandler) {
            configuration.performerErrorHandler = nil;
            performerErrorHandler(routeAction, error);
        }
    }
}

+ (void)notifyError_invalidProtocolWithAction:(ZIKRouteAction)action errorDescription:(NSString *)format ,... {
    va_list argList;
    va_start(argList, format);
    NSString *description = [[NSString alloc] initWithFormat:format arguments:argList];
    va_end(argList);
    [[self class] notifyGlobalErrorWithRouter:nil action:action error:[ZIKRouter errorWithCode:ZIKRouteErrorInvalidProtocol localizedDescription:description]];
}

- (void)notifyError_invalidConfigurationWithAction:(ZIKRouteAction)action errorDescription:(NSString *)format ,... {
    va_list argList;
    va_start(argList, format);
    NSString *description = [[NSString alloc] initWithFormat:format arguments:argList];
    va_end(argList);
    [self notifyError:[ZIKRouter errorWithCode:ZIKRouteErrorInvalidConfiguration localizedDescription:description] routeAction:action];
}

- (void)notifyError_destinationUnavailableWithAction:(ZIKRouteAction)action errorDescription:(NSString *)format ,... {
    va_list argList;
    va_start(argList, format);
    NSString *description = [[NSString alloc] initWithFormat:format arguments:argList];
    va_end(argList);
    [self notifyError:[ZIKRouter errorWithCode:ZIKRouteErrorDestinationUnavailable localizedDescription:description] routeAction:action];
}

- (void)notifyError_actionFailedWithAction:(ZIKRouteAction)action errorDescription:(NSString *)format ,... {
    va_list argList;
    va_start(argList, format);
    NSString *description = [[NSString alloc] initWithFormat:format arguments:argList];
    va_end(argList);
    [self notifyError:[ZIKRouter errorWithCode:ZIKRouteErrorActionFailed localizedDescription:description] routeAction:action];
}

- (void)notifyError_overRouteWithAction:(ZIKRouteAction)action errorDescription:(NSString *)format ,... {
    va_list argList;
    va_start(argList, format);
    NSString *description = [[NSString alloc] initWithFormat:format arguments:argList];
    va_end(argList);
    [self notifyError:[ZIKRouter errorWithCode:ZIKRouteErrorOverRoute localizedDescription:description] routeAction:action];
}

- (void)notifyError_infiniteRecursionWithAction:(ZIKRouteAction)action errorDescription:(NSString *)format ,... {
    va_list argList;
    va_start(argList, format);
    NSString *description = [[NSString alloc] initWithFormat:format arguments:argList];
    va_end(argList);
    [self notifyError:[ZIKRouter errorWithCode:ZIKRouteErrorInfiniteRecursion localizedDescription:description] routeAction:action];
}

+ (void)notifyGlobalErrorWithRouter:(nullable __kindof ZIKRouter *)router action:(ZIKRouteAction)action error:(NSError *)error {
    void(^errorHandler)(__kindof ZIKRouter *_Nullable router, ZIKRouteAction action, NSError *error) = self.globalErrorHandler;
    if (errorHandler) {
        errorHandler(router, action, error);
    } else {
#ifdef DEBUG
        NSLog(@"❌ZIKRouter Error: router's action (%@) catch error: (%@),\nrouter:(%@)", action, error, router);
#endif
    }
}

+ (BOOL)_validateInfiniteRecursion {
    NSUInteger maxRecursiveDepth = 200;
    if ([self recursiveDepth] > maxRecursiveDepth) {
        return NO;
    }
    return YES;
}

+ (void)increaseRecursiveDepth {
    NSInteger depth = [self recursiveDepth];
    [self setRecursiveDepth:++depth];
}

+ (void)decreaseRecursiveDepth {
    NSInteger depth = [self recursiveDepth];
    [self setRecursiveDepth:--depth];
}

+ (NSInteger)recursiveDepth {
    NSNumber *depth = objc_getAssociatedObject(self, @selector(recursiveDepth));
    if ([depth isKindOfClass:[NSNumber class]]) {
        return [depth unsignedIntegerValue];
    }
    return 0;
}

+ (void)setRecursiveDepth:(NSInteger)depth {
    if (depth < 0) {
        depth = 0;
    }
    objc_setAssociatedObject(self, @selector(recursiveDepth), @(depth), OBJC_ASSOCIATION_RETAIN);
}

#pragma mark Getter/Setter

- (ZIKPerformRouteConfiguration *)configuration {
    return _configuration;
}

- (ZIKPerformRouteConfiguration *)original_configuration {
    return _configuration;
}

- (ZIKRemoveRouteConfiguration *)removeConfiguration {
    return _removeConfiguration;
}

- (ZIKRemoveRouteConfiguration *)original_removeConfiguration {
    if (_removeConfiguration == nil) {
        _removeConfiguration = [[self class] defaultRemoveConfiguration];
    }
    return _removeConfiguration;
}

#pragma mark Debug

+ (NSString *)descriptionOfState:(ZIKRouterState)state {
    NSString *description;
    switch (state) {
        case ZIKRouterStateUnrouted:
            description = @"Unrouted";
            break;
        case ZIKRouterStateRouting:
            description = @"Routing";
            break;
        case ZIKRouterStateRouted:
            description = @"Routed";
            break;
        case ZIKRouterStateRemoving:
            description = @"Removing";
            break;
        case ZIKRouterStateRemoved:
            description = @"Removed";
            break;
        default:
            description = @"Unrouted";
            break;
    }
    return description;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@: state:%@,\ndestinaton:%@,\nconfiguration:(%@)",[super description],[[self class] descriptionOfState:self.state],self.destination,self.original_configuration];
}

@end
