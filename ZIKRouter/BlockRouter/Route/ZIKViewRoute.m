//
//  ZIKViewRoute.m
//  ZIKRouter
//
//  Created by zuik on 2018/4/7.
//  Copyright © 2018 zuik. All rights reserved.
//

#import "ZIKViewRoute.h"
#import "ZIKRoutePrivate.h"
#import "ZIKViewRouteRegistry.h"
#import "ZIKViewRouterInternal.h"
#import "ZIKViewRouterPrivate.h"
#import "ZIKBlockViewRouter.h"
#import "ZIKRouteConfigurationPrivate.h"
#import "ZIKPerformRouteConfiguration+Route.h"

@interface ZIKViewRoute()
@property (nonatomic, copy, nullable) BOOL(^destinationFromExternalPreparedBlock)(id destination, ZIKViewRouter *router);
@property (nonatomic, copy, nullable) BOOL(^canPerformCustomRouteBlock)(ZIKViewRouter *router);
@property (nonatomic, copy, nullable) BOOL(^canRemoveCustomRouteBlock)(ZIKViewRouter *router);
@property (nonatomic, copy, nullable) void(^performCustomRouteBlock)(id destination, _Nullable id source, ZIKViewRouteConfiguration *config, ZIKViewRouter *router);
@property (nonatomic, copy, nullable) void(^removeCustomRouteBlock)(id destination, _Nullable id source, ZIKViewRemoveConfiguration *removeConfig, ZIKViewRouteConfiguration *config, ZIKViewRouter *router);
@end

@implementation ZIKViewRoute
@dynamic registerDestination;
@dynamic registerDestinationProtocol;
@dynamic registerModuleProtocol;
@dynamic makeDefaultConfiguration;
@dynamic makeDefaultRemoveConfiguration;
@dynamic prepareDestination;
@dynamic didFinishPrepareDestination;

- (ZIKViewRoute<id, ZIKViewRouteConfiguration *> *(^)(BOOL(^)(id destination, ZIKViewRouter *router)))destinationFromExternalPrepared {
    return ^(BOOL(^block)(id destination, ZIKViewRouter *router)) {
        self.destinationFromExternalPreparedBlock = block;
        return self;
    };
}

- (ZIKViewRoute<id, ZIKViewRouteConfiguration *> *(^)(BOOL(^)(ZIKViewRouter *router)))canPerformCustomRoute {
    return ^(BOOL(^block)(ZIKViewRouter *router)) {
        self.canPerformCustomRouteBlock = block;
        return self;
    };
}
- (ZIKViewRoute<id, ZIKViewRouteConfiguration *> *(^)(BOOL(^)(ZIKViewRouter *router)))canRemoveCustomRoute {
    return ^(BOOL(^block)(ZIKViewRouter *router)) {
        self.canRemoveCustomRouteBlock = block;
        return self;
    };
}

- (ZIKViewRoute<id, ZIKViewRouteConfiguration *> *(^)(void(^)(id destination, _Nullable id source, ZIKViewRouteConfiguration *config, ZIKViewRouter *router)))performCustomRoute {
    return ^(void(^block)(id destination, _Nullable id source, ZIKViewRouteConfiguration *config, ZIKViewRouter *router)) {
        self.performCustomRouteBlock = block;
        return self;
    };
}

- (ZIKViewRoute<id, ZIKViewRouteConfiguration *> *(^)(void(^)(id destination, _Nullable id source, ZIKViewRemoveConfiguration *removeConfig, ZIKViewRouteConfiguration *config, ZIKViewRouter *router)))removeCustomRoute {
    return ^(void(^block)(id destination, _Nullable id source, ZIKViewRemoveConfiguration *removeConfig, ZIKViewRouteConfiguration *config, ZIKViewRouter *router)) {
        self.removeCustomRouteBlock = block;
        return self;
    };
}

- (Class)routerClass {
    return [ZIKBlockViewRouter class];
}

+ (Class)registryClass {
    return [ZIKViewRouteRegistry class];
}

#pragma mark Inject

- (void(^)(ZIKViewRouteConfiguration *config))_injectedConfigBuilder:(void(^)(ZIKViewRouteConfiguration *config))builder {
    return ^(ZIKViewRouteConfiguration *configuration) {
        configuration.route = self;
        ZIKViewRouteConfiguration *injected = [self defaultRouteConfigurationFromBlock];
        if (injected && configuration->_injectable != NULL) {
            configuration = injected;
            *configuration->_injectable = injected;
            configuration->_injectable = NULL;
        }
        if (builder) {
            builder(configuration);
        }
    };
}

- (void(^)(ZIKViewRemoveConfiguration *config))_injectedRemoveConfigBuilder:(void(^)(ZIKViewRemoveConfiguration *config))builder {
    return ^(ZIKViewRemoveConfiguration *configuration) {
        ZIKViewRemoveConfiguration *injected = [self defaultRemoveRouteConfigurationFromBlock];
        if (injected && configuration->_injectable != NULL) {
            configuration = injected;
            *configuration->_injectable = injected;
            configuration->_injectable = NULL;
        }
        if (builder) {
            builder(configuration);
        }
    };
}

- (void (^)(ZIKViewRouteConfiguration * _Nonnull, void (^ _Nonnull)(void (^ _Nonnull)(id _Nonnull)),
            void (^ _Nonnull)(void (^ _Nonnull)(ZIKViewRouteConfiguration * _Nonnull))))
_injectedStrictConfigBuilder:
(void (^)(ZIKViewRouteConfiguration * _Nonnull,
          void (^ _Nonnull)(void (^ _Nonnull)(id _Nonnull)),
          void (^ _Nonnull)(void (^ _Nonnull)(ZIKViewRouteConfiguration * _Nonnull)))
 )builder {
    return ^(ZIKViewRouteConfiguration * _Nonnull configuration,
             void (^ _Nonnull prepareDestination)(void (^ _Nonnull)(id _Nonnull)),
             void (^ _Nonnull prepareModule)(void (^ _Nonnull)(ZIKViewRouteConfiguration * _Nonnull))) {
        configuration.route = self;
        ZIKViewRouteConfiguration *injected = [self defaultRouteConfigurationFromBlock];
        if (injected && *configuration->_injectable != NULL) {
            configuration = injected;
            *configuration->_injectable = injected;
            configuration->_injectable = NULL;
        }
        if (builder) {
            builder(configuration, prepareDestination, prepareModule);
        }
    };
}

- (void (^)(ZIKViewRemoveConfiguration * _Nonnull,
            void (^ _Nonnull)(void (^ _Nonnull)(id _Nonnull))))
_injectedStrictRemoveConfigBuilder:
(void (^)(ZIKViewRemoveConfiguration * _Nonnull,
          void (^ _Nonnull)(void (^ _Nonnull)(id _Nonnull)))
 )builder {
    return ^(ZIKViewRemoveConfiguration * _Nonnull configuration, void (^ _Nonnull prepareDestination)(void (^ _Nonnull)(id _Nonnull))) {
        ZIKViewRemoveConfiguration *injected = [self defaultRemoveRouteConfigurationFromBlock];
        if (injected && *configuration->_injectable != NULL) {
            configuration = injected;
            *configuration->_injectable = injected;
            configuration->_injectable = NULL;
        }
        if (builder) {
            builder(configuration, prepareDestination);
        }
    };
}

- (id)performFromSource:(nullable id<ZIKViewRouteSource>)source configuring:(void(NS_NOESCAPE ^)(ZIKViewRouteConfiguration *config))configBuilder {
    return [self performFromSource:source configuring:configBuilder removing:nil];
}

- (id)performFromSource:(nullable id)source routeType:(ZIKViewRouteType)routeType {
    return [self performFromSource:source configuring:^(ZIKViewRouteConfiguration * _Nonnull config) {
        config.routeType = routeType;
    } removing:nil];
}

- (id)performFromSource:(nullable id<ZIKViewRouteSource>)source routeType:(ZIKViewRouteType)routeType completion:(ZIKPerformRouteCompletion)completionHandler {
    return [self performFromSource:source configuring:^(ZIKViewRouteConfiguration * _Nonnull config) {
        config.routeType = routeType;
        if (completionHandler == nil) {
            return;
        }
        config.completionHandler = completionHandler;
    }];
}

- (id)performFromSource:(nullable id<ZIKViewRouteSource>)source
            configuring:(void(NS_NOESCAPE ^)(ZIKViewRouteConfiguration *config))configBuilder
               removing:(void(NS_NOESCAPE ^ _Nullable)(ZIKViewRemoveConfiguration *config))removeConfigBuilder {
    configBuilder = [self _injectedConfigBuilder:configBuilder];
    removeConfigBuilder = [self _injectedRemoveConfigBuilder:removeConfigBuilder];
    return [ZIKBlockViewRouter performFromSource:source configuring:configBuilder removing:removeConfigBuilder];
}

- (id)performFromSource:(id<ZIKViewRouteSource>)source
                         strictConfiguring:(void (^)(ZIKViewRouteConfiguration * _Nonnull,
                                                     void (^ _Nonnull)(void (^ _Nonnull)(id _Nonnull)),
                                                     void (^ _Nonnull)(void (^ _Nonnull)(ZIKViewRouteConfiguration * _Nonnull))
                                                     ))configBuilder {
    return [self performFromSource:source strictConfiguring:configBuilder strictRemoving:nil];
}

- (id)performFromSource:(id<ZIKViewRouteSource>)source
                         strictConfiguring:(void (^)(ZIKViewRouteConfiguration * _Nonnull,
                                                     void (^ _Nonnull)(void (^ _Nonnull)(id _Nonnull)),
                                                     void (^ _Nonnull)(void (^ _Nonnull)(ZIKViewRouteConfiguration * _Nonnull))
                                                     ))configBuilder
                            strictRemoving:(void (^)(ZIKViewRemoveConfiguration * _Nonnull,
                                                     void (^ _Nonnull)(void (^ _Nonnull)(id _Nonnull))
                                                     ))removeConfigBuilder {
    configBuilder = [self _injectedStrictConfigBuilder:configBuilder];
    removeConfigBuilder = [self _injectedStrictRemoveConfigBuilder:removeConfigBuilder];
    return [ZIKBlockViewRouter performFromSource:source strictConfiguring:configBuilder strictRemoving:removeConfigBuilder];
}

- (id)performOnDestination:(id)destination
                                   fromSource:(nullable id<ZIKViewRouteSource>)source
                                  configuring:(void(NS_NOESCAPE ^)(ZIKViewRouteConfiguration *config))configBuilder {
    return [self performOnDestination:destination fromSource:source configuring:configBuilder removing:nil];
}

- (id)performOnDestination:(id)destination
                fromSource:(nullable id<ZIKViewRouteSource>)source
               configuring:(void(NS_NOESCAPE ^)(ZIKViewRouteConfiguration *config))configBuilder
                  removing:(void(NS_NOESCAPE ^ _Nullable)(ZIKViewRemoveConfiguration *config))removeConfigBuilder {
    configBuilder = [self _injectedConfigBuilder:configBuilder];
    removeConfigBuilder = [self _injectedRemoveConfigBuilder:removeConfigBuilder];
    return [ZIKBlockViewRouter performOnDestination:destination fromSource:source configuring:configBuilder removing:removeConfigBuilder];
}

- (id)performOnDestination:(id)destination
                fromSource:(nullable id<ZIKViewRouteSource>)source
                 routeType:(ZIKViewRouteType)routeType {
    return [self performOnDestination:destination fromSource:source configuring:^(__kindof ZIKViewRouteConfiguration * _Nonnull config) {
        config.routeType = routeType;
    } removing:nil];
}

- (id)performOnDestination:(id)destination
                fromSource:(id<ZIKViewRouteSource>)source
         strictConfiguring:(void (^)(ZIKViewRouteConfiguration * _Nonnull,
                                     void (^ _Nonnull)(void (^ _Nonnull)(id _Nonnull)),
                                     void (^ _Nonnull)(void (^ _Nonnull)(ZIKViewRouteConfiguration * _Nonnull))
                                     ))configBuilder {
    return [self performOnDestination:destination fromSource:source strictConfiguring:configBuilder strictRemoving:nil];
}

- (id)performOnDestination:(id)destination
                fromSource:(id<ZIKViewRouteSource>)source
         strictConfiguring:(void (^)(ZIKViewRouteConfiguration * _Nonnull,
                                     void (^ _Nonnull)(void (^ _Nonnull)(id _Nonnull)),
                                     void (^ _Nonnull)(void (^ _Nonnull)(ZIKViewRouteConfiguration * _Nonnull))
                                     ))configBuilder
            strictRemoving:(void (^)(ZIKViewRemoveConfiguration * _Nonnull,
                                     void (^ _Nonnull)(void (^ _Nonnull)(id _Nonnull))
                                     ))removeConfigBuilder {
    configBuilder = [self _injectedStrictConfigBuilder:configBuilder];
    removeConfigBuilder = [self _injectedStrictRemoveConfigBuilder:removeConfigBuilder];
    return [ZIKBlockViewRouter performOnDestination:destination fromSource:source strictConfiguring:configBuilder strictRemoving:removeConfigBuilder];
}

- (id)prepareDestination:(id)destination
             configuring:(void(NS_NOESCAPE ^)(ZIKViewRouteConfiguration *config))configBuilder {
    return [self prepareDestination:destination configuring:configBuilder removing:nil];
}

- (id)prepareDestination:(id)destination
             configuring:(void(NS_NOESCAPE ^)(ZIKViewRouteConfiguration *config))configBuilder
                removing:(void(NS_NOESCAPE ^ _Nullable)(ZIKViewRemoveConfiguration *config))removeConfigBuilder {
    configBuilder = [self _injectedConfigBuilder:configBuilder];
    removeConfigBuilder = [self _injectedRemoveConfigBuilder:removeConfigBuilder];
    return [ZIKBlockViewRouter prepareDestination:destination configuring:configBuilder removing:removeConfigBuilder];
}

- (id)prepareDestination:(id)destination strictConfiguring:(void (^)(ZIKViewRouteConfiguration * _Nonnull, void (^ _Nonnull)(void (^ _Nonnull)(id _Nonnull)), void (^ _Nonnull)(void (^ _Nonnull)(ZIKViewRouteConfiguration * _Nonnull))))configBuilder {
    return [self prepareDestination:destination strictConfiguring:configBuilder strictRemoving:nil];
}

- (id)prepareDestination:(id)destination
       strictConfiguring:(void (^)(ZIKViewRouteConfiguration * _Nonnull,
                                   void (^ _Nonnull)(void (^ _Nonnull)(id _Nonnull)),
                                   void (^ _Nonnull)(void (^ _Nonnull)(ZIKViewRouteConfiguration * _Nonnull))
                                   ))configBuilder
                             strictRemoving:(void (^ _Nullable)(ZIKViewRemoveConfiguration * _Nonnull,
                                                                void (^ _Nonnull)(void (^ _Nonnull)(id _Nonnull))
                                                                ))removeConfigBuilder {
    configBuilder = [self _injectedStrictConfigBuilder:configBuilder];
    removeConfigBuilder = [self _injectedStrictRemoveConfigBuilder:removeConfigBuilder];
    return [ZIKBlockViewRouter prepareDestination:destination strictConfiguring:configBuilder strictRemoving:removeConfigBuilder];
}

- (id)routerFromSegueIdentifier:(NSString *)identifier sender:(nullable id)sender destination:(UIViewController *)destination source:(UIViewController *)source {
    ZIKBlockViewRouter *router = [ZIKBlockViewRouter routerFromSegueIdentifier:identifier sender:sender destination:destination source:source];
    router.original_configuration.route = self;
    return router;
}
- (id)routerFromView:(UIView *)destination source:(UIView *)source {
    ZIKBlockViewRouter *router = [ZIKBlockViewRouter routerFromView:destination source:source];
    router.original_configuration.route = self;
    return router;
}

- (nullable ZIKViewRouteConfiguration *)defaultRouteConfigurationFromBlock {
    if (self.makeDefaultConfigurationBlock) {
        ZIKViewRouteConfiguration *config = self.makeDefaultConfigurationBlock();
        config.route = self;
        return config;
    }
    return nil;
}

- (nullable ZIKViewRemoveConfiguration *)defaultRemoveRouteConfigurationFromBlock {
    if (self.makeDefaultRemoveConfigurationBlock) {
        return self.makeDefaultRemoveConfigurationBlock();
    }
    return nil;
}

@end
