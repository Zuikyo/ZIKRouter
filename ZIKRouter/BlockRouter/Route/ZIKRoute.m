//
//  ZIKRoute.m
//  ZIKRouter
//
//  Created by zuik on 2018/4/7.
//  Copyright © 2018 zuik. All rights reserved.
//

#import "ZIKRoute.h"
#import "ZIKRouterInternal.h"
#import "ZIKRouteConfiguration.h"
#import "ZIKRouteRegistryInternal.h"
#import "ZIKRouteConfigurationPrivate.h"
#import "ZIKPerformRouteConfiguration+Route.h"

@interface ZIKRoute()
@property (nonatomic, strong) ZIKRoute *retainedSelf;
@property (nonatomic, strong) Class destinationClass;
@property (nonatomic, copy) _Nullable id(^makeDestinationBlock)(ZIKPerformRouteConfiguration *config, ZIKRouter *router);
@property (nonatomic, copy, nullable) ZIKPerformRouteConfiguration *(^makeDefaultConfigurationBlock)(void);
@property (nonatomic, copy, nullable) ZIKRemoveRouteConfiguration *(^makeDefaultRemoveConfigurationBlock)(void);
@property (nonatomic, copy, nullable) void(^prepareDestinationBlock)(id destination, ZIKPerformRouteConfiguration *config, ZIKRouter *router);
@property (nonatomic, copy, nullable) void(^didFinishPrepareDestinationBlock)(id destination, ZIKPerformRouteConfiguration *config, ZIKRouter *router);
@end

@implementation ZIKRoute

- (instancetype)initWithDestination:(Class)destinationClass makeDestination:(id  _Nullable (^)(ZIKPerformRouteConfiguration * _Nonnull, ZIKRouter * _Nonnull))makeDestination {
    if (self = [super init]) {
        self.retainedSelf = self;
        self.makeDestinationBlock = makeDestination;
        self.registerDestination(destinationClass);
    }
    return self;
}

- (NSString *)name {
    if (_name == nil) {
        return [NSString stringWithFormat:@"Anonymous route for destination: %@", NSStringFromClass(self.destinationClass)];
    }
    return _name;
}

+ (instancetype)makeRouteWithDestination:(Class)destinationClass makeDestination:(id  _Nullable (^)(ZIKPerformRouteConfiguration * _Nonnull, ZIKRouter * _Nonnull))makeDestination {
    return [[self alloc] initWithDestination:destinationClass makeDestination:makeDestination];
}

+ (Class)registryClass {
    return nil;
}

- (ZIKRoute<id, ZIKPerformRouteConfiguration *, ZIKRemoveRouteConfiguration *> *(^)(Class))registerDestination {
    return ^(Class destinationClass) {
        //register class with route
        [[[self class] registryClass] registerDestination:destinationClass route:self];
        self.destinationClass = destinationClass;
        return self;
    };
};

- (ZIKRoute<id, ZIKPerformRouteConfiguration *, ZIKRemoveRouteConfiguration *> *(^)(Protocol *))registerDestinationProtocol {
    return ^(Protocol *destinationProtocol) {
        //register destination protocol with route
        [[[self class] registryClass] registerDestinationProtocol:destinationProtocol route:self];
        return self;
    };
};

- (ZIKRoute<id, ZIKPerformRouteConfiguration *, ZIKRemoveRouteConfiguration *> *(^)(Protocol *))registerModuleProtocol {
    return ^(Protocol *moduleConfigProtocol) {
        //register module protocol with route
        [[[self class] registryClass] registerModuleProtocol:moduleConfigProtocol route:self];
        return self;
    };
};

- (ZIKRoute<id, ZIKPerformRouteConfiguration *, ZIKRemoveRouteConfiguration *> *(^)(ZIKPerformRouteConfiguration *(^)(void)))makeDefaultConfiguration {
    return ^(ZIKPerformRouteConfiguration *(^block)(void)) {
        self.makeDefaultConfigurationBlock = block;
        return self;
    };
};

- (ZIKRoute<id, ZIKPerformRouteConfiguration *, ZIKRemoveRouteConfiguration *> *(^)(ZIKRemoveRouteConfiguration *(^)(void)))makeDefaultRemoveConfiguration {
    return ^(ZIKRemoveRouteConfiguration *(^block)(void)) {
        self.makeDefaultRemoveConfigurationBlock = block;
        return self;
    };
};

- (ZIKRoute<id, ZIKPerformRouteConfiguration *, ZIKRemoveRouteConfiguration *> *(^)(void(^)(id destination, ZIKPerformRouteConfiguration *config, ZIKRouter *router)))prepareDestination {
    return ^(void(^block)(id destination, ZIKPerformRouteConfiguration *config, ZIKRouter *router)) {
        self.prepareDestinationBlock = block;
        return self;
    };
};

- (ZIKRoute<id, ZIKPerformRouteConfiguration *, ZIKRemoveRouteConfiguration *> *(^)(void(^)(id destination, ZIKPerformRouteConfiguration *config, ZIKRouter *router)))didFinishPrepareDestination {
    return ^(void(^block)(id destination, ZIKPerformRouteConfiguration *config, ZIKRouter *router)) {
        self.didFinishPrepareDestinationBlock = block;
        return self;
    };
};

#pragma mark Inject

// Let route works like class, and inject route to block router

- (Class)routerClass {
    NSAssert(NO, @"Must set router class to forward message");
    return nil;
}

- (id)forwardingTargetForSelector:(SEL)aSelector {
    return [self routerClass];
}

- (BOOL)respondsToSelector:(SEL)aSelector {
    if ([super respondsToSelector:aSelector]) {
        return YES;
    }
    return [[self routerClass] respondsToSelector:aSelector];
}

- (instancetype)alloc {
    return self;
}

- (instancetype)allocWithZone:(struct _NSZone *)zone {
    return self;
}

- (void(^)(ZIKPerformRouteConfiguration *config))_injectedConfigBuilder:(void(^)(ZIKPerformRouteConfiguration *config))builder {
    return ^(ZIKPerformRouteConfiguration *configuration) {
        configuration.route = self;
        ZIKPerformRouteConfiguration *injected = [self defaultRouteConfigurationFromBlock];
        if (injected && configuration->_injectable != NULL) {
            *configuration->_injectable = injected;
            configuration->_injectable = NULL;
        }
        if (builder) {
            builder(injected);
        }
    };
}

- (void(^)(ZIKRemoveRouteConfiguration *config))_injectedRemoveConfigBuilder:(void(^)(ZIKRemoveRouteConfiguration *config))builder {
    return ^(ZIKRemoveRouteConfiguration *configuration) {
        ZIKRemoveRouteConfiguration *injected = [self defaultRemoveRouteConfigurationFromBlock];
        if (injected && configuration->_injectable != NULL) {
            *configuration->_injectable = injected;
            configuration->_injectable = NULL;
        }
        if (builder) {
            builder(injected);
        }
    };
}

- (void (^)(ZIKPerformRouteConfiguration * _Nonnull, void (^ _Nonnull)(void (^ _Nonnull)(id _Nonnull)),
            void (^ _Nonnull)(void (^ _Nonnull)(ZIKPerformRouteConfiguration * _Nonnull))))
_injectedStrictConfigBuilder:
(void (^)(ZIKPerformRouteConfiguration * _Nonnull,
 void (^ _Nonnull)(void (^ _Nonnull)(id _Nonnull)),
 void (^ _Nonnull)(void (^ _Nonnull)(ZIKPerformRouteConfiguration * _Nonnull)))
 )builder {
    return ^(ZIKPerformRouteConfiguration * _Nonnull configuration,
             void (^ _Nonnull prepareDestination)(void (^ _Nonnull)(id _Nonnull)),
             void (^ _Nonnull prepareModule)(void (^ _Nonnull)(ZIKPerformRouteConfiguration * _Nonnull))) {
        configuration.route = self;
        ZIKPerformRouteConfiguration *injected = [self defaultRouteConfigurationFromBlock];
        if (injected && *configuration->_injectable != NULL) {
            *configuration->_injectable = injected;
            configuration->_injectable = NULL;
        }
        if (builder) {
            builder(configuration, prepareDestination, prepareModule);
        }
    };
}

- (void (^)(ZIKRemoveRouteConfiguration * _Nonnull,
            void (^ _Nonnull)(void (^ _Nonnull)(id _Nonnull))))
_injectedStrictRemoveConfigBuilder:
(void (^)(ZIKRemoveRouteConfiguration * _Nonnull,
 void (^ _Nonnull)(void (^ _Nonnull)(id _Nonnull)))
 )builder {
    return ^(ZIKRemoveRouteConfiguration * _Nonnull configuration, void (^ _Nonnull prepareDestination)(void (^ _Nonnull)(id _Nonnull))) {
        ZIKRemoveRouteConfiguration *injected = [self defaultRemoveRouteConfigurationFromBlock];
        if (injected && *configuration->_injectable != NULL) {
            *configuration->_injectable = injected;
            configuration->_injectable = NULL;
        }
        if (builder) {
            builder(configuration, prepareDestination);
        }
    };
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-designated-initializers"

- (id)initWithConfiguration:(ZIKPerformRouteConfiguration *)configuration removeConfiguration:(nullable ZIKRemoveRouteConfiguration *)removeConfiguration {
    if (configuration.route == nil) {
        configuration.route = self;
    }
    return [[[self routerClass] alloc] initWithConfiguration:configuration removeConfiguration:removeConfiguration];
}

- (id)initWithConfiguring:(void(^)(ZIKPerformRouteConfiguration *configuration))configBuilder removing:(void(^ _Nullable)(ZIKRemoveRouteConfiguration *configuration))removeConfigBuilder {
    configBuilder = [self _injectedConfigBuilder:configBuilder];
    removeConfigBuilder = [self _injectedRemoveConfigBuilder:removeConfigBuilder];
    return [[[self routerClass] alloc] initWithConfiguring:configBuilder removing:removeConfigBuilder];
}

- (id)initWithStrictConfiguring:(void (^)(ZIKPerformRouteConfiguration * _Nonnull,
                                          void (^ _Nonnull)(void (^ _Nonnull)(id _Nonnull)),
                                          void (^ _Nonnull)(void (^ _Nonnull)(ZIKPerformRouteConfiguration * _Nonnull))
                                          ))configBuilder
                 strictRemoving:(void (^ _Nullable)(ZIKRemoveRouteConfiguration * _Nonnull,
                                                    void (^ _Nonnull)(void (^ _Nonnull)(id _Nonnull))
                                                    ))removeConfigBuilder {
    configBuilder = [self _injectedStrictConfigBuilder:configBuilder];
    removeConfigBuilder = [self _injectedStrictRemoveConfigBuilder:removeConfigBuilder];
    return [[[self routerClass] alloc] initWithStrictConfiguring:configBuilder strictRemoving:removeConfigBuilder];
}

#pragma clang diagnostic pop

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"

- (id)performRoute {
    return [self performWithConfiguring:^(ZIKPerformRouteConfiguration * _Nonnull configuration) {
        
    } removing:nil];
}

- (id)performWithConfiguring:(void(^)(ZIKPerformRouteConfiguration *configuration))configBuilder {
    return [self performWithConfiguring:configBuilder removing:nil];
}

- (id)performWithConfiguring:(void(^)(ZIKPerformRouteConfiguration *configuration))configBuilder removing:(void(^)(ZIKRemoveRouteConfiguration *configuration))removeConfigBuilder {
    configBuilder = [self _injectedConfigBuilder:configBuilder];
    removeConfigBuilder = [self _injectedRemoveConfigBuilder:removeConfigBuilder];
    return [[self routerClass] performWithConfiguring:configBuilder removing:removeConfigBuilder];
}

- (id)performWithStrictConfiguring:(void (^)(ZIKPerformRouteConfiguration * _Nonnull,
                                             void (^ _Nonnull)(void (^ _Nonnull)(id _Nonnull)),
                                             void (^ _Nonnull)(void (^ _Nonnull)(ZIKPerformRouteConfiguration * _Nonnull))
                                             ))configBuilder {
    return [self performWithStrictConfiguring:configBuilder strictRemoving:nil];
}

- (id)performWithRouteConfiguring:(void (^)(ZIKPerformRouteConfiguration * _Nonnull,
                                            void (^ _Nonnull)(void (^ _Nonnull)(id _Nonnull)),
                                            void (^ _Nonnull)(void (^ _Nonnull)(ZIKPerformRouteConfiguration * _Nonnull))
                                            ))configBuilder {
    return [self performWithRouteConfiguring:configBuilder routeRemoving:nil];
}

- (id)performWithStrictConfiguring:(void (^)(ZIKPerformRouteConfiguration * _Nonnull,
                                             void (^ _Nonnull)(void (^ _Nonnull)(id _Nonnull)),
                                             void (^ _Nonnull)(void (^ _Nonnull)(ZIKPerformRouteConfiguration * _Nonnull))
                                             ))configBuilder
                    strictRemoving:(void (^)(ZIKRemoveRouteConfiguration * _Nonnull,
                                             void (^ _Nonnull)(void (^ _Nonnull)(id _Nonnull))
                                             ))removeConfigBuilder {
    configBuilder = [self _injectedStrictConfigBuilder:configBuilder];
    removeConfigBuilder = [self _injectedStrictRemoveConfigBuilder:removeConfigBuilder];
    return [[self routerClass] performWithStrictConfiguring:configBuilder strictRemoving:removeConfigBuilder];
}

- (id)performWithRouteConfiguring:(void (^)(ZIKPerformRouteConfiguration * _Nonnull,
                                            void (^ _Nonnull)(void (^ _Nonnull)(id _Nonnull)),
                                            void (^ _Nonnull)(void (^ _Nonnull)(ZIKPerformRouteConfiguration * _Nonnull))
                                            ))configBuilder
                    routeRemoving:(void (^)(ZIKRemoveRouteConfiguration * _Nonnull,
                                            void (^ _Nonnull)(void (^ _Nonnull)(id _Nonnull))
                                            ))removeConfigBuilder {
    configBuilder = [self _injectedStrictConfigBuilder:configBuilder];
    removeConfigBuilder = [self _injectedStrictRemoveConfigBuilder:removeConfigBuilder];
    return [self performWithStrictConfiguring:configBuilder strictRemoving:removeConfigBuilder];
}

- (id)makeDestinationWithPreparation:(void(^ _Nullable)(id destination))prepare {
    return [self makeDestinationWithConfiguring:^(ZIKPerformRouteConfiguration * _Nonnull config) {
        if (prepare) {
            config.prepareDestination = prepare;
        }
    }];
}

- (id)makeDestinationWithConfiguring:(void(^ _Nullable)(ZIKPerformRouteConfiguration *config))configBuilder {
    configBuilder = [self _injectedConfigBuilder:configBuilder];
    return [[self routerClass] makeDestinationWithConfiguring:configBuilder];
}

- (id)makeDestinationWithStrictConfiguring:(void (^)(ZIKPerformRouteConfiguration * _Nonnull,
                                                     void (^ _Nonnull)(void (^ _Nonnull)(id _Nonnull)),
                                                     void (^ _Nonnull)(void (^ _Nonnull)(ZIKPerformRouteConfiguration * _Nonnull))
                                                     ))configBuilder {
    configBuilder = [self _injectedStrictConfigBuilder:configBuilder];
    return [[self routerClass] makeDestinationWithStrictConfiguring:configBuilder];
}

- (id)makeDestinationWithRouteConfiguring:(void (^)(ZIKPerformRouteConfiguration * _Nonnull,
                                                    void (^ _Nonnull)(void (^ _Nonnull)(id _Nonnull)),
                                                    void (^ _Nonnull)(void (^ _Nonnull)(ZIKPerformRouteConfiguration * _Nonnull))
                                                    ))configBuilder {
    return [self makeDestinationWithStrictConfiguring:configBuilder];
}

- (id)makeDestination {
    return [self makeDestinationWithPreparation:nil];
}

#pragma clang diagnostic pop

- (ZIKPerformRouteConfiguration *)defaultRouteConfiguration {
    ZIKPerformRouteConfiguration *config = [self defaultRouteConfigurationFromBlock];
    if (config) {
        return config;
    }
    config = [[self routerClass] defaultRouteConfiguration];
    config.route = self;
    return config;
}

- (ZIKRemoveRouteConfiguration *)defaultRemoveRouteConfiguration {
    ZIKRemoveRouteConfiguration *config = [self defaultRemoveRouteConfigurationFromBlock];
    if (config) {
        return config;
    }
    return [[self routerClass] defaultRemoveConfiguration];
}

- (nullable ZIKPerformRouteConfiguration *)defaultRouteConfigurationFromBlock {
    if (self.makeDefaultConfigurationBlock) {
        ZIKPerformRouteConfiguration *config = self.makeDefaultConfigurationBlock();
        config.route = self;
        return config;
    }
    return nil;
}

- (nullable ZIKRemoveRouteConfiguration *)defaultRemoveRouteConfigurationFromBlock {
    if (self.makeDefaultRemoveConfigurationBlock) {
        return self.makeDefaultRemoveConfigurationBlock();
    }
    return nil;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@, name: %@",[super description], self.name];
}

@end
