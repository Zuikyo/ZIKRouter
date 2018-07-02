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
#if ZIKROUTER_CHECK
static CFMutableDictionaryRef _check_routerToDestinationsMap;
static CFMutableDictionaryRef _check_routerToDestinationProtocolsMap;
static NSMutableArray<Class> *_routableDestinations;
static NSMutableArray<Class> *_routerClasses;
#endif

@implementation ZIKServiceRouteRegistry

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

+ (NSLock *)lock {
    static NSLock *_lock;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _lock = [[NSLock alloc] init];
    });
    return _lock;
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

+ (void)willEnumerateClasses {
#if ZIKROUTER_CHECK
    _routableDestinations = [NSMutableArray array];
    _routerClasses = [NSMutableArray array];
#endif
}

+ (void)handleEnumerateClasses:(Class)class {
#if ZIKROUTER_CHECK
    if (class_conformsToProtocol(class, @protocol(ZIKRoutableService))) {
        [_routableDestinations addObject:class];
    }
#endif
    static Class ZIKServiceRouterClass;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ZIKServiceRouterClass = [ZIKServiceRouter class];
    });
    if (ZIKRouter_classIsSubclassOfClass(class, ZIKServiceRouterClass)) {
        NSCAssert1(ZIKRouter_classSelfImplementingMethod(class, @selector(registerRoutableDestination), true) || [class isAbstractRouter], @"Router(%@) must override +registerRoutableDestination to register destination.",class);
        NSCAssert1(ZIKRouter_classSelfImplementingMethod(class, @selector(destinationWithConfiguration:), false) || [class isAbstractRouter] || [class isAdapter], @"Router(%@) must override -destinationWithConfiguration: to return destination.",class);
        [class registerRoutableDestination];
#if ZIKROUTER_CHECK
        CFMutableSetRef services = (CFMutableSetRef)CFDictionaryGetValue(self._check_routerToDestinationsMap, (__bridge const void *)(class));
        NSSet *serviceSet = (__bridge NSSet *)(services);
        NSCAssert2(serviceSet.count > 0 || [class isAbstractRouter] || [class isAdapter], @"This router class(%@) was not resgistered with any service class. Use +registerService: to register service in Router(%@)'s +registerRoutableDestination.",class,class);
        [_routerClasses addObject:class];
#endif
    }
}

+ (void)didFinishEnumerateClasses {
#if ZIKROUTER_CHECK
    [self _checkAllRoutableDestinations];
#endif
}

+ (void)handleEnumerateProtocoles:(Protocol *)protocol {
#if ZIKROUTER_CHECK
    [self _checkProtocol:protocol];
#endif
}

+ (void)didFinishRegistration {
#if ZIKROUTER_CHECK
    if (self.autoRegister == NO) {
        [self _searchAllRoutersAndDestinations];
        [self _checkAllRoutableDestinations];
        [self _checkAllRouters];
        [self _checkAllRoutableProtocols];
        return;
    }
#if ZIK_HAS_UIKIT
    NSNotificationName name = UIApplicationDidFinishLaunchingNotification;
#else
    NSNotificationName name = NSApplicationDidFinishLaunchingNotification;
#endif
    [[NSNotificationCenter defaultCenter] addObserverForName:name object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        [self _checkAllRouters];
    }];
#endif
}

+ (BOOL)isRegisterableRouterClass:(Class)aClass {
    static Class ZIKServiceRouterClass;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ZIKServiceRouterClass = [ZIKServiceRouter class];
    });
    if (ZIKRouter_classIsSubclassOfClass(aClass, ZIKServiceRouterClass)) {
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

#pragma mark Check

#if ZIKROUTER_CHECK

+ (void)_searchAllRoutersAndDestinations {
    _routableDestinations = [NSMutableArray array];
    _routerClasses = [NSMutableArray array];
    ZIKRouter_enumerateClassList(^(__unsafe_unretained Class class) {
        if (class == nil) {
            return;
        }
        if (class_conformsToProtocol(class, @protocol(ZIKRoutableService))) {
            [_routableDestinations addObject:class];
        } else if (ZIKRouter_classIsSubclassOfClass(class, [ZIKServiceRouter class])) {
            CFMutableSetRef services = (CFMutableSetRef)CFDictionaryGetValue(self._check_routerToDestinationsMap, (__bridge const void *)(class));
            NSSet *serviceSet = (__bridge NSSet *)(services);
            NSCAssert2(serviceSet.count > 0 || [class isAbstractRouter] || [class isAdapter], @"This router class(%@) was not resgistered with any service class. Use +registerService: to register service in Router(%@)'s +registerRoutableDestination.",class,class);
            [_routerClasses addObject:class];
        }
    });
}

+ (void)_checkAllRoutableDestinations {
    for (Class destinationClass in _routableDestinations) {
        NSCAssert1(CFDictionaryGetValue(self.destinationToDefaultRouterMap, (__bridge const void *)(destinationClass)) != NULL, @"Routable service (%@) is not registered with any view router.",destinationClass);
    }
}

+ (void)_checkAllRouters {
    for (Class class in _routerClasses) {
        [class _didFinishRegistration];
    }
}

+ (void)_checkAllRoutableProtocols {
    ZIKRouter_enumerateProtocolList(^(Protocol *protocol) {
        if (protocol) {
            [self _checkProtocol:protocol];
        }
    });
}

+ (void)_checkProtocol:(Protocol *)protocol {
    if (protocol_conformsToProtocol(protocol, @protocol(ZIKServiceRoutable)) &&
        protocol != @protocol(ZIKServiceRoutable)) {
        ZIKRouterType *routerType = [self routerToDestination:protocol];
        NSCAssert1(routerType, @"Declared service protocol(%@) is not registered with any router class!",NSStringFromProtocol(protocol));
        id router = routerType.routerClass;
        if (router == nil) {
            router = routerType.route;
        }
        
        CFSetRef servicesRef = CFDictionaryGetValue(self._check_routerToDestinationsMap, (__bridge const void *)(router));
        NSSet *services = (__bridge NSSet *)(servicesRef);
        NSCAssert1(services.count > 0, @"Router(%@) didn't registered with any serviceClass", router);
        for (Class serviceClass in services) {
            NSCAssert3([serviceClass conformsToProtocol:protocol], @"Router(%@)'s serviceClass(%@) should conform to registered protocol(%@)",router, serviceClass, NSStringFromProtocol(protocol));
        }
    } else if (protocol_conformsToProtocol(protocol, @protocol(ZIKServiceModuleRoutable)) &&
               protocol != @protocol(ZIKServiceModuleRoutable)) {
        ZIKRouterType *routerType = [self routerToModule:protocol];
        NSCAssert1(routerType, @"Declared service config protocol(%@) is not registered with any router class!",NSStringFromProtocol(protocol));
        ZIKRouteConfiguration *config = [routerType defaultRouteConfiguration];
        NSCAssert3([config conformsToProtocol:protocol], @"Router(%@)'s default ZIKRouteConfiguration(%@) should conform to registered config protocol(%@)",routerType, [config class], NSStringFromProtocol(protocol));
    }
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
