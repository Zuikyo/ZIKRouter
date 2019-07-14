//
//  ZIKServiceRouteRegistry.m
//  ZIKRouter
//
//  Created by zuik on 2017/11/16.
//  Copyright © 2017 zuik. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "ZIKServiceRouteRegistry.h"
#import "ZIKRouteRegistryInternal.h"
#import "ZIKRouterInternal.h"
#import "ZIKServiceRouterInternal.h"
#import "ZIKBlockServiceRouter.h"
#import "ZIKServiceRouterType.h"
#import "ZIKServiceRoute.h"
#import "ZIKRouterRuntime.h"
#import <objc/runtime.h>
#import "ZIKPlatformCapabilities.h"
#if ZIK_HAS_UIKIT
#import <UIKit/UIKit.h>
#else
#import <AppKit/AppKit.h>
#endif

static CFMutableDictionaryRef _destinationProtocolToRouterMap;
static CFMutableDictionaryRef _moduleConfigProtocolToRouterMap;
static CFMutableDictionaryRef _destinationToRoutersMap;
static CFMutableDictionaryRef _destinationToDefaultRouterMap;
static CFMutableDictionaryRef _destinationToExclusiveRouterMap;
static CFMutableDictionaryRef _identifierToRouterMap;
static CFMutableDictionaryRef _adapterToAdapteeMap;
static CFMutableDictionaryRef _destinationProtocolToDestinationMap;
static CFMutableDictionaryRef _moduleConfigProtocolToDestinationMap;
static CFMutableSetRef        _runtimeFactoryDestinationClasses;
static CFMutableDictionaryRef _identifierToDestinationMap;
static CFMutableDictionaryRef _destinationProtocolToFactoryMap;
static CFMutableDictionaryRef _identifierToFactoryMap;
static CFMutableDictionaryRef _destinationToDefaultFactoryMap;
static CFMutableDictionaryRef _moduleConfigProtocolToFactoryMap;
static CFMutableDictionaryRef _identifierToConfigFactoryMap;
static CFMutableDictionaryRef _destinationToDefaultConfigFactoryMap;
#if ZIKROUTER_CHECK
static CFMutableDictionaryRef _check_routerToDestinationsMap;
static CFMutableDictionaryRef _check_routerToDestinationProtocolsMap;
static NSMutableArray<Class> *_routableDestinations;
static NSMutableArray<Class> *_routerClasses;
#endif

@implementation ZIKServiceRouteRegistry

+ (ZIKRoute *)easyRouteForDestinationClass:(Class)destinationClass factory:(id(^)(ZIKPerformRouteConfiguration * _Nonnull config, __kindof ZIKRouter * _Nonnull router))factory {
    return [[ZIKServiceRoute alloc] initWithMakeDestination:^id _Nullable(ZIKPerformRouteConfiguration * _Nonnull config, __kindof ZIKRouter * _Nonnull router) {
        if (!factory) {
            return nil;
        }
        return factory(config, router);
    }];
}

+ (ZIKRoute *)easyRouteForDestinationClass:(Class)destinationClass configFactory:(ZIKPerformRouteConfiguration<ZIKConfigurationMakeable> *(^)(void))factory {
    return [[ZIKServiceRoute alloc] initWithMakeDestination:^id _Nullable(ZIKPerformRouteConfiguration<ZIKConfigurationMakeable> * _Nonnull config, __kindof ZIKRouter * _Nonnull router) {
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

+ (Class)routerTypeClass {
    return [ZIKServiceRouterType class];
}

+ (nullable id)routeKeyForRouter:(ZIKRouter *)router {
    if ([router isKindOfClass:[ZIKServiceRouter class]] == NO) {
        return nil;
    }
    if ([router isKindOfClass:[ZIKBlockServiceRouter class]]) {
        return [(ZIKBlockServiceRouter *)router route];
    }
    return [router class];
}

+ (CFMutableDictionaryRef)destinationProtocolToDestinationMap {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _destinationProtocolToDestinationMap = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, NULL, NULL);
    });
    return _destinationProtocolToDestinationMap;
}
+ (CFMutableDictionaryRef)moduleConfigProtocolToDestinationMap {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _moduleConfigProtocolToDestinationMap = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, NULL, NULL);
    });
    return _moduleConfigProtocolToDestinationMap;
}
+ (CFMutableSetRef)runtimeFactoryDestinationClasses {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _runtimeFactoryDestinationClasses = CFSetCreateMutable(kCFAllocatorDefault, 0, NULL);
    });
    return _runtimeFactoryDestinationClasses;
}
+ (CFMutableDictionaryRef)destinationProtocolToRouterMap {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _destinationProtocolToRouterMap = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, NULL, NULL);
    });
    return _destinationProtocolToRouterMap;
}
+ (CFMutableDictionaryRef)moduleConfigProtocolToRouterMap {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _moduleConfigProtocolToRouterMap = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, NULL, NULL);
    });
    return _moduleConfigProtocolToRouterMap;
}
+ (CFMutableDictionaryRef)destinationToRoutersMap {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _destinationToRoutersMap = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, NULL, &kCFTypeDictionaryValueCallBacks);
    });
    return _destinationToRoutersMap;
}
+ (CFMutableDictionaryRef)destinationToDefaultRouterMap {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _destinationToDefaultRouterMap = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, NULL, NULL);
    });
    return _destinationToDefaultRouterMap;
}
+ (CFMutableDictionaryRef)destinationToExclusiveRouterMap {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _destinationToExclusiveRouterMap = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, NULL, NULL);
    });
    return _destinationToExclusiveRouterMap;
}
+ (CFMutableDictionaryRef)identifierToRouterMap {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _identifierToRouterMap = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &kCFTypeDictionaryKeyCallBacks, NULL);
    });
    return _identifierToRouterMap;
}
+ (CFMutableDictionaryRef)adapterToAdapteeMap {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _adapterToAdapteeMap = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &kCFTypeDictionaryKeyCallBacks, NULL);
    });
    return _adapterToAdapteeMap;
}
+ (CFMutableDictionaryRef)identifierToDestinationMap {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _identifierToDestinationMap = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &kCFTypeDictionaryKeyCallBacks, NULL);
    });
    return _identifierToDestinationMap;
}
+ (CFMutableDictionaryRef)destinationProtocolToFactoryMap {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _destinationProtocolToFactoryMap = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, NULL, NULL);
    });
    return _destinationProtocolToFactoryMap;
}
+ (CFMutableDictionaryRef)identifierToFactoryMap {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _identifierToFactoryMap = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &kCFTypeDictionaryKeyCallBacks, NULL);
    });
    return _identifierToFactoryMap;
}
+ (CFMutableDictionaryRef)destinationToDefaultFactoryMap {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _destinationToDefaultFactoryMap = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, NULL, NULL);
    });
    return _destinationToDefaultFactoryMap;
}
+ (CFMutableDictionaryRef)moduleConfigProtocolToFactoryMap {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _moduleConfigProtocolToFactoryMap = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, NULL, NULL);
    });
    return _moduleConfigProtocolToFactoryMap;
}
+ (CFMutableDictionaryRef)identifierToConfigFactoryMap {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _identifierToConfigFactoryMap = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &kCFTypeDictionaryKeyCallBacks, NULL);
    });
    return _identifierToConfigFactoryMap;
}
+ (CFMutableDictionaryRef)destinationToDefaultConfigFactoryMap {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _destinationToDefaultConfigFactoryMap = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, NULL, NULL);
    });
    return _destinationToDefaultConfigFactoryMap;
}
+ (CFMutableDictionaryRef)_check_routerToDestinationsMap {
#if ZIKROUTER_CHECK
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _check_routerToDestinationsMap = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, NULL, &kCFTypeDictionaryValueCallBacks);
    });
    return _check_routerToDestinationsMap;
#else
    return NULL;
#endif
}
+ (CFMutableDictionaryRef)_check_routerToDestinationProtocolsMap {
#if ZIKROUTER_CHECK
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _check_routerToDestinationProtocolsMap = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, NULL, &kCFTypeDictionaryValueCallBacks);
    });
    return _check_routerToDestinationProtocolsMap;
#else
    return NULL;
#endif
}

+ (void)handleEnumerateRouterClass:(Class)class {
    static Class ZIKServiceRouterClass;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ZIKServiceRouterClass = [ZIKServiceRouter class];
    });
    if (zix_classIsSubclassOfClass(class, ZIKServiceRouterClass)) {
        [class registerRoutableDestination];
    }
}

+ (void)didFinishRegistration {
#if ZIKROUTER_CHECK
    [self _searchAllRoutersAndDestinations];
    [self _checkAllRouters];
    [self _checkAllRoutableDestinations];    
    [self _checkAllRoutableProtocols];
#endif
}

+ (BOOL)isRegisterableRouterClass:(Class)aClass {
    static Class ZIKServiceRouterClass;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ZIKServiceRouterClass = [ZIKServiceRouter class];
    });
    if (zix_classIsSubclassOfClass(aClass, ZIKServiceRouterClass)) {
        if ([aClass isAbstractRouter]) {
            return NO;
        }
        return YES;
    }
    return NO;
}

+ (BOOL)isDestinationClassRoutable:(Class)aClass {
    while (aClass) {
        if (class_conformsToProtocol(aClass, @protocol(ZIKRoutableService))) {
            return YES;
        }
        aClass = class_getSuperclass(aClass);
    }
    return NO;
}

+ (void)enumerateAllServiceRouters:(void(NS_NOESCAPE ^)(Class _Nullable routerClass, ZIKServiceRoute * _Nullable route))handler {
    static NSSet *cachedAllRouters;
    NSSet *routers;
    if ([self registrationFinished] && cachedAllRouters && cachedAllRouters.count > 0) {
        routers = cachedAllRouters;
    } else {
        NSMutableSet *allRouters = [NSMutableSet set];
        NSDictionary *destinationToRoutersMap = (__bridge NSDictionary *)self.destinationToRoutersMap;
        [destinationToRoutersMap enumerateKeysAndObjectsUsingBlock:^(Class _Nonnull destinationClass, NSSet * _Nonnull routers, BOOL * _Nonnull stop) {
            [allRouters unionSet:routers];
        }];
        NSDictionary *destinationToExclusiveRouterMap = (__bridge NSDictionary *)self.destinationToExclusiveRouterMap;
        [destinationToExclusiveRouterMap enumerateKeysAndObjectsUsingBlock:^(Class _Nonnull destinationClass, id  _Nonnull router, BOOL * _Nonnull stop) {
            [allRouters addObject:router];
        }];
        cachedAllRouters = allRouters;
        routers = allRouters;
    }
    
    if (handler) {
        [routers enumerateObjectsUsingBlock:^(id  _Nonnull route, BOOL * _Nonnull stop) {
            if ([route class] == route) {
                handler(route, nil);
            } else {
                handler(nil, route);
            }
        }];
    }
}

#pragma mark Check

#if ZIKROUTER_CHECK

+ (void)_searchAllRoutersAndDestinations {
    _routableDestinations = [NSMutableArray array];
    _routerClasses = [NSMutableArray array];
    NSMutableString *errorDescription = [NSMutableString string];
    zix_enumerateClassList(^(__unsafe_unretained Class class) {
        if (class == nil) {
            return;
        }
        if (class_conformsToProtocol(class, @protocol(ZIKRoutableService))) {
            [_routableDestinations addObject:class];
        } else if (zix_classIsSubclassOfClass(class, [ZIKServiceRouter class])) {
            if (!(zix_classSelfImplementingMethod(class, @selector(registerRoutableDestination), true) ||
                  [class isAbstractRouter])) {
                [errorDescription appendFormat:@"\n\n❌Router(%@) must override +registerRoutableDestination to register destination.", class];
            }
            if (!(zix_classSelfImplementingMethod(class, @selector(destinationWithConfiguration:), false) ||
                  [class isAbstractRouter] ||
                  [class isAdapter])) {
                [errorDescription appendFormat:@"\n\n❌Router(%@) must override -destinationWithConfiguration: to return destination.",class];
            }
            CFMutableSetRef services = (CFMutableSetRef)CFDictionaryGetValue(self._check_routerToDestinationsMap, (__bridge const void *)(class));
            NSSet *serviceSet = (__bridge NSSet *)(services);
            if (!(serviceSet.count > 0 || [class isAbstractRouter] || [class isAdapter])) {
                [errorDescription appendFormat:@"\n\n❌Router class(%@) is not resgistered with any service class. Use +registerService: to register service in Router(%@)'s +registerRoutableDestination.", class, class];
            }
            [_routerClasses addObject:class];
        }
    });
    if (errorDescription.length > 0) {
        NSLog(@"\n❌Found router implementation errors:%@", errorDescription);
        NSAssert(NO, errorDescription);
    }
}

+ (void)_checkAllRoutableDestinations {
    NSMutableString *errorDescription = [NSMutableString string];
    for (Class destinationClass in _routableDestinations) {
        if (!(CFDictionaryGetValue(self.destinationToDefaultRouterMap, (__bridge const void *)(destinationClass)) != NULL ||
              CFDictionaryGetValue(self.destinationToExclusiveRouterMap, (__bridge const void *)(destinationClass)) != NULL ||
              [self easyRouteForDestinationClass:destinationClass])) {
            [errorDescription appendFormat:@"\n\n❌Routable service (%@) is not registered with any service router.", destinationClass];
        }
    }
    if (errorDescription.length > 0) {
        NSLog(@"\n❌Found router implementation errors:%@", errorDescription);
        NSAssert(NO, errorDescription);
    }
}

+ (void)_checkAllRouters {
    for (Class class in _routerClasses) {
        [class _didFinishRegistration];
    }
}

+ (void)_checkAllRoutableProtocols {
    NSMutableString *errorDescription = [NSMutableString string];
    zix_enumerateProtocolList(^(Protocol *protocol) {
        if (protocol) {
            NSString *error = [self _checkProtocol:protocol];
            if (error) {
                [errorDescription appendString:error];
            }
        }
    });
    if (errorDescription.length > 0) {
        NSLog(@"\n❌Found router implementation errors:%@", errorDescription);
        NSAssert(NO, errorDescription);
    }
}

+ (NSString *)_checkProtocol:(Protocol *)protocol {
    if (zix_protocolConformsToProtocol(protocol, @protocol(ZIKServiceRoutable)) &&
        protocol != @protocol(ZIKServiceRoutable)) {
        ZIKRouterType *routerType = [self routerToDestination:protocol];
        if (!routerType) {
            return [NSString stringWithFormat:@"\n\n❌Declared service protocol(%@) is not registered with any router class!",NSStringFromProtocol(protocol)];
        }
        id router = routerType.routerClass;
        if (router == nil) {
            router = routerType.route;
        }
        
        CFSetRef servicesRef = CFDictionaryGetValue(self._check_routerToDestinationsMap, (__bridge const void *)(router));
        NSSet *services = (__bridge NSSet *)(servicesRef);
        if (!(services.count > 0 ||
              CFDictionaryGetValue(self.destinationProtocolToDestinationMap, (__bridge const void *)(protocol)) ||
              CFDictionaryGetValue(self.destinationProtocolToFactoryMap, (__bridge const void *)(protocol)))) {
            return [NSString stringWithFormat:@"\n\n❌Router(%@) didn't registered with any serviceClass", router];
        }
        NSMutableString *error = [NSMutableString string];
        for (Class serviceClass in services) {
            if (![serviceClass conformsToProtocol:protocol]) {
                [error appendFormat:@"\n\n❌Router(%@)'s serviceClass(%@) should conform to registered protocol(%@)", router, serviceClass, NSStringFromProtocol(protocol)];
            }
        }
        if (error.length > 0) {
            return error;
        }
    } else if (zix_protocolConformsToProtocol(protocol, @protocol(ZIKServiceModuleRoutable)) &&
               protocol != @protocol(ZIKServiceModuleRoutable)) {
        ZIKRouterType *routerType = [self routerToModule:protocol];
        if (!routerType) {
            return [NSString stringWithFormat:@"\n\n❌Declared service module config protocol(%@) is not registered with any router class!",NSStringFromProtocol(protocol)];
        }
        ZIKRouteConfiguration *config = [routerType defaultRouteConfiguration];
        if (![config conformsToProtocol:protocol]) {
            return [NSString stringWithFormat:@"\n\n❌Router(%@)'s default ZIKRouteConfiguration(%@) should conform to registered config protocol(%@)",routerType, [config class], NSStringFromProtocol(protocol)];
        }
    }
    return nil;
}

#endif

#pragma mark Check Override

#if ZIKROUTER_CHECK

+ (void)registerDestination:(Class)destinationClass router:(Class)routerClass {
    NSParameterAssert([routerClass isSubclassOfClass:[ZIKServiceRouter class]]);
    [super registerDestination:destinationClass router:routerClass];
}

+ (void)registerExclusiveDestination:(Class)destinationClass router:(Class)routerClass {
    NSParameterAssert([routerClass isSubclassOfClass:[ZIKServiceRouter class]]);
    [super registerExclusiveDestination:destinationClass router:routerClass];
}

+ (void)registerDestinationProtocol:(Protocol *)destinationProtocol router:(Class)routerClass {
    NSParameterAssert([routerClass isSubclassOfClass:[ZIKServiceRouter class]]);
    [super registerDestinationProtocol:destinationProtocol router:routerClass];
}

+ (void)registerIdentifier:(NSString *)identifier router:(Class)routerClass {
    NSParameterAssert([routerClass isSubclassOfClass:[ZIKServiceRouter class]]);
    [super registerIdentifier:identifier router:routerClass];
}

+ (void)registerModuleProtocol:(Protocol *)configProtocol router:(Class)routerClass {
    NSParameterAssert([routerClass isSubclassOfClass:[ZIKServiceRouter class]]);
    [super registerModuleProtocol:configProtocol router:routerClass];
}

+ (void)registerDestination:(Class)destinationClass route:(ZIKRoute *)route {
    NSParameterAssert([route isKindOfClass:[ZIKServiceRoute class]]);
    [super registerDestination:destinationClass route:route];
}

+ (void)registerExclusiveDestination:(Class)destinationClass route:(ZIKRoute *)route {
    NSParameterAssert([route isKindOfClass:[ZIKServiceRoute class]]);
    [super registerExclusiveDestination:destinationClass route:route];
}

+ (void)registerDestinationProtocol:(Protocol *)destinationProtocol route:(ZIKRoute *)route {
    NSParameterAssert([route isKindOfClass:[ZIKServiceRoute class]]);
    [super registerDestinationProtocol:destinationProtocol route:route];
}

+ (void)registerModuleProtocol:(Protocol *)configProtocol route:(ZIKRoute *)route {
    NSParameterAssert([route isKindOfClass:[ZIKServiceRoute class]]);
    [super registerModuleProtocol:configProtocol route:route];
}

+ (void)registerIdentifier:(NSString *)identifier route:(ZIKRoute *)route {
    NSParameterAssert([route isKindOfClass:[ZIKServiceRoute class]]);
    [super registerIdentifier:identifier route:route];
}

#endif

@end
