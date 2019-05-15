//
//  ZIKRouteRegistry.m
//  ZIKRouter
//
//  Created by zuik on 2017/11/15.
//  Copyright © 2017 zuik. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "ZIKRouteRegistry.h"
#import "ZIKRouteRegistryInternal.h"
#import "ZIKRouterInternal.h"
#import "ZIKClassCapabilities.h"
#if ZIK_HAS_UIKIT
#import <UIKit/UIKit.h>
#else
#import <AppKit/AppKit.h>
#endif
#import <objc/runtime.h>
#import "ZIKRouterRuntime.h"
#import "ZIKRouter.h"
#import "ZIKRoute.h"
#import "ZIKRouterType.h"
#import "ZIKImageSymbol.h"
#import "NSString+Demangle.h"

static NSMutableSet<Class> *_registries;
static BOOL _autoRegister = YES;
static BOOL _registrationFinished = NO;
static CFMutableSetRef _factoryBlocks;

@interface ZIKRouteRegistry()
@property (nonatomic, class, readonly) NSMutableSet *registries;
@property (nonatomic, class) BOOL registrationFinished;
@end

/// Implementation is in ZRouter
@interface ZIKRouteRegistry(SwiftAdapter)
+ (id)_swiftRouteForDestinationAdapter:(Protocol *)destinationProtocol;
+ (id)_swiftRouteForModuleAdapter:(Protocol *)moduleProtocol;
@end

@implementation ZIKRouteRegistry

#pragma mark Auto Register

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _factoryBlocks = CFSetCreateMutable(kCFAllocatorDefault, 0, NULL);
        zix_replaceMethodWithMethod([XXApplication class], @selector(setDelegate:),
                                    self, @selector(ZIKRouteRegistry_hook_setDelegate:));
        zix_replaceMethodWithMethodType([XXStoryboard class], @selector(storyboardWithName:bundle:), true,
                                        self, @selector(ZIKRouteRegistry_hook_storyboardWithName:bundle:), true);
    });
}

+ (void)ZIKRouteRegistry_hook_setDelegate:(id)delegate {
    if (ZIKRouteRegistry.autoRegister) {
        [ZIKRouteRegistry registerAll];
    }
    [self ZIKRouteRegistry_hook_setDelegate:delegate];
}

#if ZIK_HAS_UIKIT
+ (UIStoryboard *)ZIKRouteRegistry_hook_storyboardWithName:(NSString *)name bundle:(nullable NSBundle *)storyboardBundleOrNil
#else
+ (NSStoryboard *)ZIKRouteRegistry_hook_storyboardWithName:(NSString *)name bundle:(nullable NSBundle *)storyboardBundleOrNil
#endif
{
    if (ZIKRouteRegistry.autoRegister) {
        [ZIKRouteRegistry registerAll];
    }
    return [self ZIKRouteRegistry_hook_storyboardWithName:name bundle:storyboardBundleOrNil];
}

+ (void)addRegistry:(Class)registryClass {
    NSParameterAssert([registryClass isSubclassOfClass:[ZIKRouteRegistry class]]);
    if (_registries == nil) {
        _registries = [NSMutableSet set];
    }
    [_registries addObject:registryClass];
}

+ (NSSet<Class> *)registries {
    return _registries;
}

+ (BOOL)autoRegister {
    return _autoRegister;
}

+ (void)setAutoRegister:(BOOL)autoRegister {
    if (_registrationFinished) {
        NSAssert(NO, @"Set auto register after registration is already finished.");
        return;
    }
    _autoRegister = autoRegister;
}

+ (BOOL)registrationFinished {
    return _registrationFinished;
}

+ (void)setRegistrationFinished:(BOOL)registrationFinished {
    _registrationFinished = registrationFinished;
}

+ (void)registerAll {
    if (self.registrationFinished) {
        return;
    }
    NSSet *registries = [[self registries] copy];
    if (zix_canEnumerateClassesInImage()) {
        // Fast enumeration
        zix_enumerateClassesInMainBundleForParentClass([ZIKRouter class], ^(__unsafe_unretained Class  _Nonnull aClass) {
            for (Class registry in registries) {
                [registry handleEnumerateRouterClass:aClass];
            }
        });
    } else {
        // Slow enumeration
        zix_enumerateClassList(^(__unsafe_unretained Class class) {
            for (Class registry in registries) {
                [registry handleEnumerateRouterClass:class];
            }
        });
    }
    
    self.registrationFinished = YES;
    for (Class registry in registries) {
        [registry didFinishRegistration];
    }
}

#pragma mark Discover

+ (ZIKRoute *)easyRouteForDestinationClass:(Class)destinationClass factory:(id(^)(ZIKPerformRouteConfiguration * _Nonnull config, __kindof ZIKRouter * _Nonnull router))factory {
    return [[ZIKRoute alloc] initWithMakeDestination:^id _Nullable(ZIKPerformRouteConfiguration * _Nonnull config, __kindof ZIKRouter * _Nonnull router) {
        if (!factory) {
            return nil;
        }
        return factory(config, router);
    }];
}

+ (ZIKRoute *)easyRouteForDestinationClass:(Class)destinationClass configFactory:(ZIKPerformRouteConfiguration<ZIKConfigurationMakeable> *(^)(void))factory {
    return [[ZIKRoute alloc] initWithMakeDestination:^id _Nullable(ZIKPerformRouteConfiguration<ZIKConfigurationMakeable> * _Nonnull config, __kindof ZIKRouter * _Nonnull router) {
        if ([config conformsToProtocol:@protocol(ZIKConfigurationMakeable)]) {
            if ([config respondsToSelector:@selector(makeDestination)] && config.makeDestination) {
                id destination = config.makeDestination();
                return destination;
            }
        }
        return nil;
    }].makeDefaultConfiguration(^ZIKPerformRouteConfiguration * _Nonnull{
        return factory();
    });
}

+ (ZIKRoute *)easyRouteForDestinationClass:(Class)destinationClass {
    const void *f = CFDictionaryGetValue(self.destinationToDefaultConfigFactoryMap, (__bridge const void *)(destinationClass));
    if (f) {
        ZIKPerformRouteConfiguration<ZIKConfigurationMakeable> *(*factory)(void) = f;
        if (CFSetContainsValue(_factoryBlocks, factory)) {
            ZIKPerformRouteConfiguration<ZIKConfigurationMakeable> *(^block)(void) = CFDictionaryGetValue(self.destinationToDefaultConfigFactoryMap, (__bridge const void *)(destinationClass));
            return [self easyRouteForDestinationClass:destinationClass configFactory:block];
        }
        return [self easyRouteForDestinationClass:destinationClass configFactory:^ZIKPerformRouteConfiguration *{
            return factory();
        }];
    }
    
    f = CFDictionaryGetValue(self.destinationToDefaultFactoryMap, (__bridge const void *)(destinationClass));
    if (f) {
        id _Nullable(*factory)(ZIKPerformRouteConfiguration * _Nonnull) = f;
        if (CFSetContainsValue(_factoryBlocks, factory)) {
            id _Nullable(^block)(ZIKPerformRouteConfiguration * _Nonnull) = CFDictionaryGetValue(self.destinationToDefaultFactoryMap, (__bridge const void *)(destinationClass));
            return [self easyRouteForDestinationClass:destinationClass factory:^id(ZIKPerformRouteConfiguration * _Nonnull config, __kindof ZIKRouter * _Nonnull router) {
                return block(config);
            }];
        }
        return [self easyRouteForDestinationClass:destinationClass factory:^id(ZIKPerformRouteConfiguration * _Nonnull config, __kindof ZIKRouter * _Nonnull router) {
            return factory(config);
        }];
    }
    if (CFSetContainsValue(self.runtimeFactoryDestinationClasses, (__bridge const void *)(destinationClass))) {
        return [self easyRouteForDestinationClass:destinationClass factory:^id(ZIKPerformRouteConfiguration * _Nonnull config, __kindof ZIKRouter * _Nonnull router) {
            return [[destinationClass alloc] init];
        }];
    }
    return nil;
}

+ (ZIKRoute *)easyRouteForDestinationProtocol:(Protocol *)destinationProtocol {
    Class destinationClass = CFDictionaryGetValue(self.destinationProtocolToDestinationMap, (__bridge const void *)(destinationProtocol));
    if (!destinationClass) {
        return nil;
    }
    
    id _Nullable(*factory)(ZIKPerformRouteConfiguration * _Nonnull) = CFDictionaryGetValue(self.destinationProtocolToFactoryMap, (__bridge const void *)(destinationProtocol));
    if (factory) {
        if (CFSetContainsValue(_factoryBlocks, factory)) {
            id _Nullable(^block)(ZIKPerformRouteConfiguration * _Nonnull) = CFDictionaryGetValue(self.destinationProtocolToFactoryMap, (__bridge const void *)(destinationProtocol));
            return [self easyRouteForDestinationClass:destinationClass factory:^id(ZIKPerformRouteConfiguration * _Nonnull config, __kindof ZIKRouter * _Nonnull router) {
                return block(config);
            }];
        }
        return [self easyRouteForDestinationClass:destinationClass factory:^id(ZIKPerformRouteConfiguration * _Nonnull config, __kindof ZIKRouter * _Nonnull router) {
            return factory(config);
        }];
    }
    if (CFSetContainsValue(self.runtimeFactoryDestinationClasses, (__bridge const void *)(destinationClass))) {
        return [self easyRouteForDestinationClass:destinationClass factory:^id(ZIKPerformRouteConfiguration * _Nonnull config, __kindof ZIKRouter * _Nonnull router) {
            return [[destinationClass alloc] init];
        }];
    }
    return nil;
}

+ (ZIKRoute *)easyRouteForModuleProtocol:(Protocol *)configProtocol {
    Class destinationClass = CFDictionaryGetValue(self.moduleConfigProtocolToDestinationMap, (__bridge const void *)(configProtocol));
    if (!destinationClass) {
        return nil;
    }
    ZIKPerformRouteConfiguration<ZIKConfigurationMakeable> *(*factory)(void) = CFDictionaryGetValue(self.moduleConfigProtocolToFactoryMap, (__bridge const void *)(configProtocol));
    if (factory) {
        if (CFSetContainsValue(_factoryBlocks, factory)) {
            ZIKPerformRouteConfiguration<ZIKConfigurationMakeable> *(^block)(void) = CFDictionaryGetValue(self.moduleConfigProtocolToFactoryMap, (__bridge const void *)(configProtocol));
            return [self easyRouteForDestinationClass:destinationClass configFactory:block];
        }
        return [self easyRouteForDestinationClass:destinationClass configFactory:^ZIKPerformRouteConfiguration *{
            return factory();
        }];
    }
    return nil;
}

+ (ZIKRoute *)easyRouteForIdentifier:(NSString *)identifier {
    Class destinationClass = CFDictionaryGetValue(self.identifierToDestinationMap, (__bridge CFStringRef)(identifier));
    if (!destinationClass) {
        return nil;
    }
    const void *f = CFDictionaryGetValue(self.identifierToConfigFactoryMap, (__bridge CFStringRef)(identifier));
    if (f) {
        ZIKPerformRouteConfiguration<ZIKConfigurationMakeable> *(*factory)(void) = f;
        if (CFSetContainsValue(_factoryBlocks, factory)) {
            ZIKPerformRouteConfiguration<ZIKConfigurationMakeable> *(^block)(void) = CFDictionaryGetValue(self.identifierToConfigFactoryMap, (__bridge CFStringRef)(identifier));
            return [self easyRouteForDestinationClass:destinationClass configFactory:block];
        }
        return [self easyRouteForDestinationClass:destinationClass configFactory:^ZIKPerformRouteConfiguration *{
            return factory();
        }];
    }
    
    f = CFDictionaryGetValue(self.identifierToFactoryMap, (__bridge CFStringRef)(identifier));
    if (f) {
        id _Nullable(*factory)(ZIKPerformRouteConfiguration * _Nonnull) = f;
        if (CFSetContainsValue(_factoryBlocks, factory)) {
            id _Nullable(^block)(ZIKPerformRouteConfiguration * _Nonnull) = CFDictionaryGetValue(self.identifierToFactoryMap, (__bridge CFStringRef)(identifier));
            return [self easyRouteForDestinationClass:destinationClass factory:^id(ZIKPerformRouteConfiguration * _Nonnull config, __kindof ZIKRouter * _Nonnull router) {
                return block(config);
            }];
        }
        return [self easyRouteForDestinationClass:destinationClass factory:^id(ZIKPerformRouteConfiguration * _Nonnull config, __kindof ZIKRouter * _Nonnull router) {
            return factory(config);
        }];
    }
    if (CFSetContainsValue(self.runtimeFactoryDestinationClasses, (__bridge const void *)(destinationClass))) {
        return [self easyRouteForDestinationClass:destinationClass factory:^id(ZIKPerformRouteConfiguration * _Nonnull config, __kindof ZIKRouter * _Nonnull router) {
            return [[destinationClass alloc] init];
        }];
    }
    return nil;
}

+ (Class)routerTypeClass {
    return [ZIKRouterType class];
}

+ (id)routeKeyForRouter:(ZIKRouter *)router {
    return [router class];
}

+ (nullable ZIKRouterType *)_routerTypeForObject:(id)object {
    if (object == nil) {
        return nil;
    }
    if ([object isKindOfClass:[ZIKRoute class]]) {
        return [[[self routerTypeClass] alloc] initWithRoute:object];
    } else if ([object class] == object) {
        if ([(Class)object isSubclassOfClass:[ZIKRouter class]]) {
            return [[[self routerTypeClass] alloc] initWithRouterClass:object];
        }
    }
    return nil;
}

+ (nullable ZIKRouterType *)routerToRegisteredDestinationClass:(Class)destinationClass {
    NSAssert([self isDestinationClassRoutable:destinationClass], @"destination class (%@) should conforms to ZIKRoutableView or ZIKRoutableService.", NSStringFromClass(destinationClass));
    CFMutableDictionaryRef destinationToDefaultRouterMap = self.destinationToDefaultRouterMap;
    CFDictionaryRef destinationToExclusiveRouterMap = self.destinationToExclusiveRouterMap;
    while (destinationClass) {
        if (![self isDestinationClassRoutable:destinationClass]) {
            break;
        }
        id route = CFDictionaryGetValue(destinationToDefaultRouterMap, (__bridge const void *)(destinationClass));
        if (route == nil) {
            route = CFDictionaryGetValue(destinationToExclusiveRouterMap, (__bridge const void *)(destinationClass));
            if (route) {
                CFDictionarySetValue(destinationToDefaultRouterMap, (__bridge const void *)(destinationClass), (__bridge const void *)(route));
            }
        }
        if (route == nil) {
            route = [self easyRouteForDestinationClass:destinationClass];
        }
        if (route) {
            return [self _routerTypeForObject:route];
        } else {
            destinationClass = class_getSuperclass(destinationClass);
        }
    }
    return nil;
}

+ (nullable ZIKRouterType *)routerToDestination:(Protocol *)destinationProtocol {
    NSParameterAssert(destinationProtocol);
    NSAssert(self.destinationProtocolToRouterMap != nil, @"Didn't register any protocol yet.");
    if (!destinationProtocol) {
        NSAssert1(NO, @"+routerToDestination: destinationProtocol is nil. callStackSymbols: %@",[NSThread callStackSymbols]);
        return nil;
    }
    id route = CFDictionaryGetValue(self.destinationProtocolToRouterMap, (__bridge const void *)(destinationProtocol));
    if (route == nil) {
        route = [self easyRouteForDestinationProtocol:destinationProtocol];
    }
    if (route == nil && [self respondsToSelector:@selector(_swiftRouteForDestinationAdapter:)]) {
        route = [self _swiftRouteForDestinationAdapter:destinationProtocol];
    }
    if (route == nil) {
        Protocol *adapter = destinationProtocol;
        Protocol *adaptee = nil;
#if ZIKROUTER_CHECK
        NSMutableArray<Protocol *> *traversedProtocols = [NSMutableArray array];
#endif
        do {
            adaptee = CFDictionaryGetValue(self.adapterToAdapteeMap, (__bridge const void *)(adapter));
            if (adaptee == nil) {
                break;
            }
#if ZIKROUTER_CHECK
            [traversedProtocols addObject:adapter];
            if ([traversedProtocols containsObject:adaptee]) {
                NSMutableString *adapterChain = [NSMutableString string];
                [traversedProtocols enumerateObjectsUsingBlock:^(Protocol * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    [adapterChain appendFormat:@"%@ -> ", NSStringFromProtocol(obj)];
                }];
                [adapterChain appendFormat:@"%@", NSStringFromProtocol(adaptee)];
                NSAssert(NO, @"Dead cycle in destination adapter -> adaptee chain: %@. Check your +registerDestinationAdapter:forAdaptee:.",adapterChain);
                break;
            }
#endif
            route = CFDictionaryGetValue(self.destinationProtocolToRouterMap, (__bridge const void *)(adaptee));
            if (route == nil) {
                route = [self easyRouteForDestinationProtocol:adaptee];
            }
            if (route == nil && [self respondsToSelector:@selector(_swiftRouteForDestinationAdapter:)]) {
                route = [self _swiftRouteForDestinationAdapter:adaptee];
            }
            adapter = adaptee;
        } while (route == nil);
    }
    return [self _routerTypeForObject:route];
}

+ (nullable ZIKRouterType *)routerToModule:(Protocol *)configProtocol {
    NSParameterAssert(configProtocol);
    NSAssert(self.moduleConfigProtocolToRouterMap != nil, @"Didn't register any protocol yet.");
    if (!configProtocol) {
        NSAssert1(NO, @"+routerToModule: module configProtocol is nil. callStackSymbols: %@",[NSThread callStackSymbols]);
        return nil;
    }
    id route = CFDictionaryGetValue(self.moduleConfigProtocolToRouterMap, (__bridge const void *)(configProtocol));
    if (route == nil) {
        route = [self easyRouteForModuleProtocol:configProtocol];
    }
    if (route == nil && [self respondsToSelector:@selector(_swiftRouteForDestinationAdapter:)]) {
        route = [self _swiftRouteForModuleAdapter:configProtocol];
    }
    if (route == nil) {
        Protocol *adapter = configProtocol;
        Protocol *adaptee = nil;
#if ZIKROUTER_CHECK
        NSMutableArray<Protocol *> *traversedProtocols = [NSMutableArray array];
#endif
        do {
            adaptee = CFDictionaryGetValue(self.adapterToAdapteeMap, (__bridge const void *)(adapter));
            if (adaptee == nil) {
                break;
            }
#if ZIKROUTER_CHECK
            [traversedProtocols addObject:adapter];
            if ([traversedProtocols containsObject:adaptee]) {
                NSMutableString *adapterChain = [NSMutableString string];
                [traversedProtocols enumerateObjectsUsingBlock:^(Protocol * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    [adapterChain appendFormat:@"%@ -> ", NSStringFromProtocol(obj)];
                }];
                [adapterChain appendFormat:@"%@", NSStringFromProtocol(adaptee)];
                NSAssert(NO, @"Dead cycle in module adapter -> adaptee chain: %@. Check your +registerModuleAdapter:forAdaptee:.",adapterChain);
                break;
            }
#endif
            route = CFDictionaryGetValue(self.moduleConfigProtocolToRouterMap, (__bridge const void *)(adaptee));
            if (route == nil) {
                route = [self easyRouteForModuleProtocol:adaptee];
            }
            if (route == nil && [self respondsToSelector:@selector(_swiftRouteForDestinationAdapter:)]) {
                route = [self _swiftRouteForModuleAdapter:adaptee];
            }
            adapter = adaptee;
        } while (route == nil);
    }
    return [self _routerTypeForObject:route];
}

+ (nullable ZIKRouterType *)routerToIdentifier:(NSString *)identifier {
    if (identifier == nil) {
        return nil;
    }
    id route = CFDictionaryGetValue(self.identifierToRouterMap, (CFStringRef)identifier);
    if (route == nil) {
        route = [self easyRouteForIdentifier:identifier];
    }
    return [self _routerTypeForObject:route];
}

+ (void)enumerateRoutersForDestinationClass:(Class)destinationClass handler:(void(^)(ZIKRouterType * route))handler {
    NSAssert([self isDestinationClassRoutable:destinationClass], @"destination class (%@) should conforms to ZIKRoutableView or ZIKRoutableService.", NSStringFromClass(destinationClass));
    NSParameterAssert(handler);
    if (!destinationClass) {
        return;
    }
    CFDictionaryRef destinationToExclusiveRouterMap = self.destinationToExclusiveRouterMap;
    CFDictionaryRef destinationToRoutersMap = self.destinationToRoutersMap;
    while (destinationClass) {
        if (![self isDestinationClassRoutable:destinationClass]) {
            break;
        }
        id route = CFDictionaryGetValue(destinationToExclusiveRouterMap, (__bridge const void *)(destinationClass));
        if (route) {
            ZIKRouterType *r = [self _routerTypeForObject:route];
            if (r) {
                handler(r);
            }
        } else {
            CFMutableSetRef routers = (CFMutableSetRef)CFDictionaryGetValue(destinationToRoutersMap, (__bridge const void *)(destinationClass));
            NSSet *routes = (__bridge NSSet *)(routers);
            [routes enumerateObjectsUsingBlock:^(id  _Nonnull route, BOOL * _Nonnull stop) {
                if (handler) {
                    ZIKRouterType *r = [self _routerTypeForObject:route];
                    if (r) {
                        handler(r);
                    }
                }
            }];
        }
        
        destinationClass = class_getSuperclass(destinationClass);
    }
}

#pragma mark Register

static __attribute__((always_inline)) void _registerDestinationClassWithRoute(Class destinationClass, id routeObject, Class registry) {
    NSCParameterAssert(zix_classIsSubclassOfClass(registry, [ZIKRouteRegistry class]));
    NSCParameterAssert([registry isDestinationClassRoutable:destinationClass]);
    NSCAssert3(![registry destinationToExclusiveRouterMap] ||
               ([registry destinationToExclusiveRouterMap] && !CFDictionaryGetValue([registry destinationToExclusiveRouterMap], (__bridge const void *)(destinationClass))), @"There is a registered exclusive router (%@), can't register this router (%@) for this destinationClass (%@).",CFDictionaryGetValue([registry destinationToExclusiveRouterMap], (__bridge const void *)(destinationClass)), routeObject, destinationClass);
    
    CFMutableDictionaryRef destinationToDefaultRouterMap = [registry destinationToDefaultRouterMap];
    if (!CFDictionaryContainsKey(destinationToDefaultRouterMap, (__bridge const void *)(destinationClass))) {
        CFDictionarySetValue(destinationToDefaultRouterMap, (__bridge const void *)(destinationClass), (__bridge const void *)(routeObject));
    }
    CFMutableDictionaryRef destinationToRoutersMap = [registry destinationToRoutersMap];
    CFMutableSetRef routers = (CFMutableSetRef)CFDictionaryGetValue(destinationToRoutersMap, (__bridge const void *)(destinationClass));
    if (routers == NULL) {
        routers = CFSetCreateMutable(kCFAllocatorDefault, 0, NULL);
        CFDictionarySetValue(destinationToRoutersMap, (__bridge const void *)(destinationClass), routers);
    }
    CFSetAddValue(routers, (__bridge const void *)(routeObject));
    
#if ZIKROUTER_CHECK
    CFMutableSetRef destinations = (CFMutableSetRef)CFDictionaryGetValue([registry _check_routerToDestinationsMap], (__bridge const void *)(routeObject));
    if (destinations == NULL) {
        destinations = CFSetCreateMutable(kCFAllocatorDefault, 0, NULL);
        CFDictionarySetValue([registry _check_routerToDestinationsMap], (__bridge const void *)(routeObject), destinations);
    }
    CFSetAddValue(destinations, (__bridge const void *)(destinationClass));
#endif
}

static __attribute__((always_inline)) void _registerExclusiveDestinationClassWithRoute(Class destinationClass, id routeObject, Class registry) {
    NSCParameterAssert(zix_classIsSubclassOfClass(registry, [ZIKRouteRegistry class]));
    NSCParameterAssert([registry isDestinationClassRoutable:destinationClass]);
    NSCAssert3(!CFDictionaryGetValue([registry destinationToExclusiveRouterMap], (__bridge const void *)(destinationClass)), @"There is already a registered exclusive router (%@) for this destinationClass (%@), can't register this router (%@). You can only specific one exclusive router for each destinationClass. Choose the router used as dependency injector.",CFDictionaryGetValue([registry destinationToExclusiveRouterMap], (__bridge const void *)(destinationClass)), NSStringFromClass(destinationClass), routeObject);
    NSCAssert3(!CFDictionaryGetValue([registry destinationToDefaultRouterMap], (__bridge const void *)(destinationClass)), @"destinationClass (%@) already registered with another router (%@), check and remove them. You shall only use this exclusive router (%@) for this destinationClass.",NSStringFromClass(destinationClass), CFDictionaryGetValue([registry destinationToDefaultRouterMap], (__bridge const void *)(destinationClass)), routeObject);
    NSCAssert3(!CFDictionaryContainsKey([registry destinationToRoutersMap], (__bridge const void *)(destinationClass)) ||
              (CFDictionaryContainsKey([registry destinationToRoutersMap], (__bridge const void *)(destinationClass)) &&
               !CFSetContainsValue(
                                   (CFMutableSetRef)CFDictionaryGetValue([registry destinationToRoutersMap], (__bridge const void *)(destinationClass)),
                                   (__bridge const void *)(routeObject)
                                   ))
              , @"destinationClass (%@) already registered with another router (%@), check and remove them. You shall only use this exclusive router (%@) for this destinationClass.", NSStringFromClass(destinationClass), [(__bridge NSSet *)CFDictionaryGetValue([registry destinationToRoutersMap], (__bridge const void *)(destinationClass)) anyObject], routeObject);
    NSCAssert2(!CFSetContainsValue([registry runtimeFactoryDestinationClasses], (__bridge const void *)(destinationClass)), @"destinationClass (%@) already registered with `registerXXX:forMakingXXX:`, check and remove them. You shall only use this exclusive router (%@) for this destinationClass.", NSStringFromClass(destinationClass), routeObject);
    NSCAssert2(!CFDictionaryGetValue([registry destinationToDefaultFactoryMap], (__bridge const void *)(destinationClass)), @"destinationClass (%@) already registered with `registerXXX:forMakingXXX:making:` or `registerXXX:forMakingXXX:factory:`, check and remove them. You shall only use this exclusive router (%@) for this destinationClass.", NSStringFromClass(destinationClass), routeObject);
    
    CFDictionaryAddValue([registry destinationToExclusiveRouterMap], (__bridge const void *)(destinationClass), (__bridge const void *)(routeObject));
    
#if ZIKROUTER_CHECK
    CFMutableSetRef destinations = (CFMutableSetRef)CFDictionaryGetValue([registry _check_routerToDestinationsMap], (__bridge const void *)(routeObject));
    if (destinations == NULL) {
        destinations = CFSetCreateMutable(kCFAllocatorDefault, 0, NULL);
        CFDictionarySetValue([registry _check_routerToDestinationsMap], (__bridge const void *)(routeObject), destinations);
    }
    CFSetAddValue(destinations, (__bridge const void *)(destinationClass));
#endif
}

static __attribute__((always_inline)) void _registerDestinationProtocolWithRoute(Protocol *destinationProtocol, id routeObject, Class registry) {
    NSCParameterAssert(zix_classIsSubclassOfClass(registry, [ZIKRouteRegistry class]));
    NSCAssert3(!CFDictionaryGetValue([registry destinationProtocolToRouterMap], (__bridge const void *)(destinationProtocol)) ||
               (Class)CFDictionaryGetValue([registry destinationProtocolToRouterMap], (__bridge const void *)(destinationProtocol)) == routeObject
               , @"Destination protocol (%@) already registered with another router (%@), can't register with this router (%@). Same destination protocol should only be used by one routeObject.",NSStringFromProtocol(destinationProtocol),CFDictionaryGetValue([registry destinationProtocolToRouterMap], (__bridge const void *)(destinationProtocol)),routeObject);
    
    CFDictionaryAddValue([registry destinationProtocolToRouterMap], (__bridge const void *)(destinationProtocol), (__bridge const void *)(routeObject));
#if ZIKROUTER_CHECK
    CFMutableSetRef destinationProtocols = (CFMutableSetRef)CFDictionaryGetValue([registry _check_routerToDestinationProtocolsMap], (__bridge const void *)(routeObject));
    if (destinationProtocols == NULL) {
        destinationProtocols = CFSetCreateMutable(kCFAllocatorDefault, 0, NULL);
        CFDictionarySetValue([registry _check_routerToDestinationProtocolsMap], (__bridge const void *)(routeObject), destinationProtocols);
    }
    CFSetAddValue(destinationProtocols, (__bridge const void *)(destinationProtocol));
#endif
}


static __attribute__((always_inline)) void _registerModuleProtocolWithRoute(Protocol *configProtocol, id routeObject, Class registry)  {
    NSCParameterAssert(zix_classIsSubclassOfClass(registry, [ZIKRouteRegistry class]));
    NSCAssert3(!CFDictionaryGetValue([registry moduleConfigProtocolToRouterMap], (__bridge const void *)(configProtocol)) ||
               (Class)CFDictionaryGetValue([registry moduleConfigProtocolToRouterMap], (__bridge const void *)(configProtocol)) == routeObject
               , @"Module config protocol (%@) already registered with another router (%@), can't register with this router (%@). Same configProtocol should only be used by one routeObject.",NSStringFromProtocol(configProtocol),CFDictionaryGetValue([registry moduleConfigProtocolToRouterMap], (__bridge const void *)(configProtocol)),routeObject);
    
    CFDictionaryAddValue([registry moduleConfigProtocolToRouterMap], (__bridge const void *)(configProtocol), (__bridge const void *)(routeObject));
}

static __attribute__((always_inline)) void _registerIdentifierWithRoute(NSString *identifier, id routeObject, Class registry) {
    NSCParameterAssert(zix_classIsSubclassOfClass(registry, [ZIKRouteRegistry class]));
    NSCParameterAssert(identifier.length > 0);
    if (identifier == nil) {
        return;
    }
    NSCAssert3(!CFDictionaryGetValue([registry identifierToRouterMap], (CFStringRef)identifier) ||
               (Class)CFDictionaryGetValue([registry identifierToRouterMap], (CFStringRef)identifier) == routeObject
               , @"Identifier (%@) already registered with another router (%@), can't register with this router (%@).",identifier, CFDictionaryGetValue([registry identifierToRouterMap], (CFStringRef)identifier), routeObject);
    NSCAssert3(!CFDictionaryGetValue([registry identifierToRouterMap], (CFStringRef)identifier)
              , @"Identifier (%@) already registered with another router (%@), can't register with this router (%@).",identifier, CFDictionaryGetValue([registry identifierToRouterMap], (CFStringRef)identifier), routeObject);
    NSCAssert4(!CFDictionaryGetValue([registry identifierToFactoryMap], (CFStringRef)identifier), @"Identifier (%@) already registered with a factory or block (%p) for destination (%@), can't register with this router (%@).", identifier, CFDictionaryGetValue([registry identifierToFactoryMap], (CFStringRef)identifier), NSStringFromClass(CFDictionaryGetValue([registry identifierToDestinationMap], (CFStringRef)identifier)), routeObject);
    NSCAssert4(!CFDictionaryGetValue([registry identifierToConfigFactoryMap], (CFStringRef)identifier), @"Identifier (%@) already registered with a config factory or block (%p) for destination (%@), can't register with this router (%@).", identifier, CFDictionaryGetValue([registry identifierToConfigFactoryMap], (CFStringRef)identifier), NSStringFromClass(CFDictionaryGetValue([registry identifierToDestinationMap], (CFStringRef)identifier)), routeObject);
    
    CFDictionaryAddValue([registry identifierToRouterMap], (CFStringRef)identifier, (__bridge const void *)(routeObject));
}

+ (void)registerDestinationProtocol:(Protocol *)destinationProtocol forMakingDestination:(Class)destinationClass {
    NSParameterAssert([destinationClass isKindOfClass:[NSObject class]]);
    NSAssert([destinationClass conformsToProtocol:destinationProtocol], @"destination class (%@) should conforms to registering protocol (%@)", NSStringFromClass(destinationClass), NSStringFromProtocol(destinationProtocol));
    NSAssert([self isDestinationClassRoutable:destinationClass], @"destination class (%@) should conforms to ZIKRoutableView or ZIKRoutableService.", NSStringFromClass(destinationClass));
    NSAssert3(!CFDictionaryGetValue(self.destinationProtocolToDestinationMap, (__bridge const void *)destinationProtocol), @"Protocol (%@) already registered with another destination (%@), can't be registered with destination (%@).", NSStringFromProtocol(destinationProtocol), NSStringFromClass((Class)CFDictionaryGetValue(self.destinationProtocolToDestinationMap, (__bridge const void *)destinationProtocol)), NSStringFromClass(destinationClass));
    NSAssert3(!CFDictionaryGetValue(self.destinationProtocolToFactoryMap, (__bridge const void *)destinationProtocol), @"Protocol (%@) already registered with a factory or block (%p), can't be registered with destination (%@).", NSStringFromProtocol(destinationProtocol), CFDictionaryGetValue(self.destinationProtocolToFactoryMap, (__bridge const void *)destinationProtocol), NSStringFromClass(destinationClass));
    NSAssert3(!self.destinationToExclusiveRouterMap ||
              (self.destinationToExclusiveRouterMap && !CFDictionaryGetValue(self.destinationToExclusiveRouterMap, (__bridge const void *)(destinationClass))), @"There is a registered exclusive router (%@), can't register destination protocol (%@) for this destinationClass (%@).",CFDictionaryGetValue(self.destinationToExclusiveRouterMap, (__bridge const void *)(destinationClass)), NSStringFromProtocol(destinationProtocol), destinationClass);
    CFDictionaryAddValue(self.destinationProtocolToDestinationMap, (__bridge const void *)destinationProtocol, (__bridge const void *)destinationClass);
    CFSetAddValue(self.runtimeFactoryDestinationClasses, (__bridge const void *)destinationClass);
}

+ (void)registerIdentifier:(NSString *)identifier forMakingDestination:(Class)destinationClass {
    NSParameterAssert(identifier);
    NSParameterAssert([destinationClass isKindOfClass:[NSObject class]]);
    NSAssert([self isDestinationClassRoutable:destinationClass], @"destination class (%@) should conforms to ZIKRoutableView or ZIKRoutableService.", NSStringFromClass(destinationClass));
    NSAssert3(!CFDictionaryGetValue(self.identifierToRouterMap, (CFStringRef)identifier)
              , @"Identifier (%@) already registered with another router (%@), can't register with destination class (%@).",identifier, CFDictionaryGetValue(self.identifierToRouterMap, (CFStringRef)identifier), NSStringFromClass(destinationClass));
    NSAssert4(!CFDictionaryGetValue(self.identifierToFactoryMap, (CFStringRef)identifier), @"Identifier (%@) already registered with a factory or block (%p) for destination (%@), can't be registered with destination (%@).", identifier, CFDictionaryGetValue(self.identifierToFactoryMap, (CFStringRef)identifier), NSStringFromClass(CFDictionaryGetValue(self.identifierToDestinationMap, (CFStringRef)identifier)), NSStringFromClass(destinationClass));
    NSAssert4(!CFDictionaryGetValue(self.identifierToConfigFactoryMap, (CFStringRef)identifier), @"Identifier (%@) already registered with a config factory or block (%p) for destination (%@), can't be registered with destination (%@).", identifier, CFDictionaryGetValue(self.identifierToConfigFactoryMap, (CFStringRef)identifier), NSStringFromClass(CFDictionaryGetValue(self.identifierToDestinationMap, (CFStringRef)identifier)), NSStringFromClass(destinationClass));
    NSAssert3(!self.destinationToExclusiveRouterMap ||
              (self.destinationToExclusiveRouterMap && !CFDictionaryGetValue(self.destinationToExclusiveRouterMap, (__bridge const void *)(destinationClass))), @"There is a registered exclusive router (%@), can't register identifier (%@) for this destinationClass (%@).",CFDictionaryGetValue(self.destinationToExclusiveRouterMap, (__bridge const void *)(destinationClass)), identifier, destinationClass);
    CFDictionaryAddValue(self.identifierToDestinationMap, (CFStringRef)identifier, (__bridge const void *)destinationClass);
    CFSetAddValue(self.runtimeFactoryDestinationClasses, (__bridge const void *)destinationClass);
}

+ (void)registerDestinationProtocol:(Protocol *)destinationProtocol forMakingDestination:(Class)destinationClass factoryBlock:(id _Nullable(^ _Nonnull)(ZIKPerformRouteConfiguration * _Nonnull))block {
    NSCParameterAssert(block);
    NSAssert([destinationClass conformsToProtocol:destinationProtocol], @"destination class (%@) should conforms to registering protocol (%@)", NSStringFromClass(destinationClass), NSStringFromProtocol(destinationProtocol));
    NSAssert([self isDestinationClassRoutable:destinationClass], @"destination class (%@) should conforms to ZIKRoutableView or ZIKRoutableService.", NSStringFromClass(destinationClass));
    NSAssert3(!CFDictionaryGetValue(self.destinationProtocolToDestinationMap, (__bridge const void *)destinationProtocol), @"Protocol (%@) already registered with another destination (%@), can't be registered with destination (%@).", NSStringFromProtocol(destinationProtocol), NSStringFromClass((Class)CFDictionaryGetValue(self.destinationProtocolToDestinationMap, (__bridge const void *)destinationProtocol)), NSStringFromClass(destinationClass));
    NSAssert3(!CFDictionaryGetValue(self.destinationProtocolToFactoryMap, (__bridge const void *)destinationProtocol), @"Protocol (%@) already registered with a factory or block (%p), can't be registered with destination (%@).", NSStringFromProtocol(destinationProtocol), CFDictionaryGetValue(self.destinationProtocolToFactoryMap, (__bridge const void *)destinationProtocol), NSStringFromClass(destinationClass));
    NSAssert3(!self.destinationToExclusiveRouterMap ||
              (self.destinationToExclusiveRouterMap && !CFDictionaryGetValue(self.destinationToExclusiveRouterMap, (__bridge const void *)(destinationClass))), @"There is a registered exclusive router (%@), can't register destination protocol (%@) for this destinationClass (%@).",CFDictionaryGetValue(self.destinationToExclusiveRouterMap, (__bridge const void *)(destinationClass)), NSStringFromProtocol(destinationProtocol), destinationClass);
    CFSetAddValue(_factoryBlocks, CFBridgingRetain(block));
    CFDictionaryAddValue(self.destinationProtocolToFactoryMap, (__bridge const void *)destinationProtocol, (void *)block);
    CFDictionaryAddValue(self.destinationToDefaultFactoryMap, (__bridge const void *)destinationClass, (void *)block);
    CFDictionaryAddValue(self.destinationProtocolToDestinationMap, (__bridge const void *)destinationProtocol, (__bridge const void *)destinationClass);
}

+ (void)registerModuleProtocol:(Protocol *)configProtocol forMakingDestination:(Class)destinationClass factoryBlock:(ZIKPerformRouteConfiguration<ZIKConfigurationMakeable> *(^ _Nonnull)(void))block {
    NSCParameterAssert(block);
#if DEBUG
    ZIKPerformRouteConfiguration<ZIKConfigurationMakeable> *config = block();
    NSAssert([config conformsToProtocol:configProtocol], @"configuration class (%@) should conforms to registering protocol (%@)", NSStringFromClass([config class]), NSStringFromProtocol(configProtocol));
    [self validateMakeableConfiguration:config];
#endif
    NSAssert([self isDestinationClassRoutable:destinationClass], @"destination class (%@) should conforms to ZIKRoutableView or ZIKRoutableService.", NSStringFromClass(destinationClass));
    NSAssert3(!CFDictionaryGetValue(self.destinationToDefaultConfigFactoryMap, (__bridge const void *)configProtocol), @"Protocol (%@) already registered with a factory or block (%p), can't be registered with destination (%@).", NSStringFromProtocol(configProtocol), CFDictionaryGetValue(self.destinationToDefaultConfigFactoryMap, (__bridge const void *)configProtocol), NSStringFromClass(destinationClass));
    NSAssert3(!self.destinationToExclusiveRouterMap ||
              (self.destinationToExclusiveRouterMap && !CFDictionaryGetValue(self.destinationToExclusiveRouterMap, (__bridge const void *)(destinationClass))), @"There is a registered exclusive router (%@), can't register module config protocol (%@) for this destinationClass (%@).",CFDictionaryGetValue(self.destinationToExclusiveRouterMap, (__bridge const void *)(destinationClass)), NSStringFromProtocol(configProtocol), destinationClass);
    CFSetAddValue(_factoryBlocks, CFBridgingRetain(block));
    CFDictionaryAddValue(self.moduleConfigProtocolToFactoryMap, (__bridge const void *)configProtocol, (void *)block);
    CFDictionaryAddValue(self.destinationToDefaultConfigFactoryMap, (__bridge const void *)destinationClass, (void *)block);
    CFDictionaryAddValue(self.moduleConfigProtocolToDestinationMap, (__bridge const void *)configProtocol, (__bridge const void *)destinationClass);
}

+ (void)registerIdentifier:(NSString *)identifier forMakingDestination:(Class)destinationClass factoryBlock:(id _Nullable(^ _Nonnull)(ZIKPerformRouteConfiguration * _Nonnull))block {
    NSParameterAssert(identifier);
    NSParameterAssert(block);
    NSAssert([self isDestinationClassRoutable:destinationClass], @"destination class (%@) should conforms to ZIKRoutableView or ZIKRoutableService.", NSStringFromClass(destinationClass));
    NSAssert3(!CFDictionaryGetValue(self.identifierToRouterMap, (CFStringRef)identifier)
              , @"Identifier (%@) already registered with another router (%@), can't register with destination class (%@).",identifier, CFDictionaryGetValue(self.identifierToRouterMap, (CFStringRef)identifier), NSStringFromClass(destinationClass));
    NSAssert4(!CFDictionaryGetValue(self.identifierToFactoryMap, (CFStringRef)identifier), @"Identifier (%@) already registered with a factory or block (%p) for destination (%@), can't be registered with destination (%@).", identifier, CFDictionaryGetValue(self.identifierToFactoryMap, (CFStringRef)identifier), NSStringFromClass(CFDictionaryGetValue(self.identifierToDestinationMap, (CFStringRef)identifier)), NSStringFromClass(destinationClass));
    NSAssert4(!CFDictionaryGetValue(self.identifierToConfigFactoryMap, (CFStringRef)identifier), @"Identifier (%@) already registered with a config factory or block (%p) for destination (%@), can't be registered with destination (%@).", identifier, CFDictionaryGetValue(self.identifierToConfigFactoryMap, (CFStringRef)identifier), NSStringFromClass(CFDictionaryGetValue(self.identifierToDestinationMap, (CFStringRef)identifier)), NSStringFromClass(destinationClass));
    NSAssert3(!self.destinationToExclusiveRouterMap ||
              (self.destinationToExclusiveRouterMap && !CFDictionaryGetValue(self.destinationToExclusiveRouterMap, (__bridge const void *)(destinationClass))), @"There is a registered exclusive router (%@), can't register identifier (%@) for this destinationClass (%@).",CFDictionaryGetValue(self.destinationToExclusiveRouterMap, (__bridge const void *)(destinationClass)), identifier, destinationClass);
    CFSetAddValue(_factoryBlocks, CFBridgingRetain(block));
    CFDictionaryAddValue(self.identifierToFactoryMap, (CFStringRef)identifier, (__bridge const void *)block);
    CFDictionaryAddValue(self.destinationToDefaultFactoryMap, (__bridge const void *)destinationClass, (void *)block);
    CFDictionaryAddValue(self.identifierToDestinationMap, (CFStringRef)identifier, (__bridge const void *)destinationClass);
}

+ (void)registerIdentifier:(NSString *)identifier forMakingDestination:(Class)destinationClass configFactoryBlock:(ZIKPerformRouteConfiguration<ZIKConfigurationMakeable> *(^ _Nonnull)(void))block {
    NSParameterAssert(identifier);
    NSParameterAssert(block);
#if DEBUG
    ZIKPerformRouteConfiguration<ZIKConfigurationMakeable> *config = block();
    [self validateMakeableConfiguration:config];
#endif
    NSAssert([self isDestinationClassRoutable:destinationClass], @"destination class (%@) should conforms to ZIKRoutableView or ZIKRoutableService.", NSStringFromClass(destinationClass));
    NSAssert3(!CFDictionaryGetValue(self.identifierToRouterMap, (CFStringRef)identifier)
              , @"Identifier (%@) already registered with another router (%@), can't register with destination class (%@).",identifier, CFDictionaryGetValue(self.identifierToRouterMap, (CFStringRef)identifier), NSStringFromClass(destinationClass));
    NSAssert4(!CFDictionaryGetValue(self.identifierToFactoryMap, (CFStringRef)identifier), @"Identifier (%@) already registered with a factory or block (%p) for destination (%@), can't be registered with destination (%@).", identifier, CFDictionaryGetValue(self.identifierToFactoryMap, (CFStringRef)identifier), NSStringFromClass(CFDictionaryGetValue(self.identifierToDestinationMap, (CFStringRef)identifier)), NSStringFromClass(destinationClass));
    NSAssert4(!CFDictionaryGetValue(self.identifierToConfigFactoryMap, (CFStringRef)identifier), @"Identifier (%@) already registered with a config factory or block (%p) for destination (%@), can't be registered with destination (%@).", identifier, CFDictionaryGetValue(self.identifierToConfigFactoryMap, (CFStringRef)identifier), NSStringFromClass(CFDictionaryGetValue(self.identifierToDestinationMap, (CFStringRef)identifier)), NSStringFromClass(destinationClass));
    NSAssert3(!self.destinationToExclusiveRouterMap ||
              (self.destinationToExclusiveRouterMap && !CFDictionaryGetValue(self.destinationToExclusiveRouterMap, (__bridge const void *)(destinationClass))), @"There is a registered exclusive router (%@), can't register identifier (%@) for this destinationClass (%@).",CFDictionaryGetValue(self.destinationToExclusiveRouterMap, (__bridge const void *)(destinationClass)), identifier, destinationClass);
    CFSetAddValue(_factoryBlocks, CFBridgingRetain(block));
    CFDictionaryAddValue(self.identifierToConfigFactoryMap, (CFStringRef)identifier, (__bridge const void *)block);
    CFDictionaryAddValue(self.destinationToDefaultConfigFactoryMap, (__bridge const void *)destinationClass, (void *)block);
    CFDictionaryAddValue(self.identifierToDestinationMap, (CFStringRef)identifier, (__bridge const void *)destinationClass);
}

+ (void)registerDestinationProtocol:(Protocol *)destinationProtocol forMakingDestination:(Class)destinationClass factoryFunction:(id _Nullable(*)(ZIKPerformRouteConfiguration * _Nonnull))function {
    NSParameterAssert(function);
    NSAssert([destinationClass conformsToProtocol:destinationProtocol], @"destination class (%@) should conforms to registering protocol (%@)", NSStringFromClass(destinationClass), NSStringFromProtocol(destinationProtocol));
    NSAssert([self isDestinationClassRoutable:destinationClass], @"destination class (%@) should conforms to ZIKRoutableView or ZIKRoutableService.", NSStringFromClass(destinationClass));
    NSAssert3(!CFDictionaryGetValue(self.destinationProtocolToDestinationMap, (__bridge const void *)destinationProtocol), @"Protocol (%@) already registered with another destination (%@), can't be registered with destination (%@).", NSStringFromProtocol(destinationProtocol), NSStringFromClass((Class)CFDictionaryGetValue(self.destinationProtocolToDestinationMap, (__bridge const void *)destinationProtocol)), NSStringFromClass(destinationClass));
    NSAssert3(!self.destinationToExclusiveRouterMap ||
              (self.destinationToExclusiveRouterMap && !CFDictionaryGetValue(self.destinationToExclusiveRouterMap, (__bridge const void *)(destinationClass))), @"There is a registered exclusive router (%@), can't register destination protocol (%@) for this destinationClass (%@).",CFDictionaryGetValue(self.destinationToExclusiveRouterMap, (__bridge const void *)(destinationClass)), NSStringFromProtocol(destinationProtocol), destinationClass);
#if DEBUG
    NSAssert3(!CFDictionaryGetValue(self.destinationProtocolToFactoryMap, (__bridge const void *)destinationProtocol), @"Protocol (%@) already registered with a factory or block (%p), can't be registered with function (%@).", NSStringFromProtocol(destinationProtocol), CFDictionaryGetValue(self.destinationProtocolToFactoryMap, (__bridge const void *)destinationProtocol), [ZIKImageSymbol symbolNameForAddress:function]);
#endif
    CFDictionaryAddValue(self.destinationProtocolToFactoryMap, (__bridge const void *)destinationProtocol, (void *)function);
    CFDictionaryAddValue(self.destinationToDefaultFactoryMap, (__bridge const void *)destinationClass, (void *)function);
    CFDictionaryAddValue(self.destinationProtocolToDestinationMap, (__bridge const void *)destinationProtocol, (__bridge const void *)destinationClass);
}

+ (void)registerModuleProtocol:(Protocol *)configProtocol forMakingDestination:(Class)destinationClass factoryFunction:(ZIKPerformRouteConfiguration<ZIKConfigurationMakeable> *_Nonnull(* _Nonnull)(void))function {
    NSParameterAssert(function);
#if DEBUG
    ZIKPerformRouteConfiguration<ZIKConfigurationMakeable> *config = function();
    NSAssert([config conformsToProtocol:configProtocol], @"configuration class (%@) should conforms to registering protocol (%@)", NSStringFromClass([config class]), NSStringFromProtocol(configProtocol));
    [self validateMakeableConfiguration:config];
#endif
    NSAssert([self isDestinationClassRoutable:destinationClass], @"destination class (%@) should conforms to ZIKRoutableView or ZIKRoutableService.", NSStringFromClass(destinationClass));
    NSAssert3(!self.destinationToExclusiveRouterMap ||
              (self.destinationToExclusiveRouterMap && !CFDictionaryGetValue(self.destinationToExclusiveRouterMap, (__bridge const void *)(destinationClass))), @"There is a registered exclusive router (%@), can't register destination protocol (%@) for this destinationClass (%@).",CFDictionaryGetValue(self.destinationToExclusiveRouterMap, (__bridge const void *)(destinationClass)), NSStringFromProtocol(configProtocol), destinationClass);
#if DEBUG
    NSAssert3(!CFDictionaryGetValue(self.moduleConfigProtocolToFactoryMap, (__bridge const void *)configProtocol), @"Protocol (%@) already registered with a factory or block (%p), can't be registered with function (%@).", NSStringFromProtocol(configProtocol), CFDictionaryGetValue(self.moduleConfigProtocolToFactoryMap, (__bridge const void *)configProtocol), [ZIKImageSymbol symbolNameForAddress:function]);
#endif
    CFDictionaryAddValue(self.moduleConfigProtocolToFactoryMap, (__bridge const void *)configProtocol, (void *)function);
    CFDictionaryAddValue(self.destinationToDefaultConfigFactoryMap, (__bridge const void *)destinationClass, (void *)function);
    CFDictionaryAddValue(self.moduleConfigProtocolToDestinationMap, (__bridge const void *)configProtocol, (__bridge const void *)destinationClass);
}

+ (void)registerIdentifier:(NSString *)identifier forMakingDestination:(Class)destinationClass factoryFunction:(id _Nullable(*)(ZIKPerformRouteConfiguration * _Nonnull))function {
    NSParameterAssert(identifier);
    NSParameterAssert(function);
    NSAssert([self isDestinationClassRoutable:destinationClass], @"destination class (%@) should conforms to ZIKRoutableView or ZIKRoutableService.", NSStringFromClass(destinationClass));
    NSAssert3(!CFDictionaryGetValue(self.identifierToRouterMap, (CFStringRef)identifier)
              , @"Identifier (%@) already registered with another router (%@), can't register with destination class (%@).",identifier, CFDictionaryGetValue(self.identifierToRouterMap, (CFStringRef)identifier), NSStringFromClass(destinationClass));
    NSAssert3(!self.destinationToExclusiveRouterMap ||
              (self.destinationToExclusiveRouterMap && CFDictionaryGetValue(self.destinationToExclusiveRouterMap, (__bridge const void *)(destinationClass))), @"There is a registered exclusive router (%@), can't register identifier (%@) for this destinationClass (%@).",CFDictionaryGetValue(self.destinationToExclusiveRouterMap, (__bridge const void *)(destinationClass)), identifier, destinationClass);
#if DEBUG
    NSAssert4(!CFDictionaryGetValue(self.identifierToFactoryMap, (CFStringRef)identifier), @"Identifier (%@) already registered with another factory function (%@) for destination (%@), can't be registered with function (%@).", identifier, CFDictionaryGetValue(self.identifierToFactoryMap, (__bridge CFStringRef)identifier), NSStringFromClass(CFDictionaryGetValue(self.identifierToDestinationMap, (CFStringRef)identifier)), [ZIKImageSymbol symbolNameForAddress:function]);
    NSAssert4(!CFDictionaryGetValue(self.identifierToConfigFactoryMap, (CFStringRef)identifier), @"Identifier (%@) already registered with another config factory function (%@) for destination (%@), can't be registered with function (%@).", identifier, CFDictionaryGetValue(self.identifierToConfigFactoryMap, (__bridge CFStringRef)identifier), NSStringFromClass(CFDictionaryGetValue(self.identifierToDestinationMap, (CFStringRef)identifier)), [ZIKImageSymbol symbolNameForAddress:function]);
#endif
    CFDictionaryAddValue(self.identifierToFactoryMap, (CFStringRef)identifier, (void *)function);
    CFDictionaryAddValue(self.destinationToDefaultFactoryMap, (__bridge const void *)destinationClass, (void *)function);
    CFDictionaryAddValue(self.identifierToDestinationMap, (CFStringRef)identifier, (__bridge const void *)destinationClass);
}

+ (void)registerIdentifier:(NSString *)identifier forMakingDestination:(Class)destinationClass configFactoryFunction:(ZIKPerformRouteConfiguration<ZIKConfigurationMakeable> *_Nonnull(* _Nonnull)(void))function {
    NSParameterAssert(identifier);
    NSParameterAssert(function);
#if DEBUG
    ZIKPerformRouteConfiguration<ZIKConfigurationMakeable> *config = function();
    [self validateMakeableConfiguration:config];
#endif
    NSAssert([self isDestinationClassRoutable:destinationClass], @"destination class (%@) should conforms to ZIKRoutableView or ZIKRoutableService.", NSStringFromClass(destinationClass));
    NSAssert3(!CFDictionaryGetValue(self.identifierToRouterMap, (CFStringRef)identifier)
              , @"Identifier (%@) already registered with another router (%@), can't register with destination class (%@).",identifier, CFDictionaryGetValue(self.identifierToRouterMap, (CFStringRef)identifier), NSStringFromClass(destinationClass));
    NSAssert3(!self.destinationToExclusiveRouterMap ||
              (self.destinationToExclusiveRouterMap && CFDictionaryGetValue(self.destinationToExclusiveRouterMap, (__bridge const void *)(destinationClass))), @"There is a registered exclusive router (%@), can't register identifier (%@) for this destinationClass (%@).",CFDictionaryGetValue(self.destinationToExclusiveRouterMap, (__bridge const void *)(destinationClass)), identifier, destinationClass);
#if DEBUG
    NSAssert4(!CFDictionaryGetValue(self.identifierToFactoryMap, (CFStringRef)identifier), @"Identifier (%@) already registered with another factory function (%@) for destination (%@), can't be registered with function (%@).", identifier, CFDictionaryGetValue(self.identifierToFactoryMap, (__bridge CFStringRef)identifier), NSStringFromClass(CFDictionaryGetValue(self.identifierToDestinationMap, (CFStringRef)identifier)), [ZIKImageSymbol symbolNameForAddress:function]);
    NSAssert4(!CFDictionaryGetValue(self.identifierToConfigFactoryMap, (CFStringRef)identifier), @"Identifier (%@) already registered with another config factory function (%@) for destination (%@), can't be registered with function (%@).", identifier, CFDictionaryGetValue(self.identifierToConfigFactoryMap, (__bridge CFStringRef)identifier), NSStringFromClass(CFDictionaryGetValue(self.identifierToDestinationMap, (CFStringRef)identifier)), [ZIKImageSymbol symbolNameForAddress:function]);
#endif
    CFDictionaryAddValue(self.identifierToConfigFactoryMap, (CFStringRef)identifier, (void *)function);
    CFDictionaryAddValue(self.destinationToDefaultConfigFactoryMap, (__bridge const void *)destinationClass, (void *)function);
    CFDictionaryAddValue(self.identifierToDestinationMap, (CFStringRef)identifier, (__bridge const void *)destinationClass);
}

+ (void)registerDestination:(Class)destinationClass router:(Class)routerClass {
    NSParameterAssert([routerClass isSubclassOfClass:[ZIKRouter class]]);
    _registerDestinationClassWithRoute(destinationClass, routerClass, self);
}

+ (void)registerExclusiveDestination:(Class)destinationClass router:(Class)routerClass {
    NSParameterAssert([routerClass isSubclassOfClass:[ZIKRouter class]]);
    _registerExclusiveDestinationClassWithRoute(destinationClass, routerClass, self);
}

+ (void)registerDestinationProtocol:(Protocol *)destinationProtocol router:(Class)routerClass {
    NSParameterAssert([routerClass isSubclassOfClass:[ZIKRouter class]]);
    _registerDestinationProtocolWithRoute(destinationProtocol, routerClass, self);
}

+ (void)registerModuleProtocol:(Protocol *)configProtocol router:(Class)routerClass {
    NSParameterAssert([routerClass isSubclassOfClass:[ZIKRouter class]]);
    _registerModuleProtocolWithRoute(configProtocol, routerClass, self);
}

+ (void)registerIdentifier:(NSString *)identifier router:(Class)routerClass {
    NSParameterAssert([routerClass isSubclassOfClass:[ZIKRouter class]]);
    _registerIdentifierWithRoute(identifier, routerClass, self);
}

+ (void)registerDestination:(Class)destinationClass route:(ZIKRoute *)route {
    NSParameterAssert([route isKindOfClass:[ZIKRoute class]]);
    _registerDestinationClassWithRoute(destinationClass, route, self);
}

+ (void)registerExclusiveDestination:(Class)destinationClass route:(ZIKRoute *)route {
    NSParameterAssert([route isKindOfClass:[ZIKRoute class]]);
    _registerExclusiveDestinationClassWithRoute(destinationClass, route, self);
}

+ (void)registerDestinationProtocol:(Protocol *)destinationProtocol route:(ZIKRoute *)route {
    NSParameterAssert([route isKindOfClass:[ZIKRoute class]]);
    _registerDestinationProtocolWithRoute(destinationProtocol, route, self);
}

+ (void)registerModuleProtocol:(Protocol *)configProtocol route:(ZIKRoute *)route {
    NSParameterAssert([route isKindOfClass:[ZIKRoute class]]);
    _registerModuleProtocolWithRoute(configProtocol, route, self);
}

+ (void)registerIdentifier:(NSString *)identifier route:(ZIKRoute *)route {
    NSParameterAssert([route isKindOfClass:[ZIKRoute class]]);
    _registerIdentifierWithRoute(identifier, route, self);
}

+ (void)registerDestinationAdapter:(Protocol *)adapterProtocol forAdaptee:(Protocol *)adapteeProtocol {
    NSAssert2(CFDictionaryGetValue(self.destinationProtocolToRouterMap, (__bridge const void *)(adapterProtocol)) == nil, @"Adapter (%@) already register with router (%@)", NSStringFromProtocol(adapterProtocol), CFDictionaryGetValue(self.destinationProtocolToRouterMap, (__bridge const void *)(adapterProtocol)));
    NSAssert3(CFDictionaryGetValue(self.adapterToAdapteeMap, (__bridge const void *)(adapterProtocol)) == nil, @"Adapter (%@) can't register adaptee (%@),  already register another adaptee (%@)", NSStringFromProtocol(adapterProtocol), NSStringFromProtocol(adapteeProtocol), CFDictionaryGetValue(self.adapterToAdapteeMap, (__bridge const void *)(adapterProtocol)));
    CFDictionarySetValue(self.adapterToAdapteeMap, (__bridge const void *)(adapterProtocol), (__bridge const void *)(adapteeProtocol));
}

+ (void)registerModuleAdapter:(Protocol *)adapterProtocol forAdaptee:(Protocol *)adapteeProtocol {
    NSAssert2(CFDictionaryGetValue(self.moduleConfigProtocolToRouterMap, (__bridge const void *)(adapterProtocol)) == nil, @"Adapter (%@) already register with router (%@)", NSStringFromProtocol(adapterProtocol), CFDictionaryGetValue(self.moduleConfigProtocolToRouterMap, (__bridge const void *)(adapterProtocol)));
    NSAssert3(CFDictionaryGetValue(self.adapterToAdapteeMap, (__bridge const void *)(adapterProtocol)) == nil, @"Adapter (%@) can't register adaptee (%@),  already register another adaptee (%@)", NSStringFromProtocol(adapterProtocol), NSStringFromProtocol(adapteeProtocol), CFDictionaryGetValue(self.adapterToAdapteeMap, (__bridge const void *)(adapterProtocol)));
    CFDictionarySetValue(self.adapterToAdapteeMap, (__bridge const void *)(adapterProtocol), (__bridge const void *)(adapteeProtocol));
}

#pragma mark Manually Register

+ (void)notifyRegistrationFinished {
    NSAssert(self.autoRegister == NO, @"Only use -notifyRegistrationFinished for manually registration.");
    if (_registrationFinished) {
        NSAssert(NO, @"Registration is already finished.");
        return;
    }
    self.registrationFinished = YES;
    
    NSSet *registries = [[self registries] copy];
    for (Class registry in registries) {
        [registry didFinishRegistration];
    }
}

#pragma mark Check

+ (BOOL)validateDestinationConformance:(Class)destinationClass forRouter:(ZIKRouter *)router protocol:(Protocol **)protocol {
#if ZIKROUTER_CHECK
    id routeKey = [self routeKeyForRouter:router];
    if (routeKey == nil) {
        return NO;
    }
    CFMutableSetRef destinationProtocols = (CFMutableSetRef)CFDictionaryGetValue(self._check_routerToDestinationProtocolsMap, (__bridge const void *)(routeKey));
    if (destinationProtocols != NULL) {
        for (Protocol *destinationProtocol in (__bridge NSSet*)destinationProtocols) {
            if (![destinationClass conformsToProtocol:destinationProtocol]) {
                *protocol = destinationProtocol;
                return NO;
            }
        }
    }
#endif
    return YES;
}

+ (nullable Class)validateDestinationsForRoute:(id)route handler:(BOOL(^)(Class destinationClass))handler {
#if ZIKROUTER_CHECK
    NSParameterAssert([self _routerTypeForObject:route]);
    CFMutableSetRef destinationClasses = (CFMutableSetRef)CFDictionaryGetValue(self._check_routerToDestinationsMap, (__bridge const void *)(route));
    __block Class badClass = nil;
    [(__bridge NSSet *)(destinationClasses) enumerateObjectsUsingBlock:^(Class  _Nonnull destinationClass, BOOL * _Nonnull stop) {
        if (handler) {
            if (!handler(destinationClass)) {
                badClass = destinationClass;
                *stop = YES;
            }
            ;
        }
    }];
    return badClass;
#else
    return nil;
#endif
}

+ (void)validateMakeableConfiguration:(ZIKPerformRouteConfiguration<ZIKConfigurationMakeable> *)config {
    NSAssert1([config conformsToProtocol:@protocol(ZIKConfigurationMakeable)], @"configuration class (%@) should conforms to ZIKConfigurationMakeable when registering as factory.", config);
#if DEBUG
    NSAssert1(config.makeDestination || [config valueForKey:@"_makeDestinationWith"] || [config valueForKey:@"_constructDestination"] || [[NSStringFromClass([config class]) demangledAsSwift] rangeOfString:@"."].length != 0, @"configuration (%@) must has makeDestination block or constructDestination block when registering as factory.", config);
#endif
}

#pragma mark Override

+ (CFMutableDictionaryRef)destinationProtocolToRouterMap {
    NSAssert(NO, @"%@ must override %@",self,NSStringFromSelector(_cmd));
    return nil;
}
+ (CFMutableDictionaryRef)moduleConfigProtocolToRouterMap {
    NSAssert(NO, @"%@ must override %@",self,NSStringFromSelector(_cmd));
    return nil;
}
+ (CFMutableDictionaryRef)destinationToRoutersMap {
    NSAssert(NO, @"%@ must override %@",self,NSStringFromSelector(_cmd));
    return nil;
}
+ (CFMutableDictionaryRef)destinationToDefaultRouterMap {
    NSAssert(NO, @"%@ must override %@",self,NSStringFromSelector(_cmd));
    return nil;
}
+ (CFMutableDictionaryRef)destinationToExclusiveRouterMap {
    NSAssert(NO, @"%@ must override %@",self,NSStringFromSelector(_cmd));
    return nil;
}
+ (CFMutableDictionaryRef)identifierToRouterMap {
    NSAssert(NO, @"%@ must override %@",self,NSStringFromSelector(_cmd));
    return nil;
}
+ (CFMutableDictionaryRef)adapterToAdapteeMap {
    NSAssert(NO, @"%@ must override %@",self,NSStringFromSelector(_cmd));
    return nil;
}
+ (CFMutableDictionaryRef)destinationProtocolToDestinationMap {
    NSAssert(NO, @"%@ must override %@",self,NSStringFromSelector(_cmd));
    return nil;
}
+ (CFMutableDictionaryRef)moduleConfigProtocolToDestinationMap {
    NSAssert(NO, @"%@ must override %@",self,NSStringFromSelector(_cmd));
    return nil;
}
+ (CFMutableDictionaryRef)identifierToDestinationMap {
    NSAssert(NO, @"%@ must override %@",self,NSStringFromSelector(_cmd));
    return nil;
}
+ (CFMutableSetRef)runtimeFactoryDestinationClasses {
    NSAssert(NO, @"%@ must override %@",self,NSStringFromSelector(_cmd));
    return nil;
}
+ (CFMutableDictionaryRef)destinationProtocolToFactoryMap {
    NSAssert(NO, @"%@ must override %@",self,NSStringFromSelector(_cmd));
    return nil;
}
+ (CFMutableDictionaryRef)identifierToFactoryMap {
    NSAssert(NO, @"%@ must override %@",self,NSStringFromSelector(_cmd));
    return nil;
}
+ (CFMutableDictionaryRef)destinationToDefaultFactoryMap {
    NSAssert(NO, @"%@ must override %@",self,NSStringFromSelector(_cmd));
    return nil;
}
+ (CFMutableDictionaryRef)moduleConfigProtocolToFactoryMap {
    NSAssert(NO, @"%@ must override %@",self,NSStringFromSelector(_cmd));
    return nil;
}
+ (CFMutableDictionaryRef)identifierToConfigFactoryMap {
    NSAssert(NO, @"%@ must override %@",self,NSStringFromSelector(_cmd));
    return nil;
}
+ (CFMutableDictionaryRef)destinationToDefaultConfigFactoryMap {
    NSAssert(NO, @"%@ must override %@",self,NSStringFromSelector(_cmd));
    return nil;
}
+ (CFMutableDictionaryRef)_check_routerToDestinationsMap {
    NSAssert(NO, @"%@ must override %@",self,NSStringFromSelector(_cmd));
    return nil;
}
+ (CFMutableDictionaryRef)_check_routerToDestinationProtocolsMap {
    NSAssert(NO, @"%@ must override %@",self,NSStringFromSelector(_cmd));
    return nil;
}

+ (void)willEnumerateClasses {
    
}

+ (void)handleEnumerateRouterClass:(Class)aClass {
    
}

+ (void)didFinishRegistration {
    
}

+ (BOOL)isRegisterableRouterClass:(Class)aClass {
    NSAssert(NO, @"%@ must override %@",self,NSStringFromSelector(_cmd));
    return NO;
}

+ (BOOL)isDestinationClassRoutable:(Class)aClass {
    NSAssert(NO, @"%@ must override %@",self,NSStringFromSelector(_cmd));
    return NO;
}

@end
