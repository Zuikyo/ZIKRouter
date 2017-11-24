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
#import "ZIKRouteConfiguration+Private.h"
#import <objc/runtime.h>

ZIKRouteAction const ZIKRouteActionInit = @"ZIKRouteActionInit";
ZIKRouteAction const ZIKRouteActionPerformRoute = @"ZIKRouteActionPerformRoute";
ZIKRouteAction const ZIKRouteActionRemoveRoute = @"ZIKRouteActionRemoveRoute";

NSString *kZIKRouterErrorDomain = @"kZIKRouterErrorDomain";

@interface ZIKRouter () {
    dispatch_semaphore_t _stateSema;
}
@property (nonatomic, assign) ZIKRouterState state;
@property (nonatomic, assign) ZIKRouterState preState;
@property (nonatomic, strong, nullable) NSError *error;
@property (nonatomic, copy) ZIKPerformRouteConfiguration *configuration;
@property (nonatomic, copy, nullable) ZIKRouteConfiguration *removeConfiguration;
@property (nonatomic, weak) id destination;
@end

@implementation ZIKRouter

- (instancetype)initWithConfiguration:(ZIKRouteConfiguration *)configuration removeConfiguration:(nullable ZIKRouteConfiguration *)removeConfiguration {
    NSParameterAssert(configuration);
    
    if (self = [super init]) {
        _state = ZIKRouterStateNotRoute;
        _configuration = [configuration copy];
        _removeConfiguration = [removeConfiguration copy];
        _stateSema = dispatch_semaphore_create(1);
    }
    return self;
}

- (instancetype)initWithConfiguring:(void(^)(ZIKPerformRouteConfiguration *configuration))configBuilder removing:(void(^ _Nullable)(ZIKRouteConfiguration *configuration))removeConfigBuilder {
    NSParameterAssert(configBuilder);
    ZIKPerformRouteConfiguration *configuration = [[self class] defaultRouteConfiguration];
    if (configBuilder) {
        configBuilder(configuration);
    }
    ZIKRouteConfiguration *removeConfiguration;
    if (removeConfigBuilder) {
        removeConfiguration = [[self class] defaultRemoveConfiguration];
        removeConfigBuilder(removeConfiguration);
    }
    return [self initWithConfiguration:configuration removeConfiguration:removeConfiguration];
}

- (void)attachDestination:(id)destination {
    NSParameterAssert(destination);
//    NSAssert(!self.destination, @"destination exists!");
    if (destination) {
        self.destination = destination;
    }
}

- (void)notifyRouteState:(ZIKRouterState)state {
    dispatch_semaphore_wait(_stateSema, DISPATCH_TIME_FOREVER);
    ZIKRouterState oldState = self.state;
    self.preState = oldState;
    self.state = state;
    
    if (self.original_configuration.stateNotifier) {
        self.original_configuration.stateNotifier(oldState, state);
    }
    
    dispatch_semaphore_signal(_stateSema);
}

- (BOOL)canPerform {
    return YES;
}

- (void)performRoute {
    [self performRouteWithSuccessHandler:self.original_configuration.performerSuccessHandler
                            errorHandler:self.original_configuration.performerErrorHandler];
}

- (void)performRouteWithSuccessHandler:(void(^)(void))performerSuccessHandler
                          errorHandler:(void(^)(ZIKRouteAction routeAction, NSError *error))performerErrorHandler {
    NSAssert(self.original_configuration, @"router must has configuration");
    ZIKRouteConfiguration *configuration = self.original_configuration;
    if (performerSuccessHandler) {
        configuration.performerSuccessHandler = performerSuccessHandler;
    }
    if (performerErrorHandler) {
        configuration.performerErrorHandler = performerErrorHandler;
    }
    [self performWithConfiguration:configuration];
}

- (void)performWithConfiguration:(ZIKRouteConfiguration *)configuration {
    NSParameterAssert(configuration);
    
    id destination = [self destinationWithConfiguration:configuration];
    self.destination = destination;
    [self performRouteOnDestination:destination configuration:configuration];
}

+ (__kindof ZIKRouter *)performRoute {
    ZIKRouter *router = [[self alloc] initWithConfiguration:[self defaultRouteConfiguration] removeConfiguration:nil];
    [router performRoute];
    return router;
}

+ (__kindof ZIKRouter *)performWithConfiguring:(void(^)(ZIKPerformRouteConfiguration *configuration))configBuilder {
    NSParameterAssert(configBuilder);
    ZIKRouter *router = [[self alloc] initWithConfiguring:configBuilder removing:nil];
    [router performRoute];
    return router;
}

+ (__kindof ZIKRouter *)performWithConfiguring:(void(^)(ZIKPerformRouteConfiguration *configuration))configBuilder removing:(void(^)(ZIKRouteConfiguration *configuration))removeConfigBuilder {
    NSParameterAssert(configBuilder);
    ZIKRouter *router = [[self alloc] initWithConfiguring:configBuilder removing:removeConfigBuilder];
    [router performRoute];
    return router;
}

- (BOOL)canRemove {
    return YES;
}

- (void)removeRoute {
    [self removeRouteWithSuccessHandler:nil errorHandler:nil];
}

- (void)removeRouteWithSuccessHandler:(void(^)(void))performerSuccessHandler
                         errorHandler:(void(^)(ZIKRouteAction routeAction, NSError *error))performerErrorHandler {
    ZIKRouteConfiguration *configuration = self.original_removeConfiguration;
    if (!configuration) {
        configuration = [[self class] defaultRemoveConfiguration];
    }
    if (performerSuccessHandler) {
        configuration.performerSuccessHandler = performerSuccessHandler;
    }
    if (performerErrorHandler) {
        configuration.performerErrorHandler = performerErrorHandler;
    }
    [self removeDestination:self.destination removeConfiguration:configuration];
}

+ (BOOL)canMakeDestination {
    return [self completeSynchronously];
}

+ (nullable id)makeDestinationWithPreparation:(void(^ _Nullable)(id destination))prepare {
    NSAssert(self != [ZIKRouter class], @"Only get destination from router subclass");
    if (![self canMakeDestination]) {
        NSAssert1(NO, @"The router (%@) doesn't support makeDestination",self);
        return nil;
    }
    __block id dest;
    ZIKRouter *router = [[self alloc] initWithConfiguring:^(ZIKPerformRouteConfiguration * _Nonnull config) {
        if (prepare) {
            config.prepareDestination = prepare;
        }
        void(^routeCompletion)(id destination) = config.routeCompletion;
        if (routeCompletion) {
            config.routeCompletion = ^(id  _Nonnull destination) {
                routeCompletion(destination);
                dest = destination;
            };
        } else {
            config.routeCompletion = ^(id  _Nonnull destination) {
                dest = destination;
            };
        }
    } removing:NULL];
    [router performRoute];
    return dest;
}

+ (nullable id)makeDestinationWithConfiguring:(void(^ _Nullable)(ZIKPerformRouteConfiguration *config))configBuilder {
    NSAssert(self != [ZIKRouter class], @"Only get destination from router subclass");
    if (![self canMakeDestination]) {
        NSAssert1(NO, @"The router (%@) doesn't support makeDestination",self);
        return nil;
    }
    __block id dest;
    ZIKRouter *router = [[self alloc] initWithConfiguring:^(ZIKPerformRouteConfiguration * _Nonnull config) {
        if (configBuilder) {
            configBuilder(config);
        }
        void(^routeCompletion)(id destination) = config.routeCompletion;
        if (routeCompletion) {
            config.routeCompletion = ^(id  _Nonnull destination) {
                routeCompletion(destination);
                dest = destination;
            };
        } else {
            config.routeCompletion = ^(id  _Nonnull destination) {
                dest = destination;
            };
        }
    } removing:NULL];
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

- (void)performRouteOnDestination:(id)destination configuration:(ZIKRouteConfiguration *)configuration {
    NSAssert(NO, @"ZIKRouter: %@ not conforms to ZIKRouterProtocol!",[self class]);
}

- (void)removeDestination:(id)destination removeConfiguration:(ZIKRouteConfiguration *)removeConfiguration {
    NSAssert(NO, @"ZIKRouter: %@ not conforms to ZIKRouterProtocol!",[self class]);
}

- (id)destinationWithConfiguration:(ZIKRouteConfiguration *)configuration {
    NSAssert(NO, @"ZIKRouter: %@ not conforms to ZIKRouterProtocol!",[self class]);
    return nil;
}

+ (ZIKPerformRouteConfiguration *)defaultRouteConfiguration {
    NSAssert(NO, @"ZIKRouter: %@ not conforms to ZIKRouterProtocol!",[self class]);
    return nil;
}

+ (ZIKRouteConfiguration *)defaultRemoveConfiguration {
    NSAssert(NO, @"ZIKRouter: %@ not conforms to ZIKRouterProtocol!",[self class]);
    return nil;
}

+ (BOOL)completeSynchronously {
    return YES;
}

#pragma mark Error Handle

+ (NSString *)errorDomain {
    return kZIKRouterErrorDomain;
}

+ (NSError *)errorWithCode:(NSInteger)code userInfo:(nullable NSDictionary *)userInfo {
    return [NSError errorWithDomain:[self errorDomain] code:code userInfo:userInfo];
}

+ (NSError *)errorWithCode:(NSInteger)code localizedDescription:(NSString *)description {
    NSParameterAssert(description);
    return [NSError errorWithDomain:[self errorDomain] code:code userInfo:@{NSLocalizedDescriptionKey:description}];
}

+ (NSError *)errorWithCode:(NSInteger)code localizedDescriptionFormat:(NSString *)format ,... {
    va_list argList;
    va_start(argList, format);
    NSString *description = [[NSString alloc] initWithFormat:format arguments:argList];
    va_end(argList);
    return [NSError errorWithDomain:[self errorDomain] code:code userInfo:@{NSLocalizedDescriptionKey:description}];
}

- (void)notifySuccessWithAction:(ZIKRouteAction)routeAction {
    [self notifySuccessToProviderWithAction:routeAction];
    [self notifySuccessToPerformerWithAction:routeAction];
}

- (void)notifyError:(NSError *)error routeAction:(ZIKRouteAction)routeAction {
    [self notifyErrorToProvider:error routeAction:routeAction];
    [self notifyErrorToPerformer:error routeAction:routeAction];
}

- (void)notifySuccessToProviderWithAction:(ZIKRouteAction)routeAction {
    NSParameterAssert(routeAction);
    ZIKRouteConfiguration *configuration;
    if ([routeAction isEqual:ZIKRouteActionPerformRoute]) {
        configuration = self.original_configuration;
    } else if ([routeAction isEqual:ZIKRouteActionRemoveRoute]) {
        configuration = self.original_removeConfiguration;
    } else {
        configuration = self.original_configuration;
    }
    
    if (configuration.successHandler) {
        configuration.successHandler();
    }
}

- (void)notifyErrorToProvider:(NSError *)error routeAction:(ZIKRouteAction)routeAction {
    NSParameterAssert(error);
    NSParameterAssert(routeAction);
    self.error = error;
    ZIKRouteConfiguration *configuration;
    if ([routeAction isEqual:ZIKRouteActionPerformRoute]) {
        configuration = self.original_configuration;
    } else if ([routeAction isEqual:ZIKRouteActionRemoveRoute]) {
        configuration = self.original_removeConfiguration;
    } else {
        configuration = self.original_configuration;
    }
    if (!configuration.errorHandler) {
        return;
    }
    if ([NSThread isMainThread]) {
        configuration.errorHandler(routeAction, error);
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            configuration.errorHandler(routeAction, error);
        });
    }
}

- (void)notifySuccessToPerformerWithAction:(ZIKRouteAction)routeAction {
    NSParameterAssert(routeAction);
    
    ZIKRouteConfiguration *configuration;
    if ([routeAction isEqual:ZIKRouteActionPerformRoute]) {
        configuration = self.original_configuration;
    } else if ([routeAction isEqual:ZIKRouteActionRemoveRoute]) {
        configuration = self.original_removeConfiguration;
    } else {
        configuration = self.original_configuration;
    }
    
    if (configuration.performerSuccessHandler) {
        configuration.performerSuccessHandler();
        configuration.performerSuccessHandler = nil;
    }
    if (configuration.performerErrorHandler) {
        configuration.performerErrorHandler = nil;
    }
}

- (void)notifyErrorToPerformer:(NSError *)error routeAction:(ZIKRouteAction)routeAction {
    NSParameterAssert(error);
    NSParameterAssert(routeAction);
    
    self.error = error;
    ZIKRouteConfiguration *configuration;
    if ([routeAction isEqual:ZIKRouteActionPerformRoute]) {
        configuration = self.original_configuration;
    } else if ([routeAction isEqual:ZIKRouteActionRemoveRoute]) {
        configuration = self.original_removeConfiguration;
    } else {
        configuration = self.original_configuration;
    }
    
    if (configuration.performerErrorHandler) {
        configuration.performerErrorHandler(routeAction, error);
        configuration.performerErrorHandler = nil;
    }
    if (configuration.performerSuccessHandler) {
        configuration.performerSuccessHandler = nil;
    }    
}

#pragma mark Getter/Setter

- (ZIKRouteConfiguration*)configuration {
    return [_configuration copy];
}

- (ZIKRouteConfiguration*)original_configuration {
    return _configuration;
}

- (ZIKRouteConfiguration*)removeConfiguration {
    return [_removeConfiguration copy];
}

- (ZIKRouteConfiguration*)original_removeConfiguration {
    return _removeConfiguration;
}

#pragma mark Debug

+ (NSString *)descriptionOfState:(ZIKRouterState)state {
    NSString *description;
    switch (state) {
        case ZIKRouterStateNotRoute:
            description = @"NotRoute";
            break;
        case ZIKRouterStateRouting:
            description = @"Routing";
            break;
        case ZIKRouterStateRouted:
            description = @"Routed";
            break;
        case ZIKRouterStateRouteFailed:
            description = @"RouteFailed";
            break;
        case ZIKRouterStateRemoving:
            description = @"Removing";
            break;
        case ZIKRouterStateRemoved:
            description = @"Removed";
            break;
        case ZIKRouterStateRemoveFailed:
            description = @"RemoveFailed";
            break;
    }
    return description;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@: state:%@, destinaton:%@, configuration:(%@)",[super description],[[self class] descriptionOfState:self.state],self.destination,self.original_configuration];
}

@end
