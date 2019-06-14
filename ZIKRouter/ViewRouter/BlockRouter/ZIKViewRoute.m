//
//  ZIKViewRoute.m
//  ZIKRouter
//
//  Created by zuik on 2018/4/7.
//  Copyright © 2018 zuik. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#if __has_include("ZIKViewRouter.h")

#import "ZIKViewRoute.h"
#import "ZIKRoutePrivate.h"
#import "ZIKViewRouteRegistry.h"
#import "ZIKViewRouterInternal.h"
#import "ZIKViewRouterPrivate.h"
#import "ZIKRouteConfigurationPrivate.h"
#import "ZIKBlockViewRouter.h"
#import "ZIKClassCapabilities.h"

@interface ZIKViewRoute()
@property (nonatomic, copy, nullable) BOOL(^shouldAutoCreateForDestinationBlock)(id destination, id source);
@property (nonatomic, copy, nullable) BOOL(^destinationFromExternalPreparedBlock)(id destination, ZIKViewRouter *router);
@property (nonatomic, copy, nullable) ZIKBlockViewRouteTypeMask(^makeSupportedRouteTypesBlock)(void);
@property (nonatomic, copy, nullable) BOOL(^canPerformCustomRouteBlock)(ZIKViewRouter *router);
@property (nonatomic, copy, nullable) BOOL(^canRemoveCustomRouteBlock)(ZIKViewRouter *router);
@property (nonatomic, copy, nullable) void(^performCustomRouteBlock)(id destination, _Nullable id source, ZIKViewRouteConfiguration *config, ZIKViewRouter *router);
@property (nonatomic, copy, nullable) void(^removeCustomRouteBlock)(id destination, _Nullable id source, ZIKViewRemoveConfiguration *removeConfig, ZIKViewRouteConfiguration *config, ZIKViewRouter *router);
@end

@implementation ZIKViewRoute
@dynamic nameAs;
@dynamic registerDestination;
@dynamic registerExclusiveDestination;
@dynamic registerDestinationProtocol;
@dynamic registerModuleProtocol;
@dynamic registerIdentifier;
@dynamic makeDefaultConfiguration;
@dynamic makeDefaultRemoveConfiguration;
@dynamic prepareDestination;
@dynamic didFinishPrepareDestination;

- (ZIKViewRoute<id, ZIKViewRouteConfiguration *> *(^)(BOOL(^)(id destination, id source)))shouldAutoCreateForDestination {
    return ^(BOOL(^block)(id destination, id source)) {
        self.shouldAutoCreateForDestinationBlock = block;
        return self;
    };
}

- (ZIKViewRoute<id, ZIKViewRouteConfiguration *> *(^)(BOOL(^)(id destination, ZIKViewRouter *router)))destinationFromExternalPrepared {
    return ^(BOOL(^block)(id destination, ZIKViewRouter *router)) {
        self.destinationFromExternalPreparedBlock = block;
        return self;
    };
}

- (ZIKViewRoute<id, ZIKViewRouteConfiguration *> *(^)(ZIKBlockViewRouteTypeMask(^)(void)))makeSupportedRouteTypes {
    return ^(ZIKBlockViewRouteTypeMask(^block)(void)) {
        self.makeSupportedRouteTypesBlock = block;
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
    if (self.makeSupportedRouteTypesBlock) {
        return [self routerClassForSupportedRouteTypes:self.makeSupportedRouteTypesBlock()];
    }
    return [ZIKBlockViewRouter class];
}

+ (Class)registryClass {
    return [ZIKViewRouteRegistry class];
}

#pragma mark Inject

#define INJECT_CONFIG_BUILDER configBuilder = ^(ZIKViewRouteConfiguration *configuration) {\
    configuration.route = self;\
    ZIKViewRouteConfiguration *injected = [self defaultRouteConfigurationFromBlock];\
    if (injected) {\
        configuration.injected = injected;\
        configuration = injected;\
    }\
    if (configBuilder) {\
        configBuilder(configuration);\
    }\
};\

- (void(^)(ZIKViewRouteConfiguration *config))_injectedConfigBuilder:(void(^)(ZIKViewRouteConfiguration *config))builder {
    return ^(ZIKViewRouteConfiguration *configuration) {
        configuration.route = self;
        ZIKViewRouteConfiguration *injected = [self defaultRouteConfigurationFromBlock];
        if (injected) {
            configuration.injected = injected;
            configuration = injected;
        }
        if (builder) {
            builder(configuration);
        }
    };
}

#define INJECT_REMOVE_BUILDER removeConfigBuilder = ^(ZIKViewRemoveConfiguration *configuration) {\
    ZIKViewRemoveConfiguration *injected = [self defaultRemoveRouteConfigurationFromBlock];\
    if (injected) {\
        configuration.injected = injected;\
        configuration = injected;\
    }\
    if (removeConfigBuilder) {\
        removeConfigBuilder(configuration);\
    }\
};\

- (void(^)(ZIKViewRemoveConfiguration *config))_injectedRemoveConfigBuilder:(void(^)(ZIKViewRemoveConfiguration *config))builder {
    return ^(ZIKViewRemoveConfiguration *configuration) {
        ZIKViewRemoveConfiguration *injected = [self defaultRemoveRouteConfigurationFromBlock];
        if (injected) {
            configuration.injected = injected;
            configuration = injected;
        }
        if (builder) {
            builder(configuration);
        }
    };
}

#define INJECT_STRICT_CONFIG_BUILDER configBuilder = ^(ZIKPerformRouteStrictConfiguration<id> *strictConfig, ZIKViewRouteConfiguration *configuration) {\
    configuration.route = self;\
    ZIKViewRouteConfiguration *injected = [self defaultRouteConfigurationFromBlock];\
    if (injected) {\
        configuration.injected = injected;\
        configuration = injected;\
        strictConfig.configuration = injected;\
    }\
    if (configBuilder) {\
        configBuilder(strictConfig, configuration);\
    }\
};\

- (void (^)(ZIKPerformRouteStrictConfiguration<id> * _Nonnull, ZIKViewRouteConfiguration * _Nonnull))
_injectedStrictConfigBuilder:
(void (^)(ZIKPerformRouteStrictConfiguration<id> * _Nonnull, ZIKViewRouteConfiguration * _Nonnull)
 )builder {
    return ^(ZIKPerformRouteStrictConfiguration<id> *strictConfig, ZIKViewRouteConfiguration *configuration) {
        configuration.route = self;
        ZIKViewRouteConfiguration *injected = [self defaultRouteConfigurationFromBlock];
        if (injected) {
            configuration.injected = injected;
            configuration = injected;
            strictConfig.configuration = injected;
        }
        if (builder) {
            builder(strictConfig, configuration);
        }
    };
}

#define INJECT_STRICT_REMOVE_BUILDER removeConfigBuilder = ^(ZIKRemoveRouteStrictConfiguration<id> *strictConfig) {\
    ZIKViewRemoveConfiguration *injected = [self defaultRemoveRouteConfigurationFromBlock];\
    if (injected) {\
        ZIKRemoveRouteConfiguration *configuration = strictConfig.configuration;\
        configuration.injected = injected;\
        strictConfig.configuration = injected;\
    }\
    if (removeConfigBuilder) {\
        removeConfigBuilder(strictConfig);\
    }\
};\

- (void (^)(ZIKRemoveRouteStrictConfiguration<id> * _Nonnull))
_injectedStrictRemoveConfigBuilder:
(void (^)(ZIKRemoveRouteStrictConfiguration<id> * _Nonnull)
 )builder {
    return ^(ZIKRemoveRouteStrictConfiguration<id> *strictConfig) {
        ZIKViewRemoveConfiguration *injected = [self defaultRemoveRouteConfigurationFromBlock];
        if (injected) {
            ZIKRemoveRouteConfiguration *configuration = strictConfig.configuration;
            configuration.injected = injected;
            strictConfig.configuration = injected;
        }
        if (builder) {
            builder(strictConfig);
        }
    };
}

- (BOOL)shouldAutoCreateForDestination:(id)destination fromSource:(nullable id)source {
    if (self.shouldAutoCreateForDestinationBlock) {
        return self.shouldAutoCreateForDestinationBlock(destination, source);
    }
    return [self.routerClass shouldAutoCreateForDestination:destination fromSource:source];
}

- (id)performPath:(ZIKViewRoutePath *)path configuring:(void(NS_NOESCAPE ^)(ZIKViewRouteConfiguration *config))configBuilder {
    return [self performPath:path configuring:configBuilder removing:nil];
}

- (id)performPath:(ZIKViewRoutePath *)path {
    return [self performPath:path configuring:^(ZIKViewRouteConfiguration * _Nonnull config) {
        
    } removing:nil];
}

- (id)performPath:(ZIKViewRoutePath *)path
   successHandler:(void(^ _Nullable)(id destination))performerSuccessHandler
     errorHandler:(void(^ _Nullable)(ZIKRouteAction routeAction, NSError *error))performerErrorHandler {
    return [self performPath:path configuring:^(ZIKViewRouteConfiguration * _Nonnull config) {
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

- (id)performPath:(ZIKViewRoutePath *)path completion:(ZIKPerformRouteCompletion)performerCompletion {
    return [self performPath:path successHandler:^(id destination) {
        if (performerCompletion) {
            performerCompletion(YES, destination, ZIKRouteActionPerformRoute, nil);
        }
    } errorHandler:^(ZIKRouteAction routeAction, NSError *error) {
        if (performerCompletion) {
            performerCompletion(NO, nil, routeAction, error);
        }
    }];
}

- (id)performPath:(ZIKViewRoutePath *)path preparation:(void(^)(id destination))prepare {
    return [self performPath:path configuring:^(ZIKViewRouteConfiguration * _Nonnull config) {
        config.prepareDestination = prepare;
    }];
}

- (id)performPath:(ZIKViewRoutePath *)path
      configuring:(void(NS_NOESCAPE ^)(ZIKViewRouteConfiguration *config))configBuilder
         removing:(void(NS_NOESCAPE ^ _Nullable)(ZIKViewRemoveConfiguration *config))removeConfigBuilder {
    INJECT_CONFIG_BUILDER;
    INJECT_REMOVE_BUILDER;
    return [[self routerClass] performPath:path configuring:configBuilder removing:removeConfigBuilder];
}

- (id)performPath:(ZIKViewRoutePath *)path
strictConfiguring:(void (^)(ZIKPerformRouteStrictConfiguration<id> * _Nonnull, ZIKViewRouteConfiguration * _Nonnull))configBuilder {
    return [self performPath:path strictConfiguring:configBuilder strictRemoving:nil];
}

- (id)performPath:(ZIKViewRoutePath *)path
strictConfiguring:(void (^)(ZIKPerformRouteStrictConfiguration<id> * _Nonnull, ZIKViewRouteConfiguration * _Nonnull))configBuilder
   strictRemoving:(void (^)(ZIKRemoveRouteStrictConfiguration<id> * _Nonnull))removeConfigBuilder {
    INJECT_STRICT_CONFIG_BUILDER;
    INJECT_STRICT_REMOVE_BUILDER;
    return [[self routerClass] performPath:path strictConfiguring:configBuilder strictRemoving:removeConfigBuilder];
}

- (id)performOnDestination:(id)destination
                      path:(ZIKViewRoutePath *)path
               configuring:(void(NS_NOESCAPE ^)(ZIKViewRouteConfiguration *config))configBuilder {
    return [self performOnDestination:destination path:path configuring:configBuilder removing:nil];
}

- (id)performOnDestination:(id)destination
                      path:(ZIKViewRoutePath *)path
               configuring:(void(NS_NOESCAPE ^)(ZIKViewRouteConfiguration *config))configBuilder
                  removing:(void(NS_NOESCAPE ^ _Nullable)(ZIKViewRemoveConfiguration *config))removeConfigBuilder {
    INJECT_CONFIG_BUILDER;
    INJECT_REMOVE_BUILDER;
    return [[self routerClass] performOnDestination:destination path:path configuring:configBuilder removing:removeConfigBuilder];
}

- (id)performOnDestination:(id)destination
                      path:(ZIKViewRoutePath *)path {
    return [self performOnDestination:destination path:path configuring:^(__kindof ZIKViewRouteConfiguration * _Nonnull config) {
        
    } removing:nil];
}

- (id)performOnDestination:(id)destination
                      path:(ZIKViewRoutePath *)path
         strictConfiguring:(void (^)(ZIKPerformRouteStrictConfiguration<id> * _Nonnull, ZIKViewRouteConfiguration * _Nonnull))configBuilder {
    return [self performOnDestination:destination path:path strictConfiguring:configBuilder strictRemoving:nil];
}

- (id)performOnDestination:(id)destination
                      path:(ZIKViewRoutePath *)path
         strictConfiguring:(void (^)(ZIKPerformRouteStrictConfiguration<id> * _Nonnull, ZIKViewRouteConfiguration * _Nonnull))configBuilder
            strictRemoving:(void (^)(ZIKRemoveRouteStrictConfiguration<id> * _Nonnull))removeConfigBuilder {
    INJECT_STRICT_CONFIG_BUILDER;
    INJECT_STRICT_REMOVE_BUILDER;
    return [[self routerClass] performOnDestination:destination path:path strictConfiguring:configBuilder strictRemoving:removeConfigBuilder];
}

- (id)prepareDestination:(id)destination
             configuring:(void(NS_NOESCAPE ^)(ZIKViewRouteConfiguration *config))configBuilder {
    return [self prepareDestination:destination configuring:configBuilder removing:nil];
}

- (id)prepareDestination:(id)destination
             configuring:(void(NS_NOESCAPE ^)(ZIKViewRouteConfiguration *config))configBuilder
                removing:(void(NS_NOESCAPE ^ _Nullable)(ZIKViewRemoveConfiguration *config))removeConfigBuilder {
    INJECT_CONFIG_BUILDER;
    INJECT_REMOVE_BUILDER;
    return [[self routerClass] prepareDestination:destination configuring:configBuilder removing:removeConfigBuilder];
}

- (id)prepareDestination:(id)destination strictConfiguring:(void (^)(ZIKPerformRouteStrictConfiguration<id> * _Nonnull, ZIKViewRouteConfiguration * _Nonnull))configBuilder {
    return [self prepareDestination:destination strictConfiguring:configBuilder strictRemoving:nil];
}

- (id)prepareDestination:(id)destination
       strictConfiguring:(void (^)(ZIKPerformRouteStrictConfiguration<id> * _Nonnull, ZIKViewRouteConfiguration * _Nonnull))configBuilder
          strictRemoving:(void (^ _Nullable)(ZIKRemoveRouteStrictConfiguration<id> * _Nonnull))removeConfigBuilder {
    INJECT_STRICT_CONFIG_BUILDER;
    INJECT_STRICT_REMOVE_BUILDER;
    return [[self routerClass] prepareDestination:destination strictConfiguring:configBuilder strictRemoving:removeConfigBuilder];
}

- (id)routerFromSegueIdentifier:(NSString *)identifier sender:(nullable id)sender destination:(XXViewController *)destination source:(XXViewController *)source {
    ZIKBlockViewRouter *router = [[self routerClass] routerFromSegueIdentifier:identifier sender:sender destination:destination source:source configuring:^(ZIKPerformRouteConfiguration * _Nonnull config) {
        config.route = self;
    }];
    return router;
}
- (id)routerFromView:(XXView *)destination source:(XXView *)source {
    ZIKBlockViewRouter *router = [[self routerClass] routerFromView:destination source:source configuring:^(ZIKPerformRouteConfiguration * _Nonnull config) {
        config.route = self;
    }];
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

- (ZIKViewRouteTypeMask)supportedRouteTypes {
    if (self.makeSupportedRouteTypesBlock) {
        return (ZIKViewRouteTypeMask)self.makeSupportedRouteTypesBlock();
    }
    return [[self routerClass] supportedRouteTypes];
}

- (BOOL)supportRouteType:(ZIKViewRouteType)type {
    ZIKViewRouteTypeMask supportedRouteTypes = [self supportedRouteTypes];
    ZIKViewRouteTypeMask mask = 1 << type;
    if ((supportedRouteTypes & mask) == mask) {
        return YES;
    }
    return NO;
}

- (Class)routerClassForSupportedRouteTypes:(ZIKBlockViewRouteTypeMask)supportedTypes {
    switch ((NSInteger)supportedTypes) {
        case ZIKBlockViewRouteTypeMaskViewControllerDefault:
            return [ZIKBlockViewRouter class];
            break;
        case ZIKBlockViewRouteTypeMaskViewControllerDefault | ZIKBlockViewRouteTypeMaskCustom:
            return [ZIKBlockCustomViewRouter class];
            break;
        case ZIKBlockViewRouteTypeMaskViewDefault:
            return [ZIKBlockSubviewRouter class];
            break;
        case ZIKBlockViewRouteTypeMaskViewDefault | ZIKBlockViewRouteTypeMaskCustom:
            return [ZIKBlockCustomSubviewRouter class];
            break;
        case ZIKBlockViewRouteTypeMaskCustom:
            return [ZIKBlockCustomOnlyViewRouter class];
            break;
        case ZIKBlockViewRouteTypeMaskViewControllerDefault | ZIKBlockViewRouteTypeMaskViewDefault:
            return [ZIKBlockAnyViewRouter class];
            break;
        case ZIKBlockViewRouteTypeMaskViewControllerDefault | ZIKBlockViewRouteTypeMaskViewDefault | ZIKBlockViewRouteTypeMaskCustom:
            return [ZIKBlockAllViewRouter class];
            break;
    }
    return [ZIKBlockViewRouter class];
}

#pragma mark Deprecated

- (id)performFromSource:(nullable id<ZIKViewRouteSource>)source configuring:(void(NS_NOESCAPE ^)(ZIKViewRouteConfiguration *config))configBuilder {
    return [self performFromSource:source configuring:configBuilder removing:nil];
}

- (id)performFromSource:(nullable id)source routeType:(ZIKViewRouteType)routeType {
    ZIKViewRoutePath *path = [[ZIKViewRoutePath alloc] initWithRouteType:routeType source:source];
    return [self performPath:path];
}

- (id)performFromSource:(nullable id<ZIKViewRouteSource>)source
              routeType:(ZIKViewRouteType)routeType
         successHandler:(void(^ _Nullable)(id destination))performerSuccessHandler
           errorHandler:(void(^ _Nullable)(ZIKRouteAction routeAction, NSError *error))performerErrorHandler {
    ZIKViewRoutePath *path = [[ZIKViewRoutePath alloc] initWithRouteType:routeType source:source];
    return [self performPath:path successHandler:performerSuccessHandler errorHandler:performerErrorHandler];
}

- (id)performFromSource:(nullable id<ZIKViewRouteSource>)source routeType:(ZIKViewRouteType)routeType completion:(ZIKPerformRouteCompletion)performerCompletion {
    ZIKViewRoutePath *path = [[ZIKViewRoutePath alloc] initWithRouteType:routeType source:source];
    return [self performPath:path completion:performerCompletion];
}

- (id)performFromSource:(nullable id<ZIKViewRouteSource>)source
            configuring:(void(NS_NOESCAPE ^)(ZIKViewRouteConfiguration *config))configBuilder
               removing:(void(NS_NOESCAPE ^ _Nullable)(ZIKViewRemoveConfiguration *config))removeConfigBuilder {
    INJECT_CONFIG_BUILDER;
    INJECT_REMOVE_BUILDER;
    return [[self routerClass] performFromSource:source configuring:configBuilder removing:removeConfigBuilder];
}

- (id)performFromSource:(id<ZIKViewRouteSource>)source
      strictConfiguring:(void (^)(ZIKPerformRouteStrictConfiguration<id> * _Nonnull, ZIKViewRouteConfiguration * _Nonnull))configBuilder {
    return [self performFromSource:source strictConfiguring:configBuilder strictRemoving:nil];
}

- (id)performFromSource:(id<ZIKViewRouteSource>)source
      strictConfiguring:(void (^)(ZIKPerformRouteStrictConfiguration<id> * _Nonnull, ZIKViewRouteConfiguration * _Nonnull))configBuilder
         strictRemoving:(void (^)(ZIKRemoveRouteStrictConfiguration<id> * _Nonnull))removeConfigBuilder {
    INJECT_STRICT_CONFIG_BUILDER;
    INJECT_STRICT_REMOVE_BUILDER;
    return [[self routerClass] performFromSource:source strictConfiguring:configBuilder strictRemoving:removeConfigBuilder];
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
    INJECT_CONFIG_BUILDER;
    INJECT_REMOVE_BUILDER;
    return [[self routerClass] performOnDestination:destination fromSource:source configuring:configBuilder removing:removeConfigBuilder];
}

- (id)performOnDestination:(id)destination
                fromSource:(nullable id<ZIKViewRouteSource>)source
                 routeType:(ZIKViewRouteType)routeType {
    ZIKViewRoutePath *path = [[ZIKViewRoutePath alloc] initWithRouteType:routeType source:source];
    return [self performOnDestination:destination path:path];
}

- (id)performOnDestination:(id)destination
                fromSource:(id<ZIKViewRouteSource>)source
         strictConfiguring:(void (^)(ZIKPerformRouteStrictConfiguration<id> * _Nonnull, ZIKViewRouteConfiguration * _Nonnull))configBuilder {
    return [self performOnDestination:destination fromSource:source strictConfiguring:configBuilder strictRemoving:nil];
}

- (id)performOnDestination:(id)destination
                fromSource:(id<ZIKViewRouteSource>)source
         strictConfiguring:(void (^)(ZIKPerformRouteStrictConfiguration<id> * _Nonnull, ZIKViewRouteConfiguration * _Nonnull))configBuilder
            strictRemoving:(void (^)(ZIKRemoveRouteStrictConfiguration<id> * _Nonnull))removeConfigBuilder {
    INJECT_STRICT_CONFIG_BUILDER;
    INJECT_STRICT_REMOVE_BUILDER;
    return [[self routerClass] performOnDestination:destination fromSource:source strictConfiguring:configBuilder strictRemoving:removeConfigBuilder];
}

@end

#endif
