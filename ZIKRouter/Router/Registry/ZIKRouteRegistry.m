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

static NSMutableSet<Class> *_registries;
static BOOL _autoRegister = YES;
static BOOL _registrationFinished = NO;

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
        ZIKRouter_replaceMethodWithMethod([XXApplication class], @selector(setDelegate:),
                                          self, @selector(ZIKRouteRegistry_hook_setDelegate:));
        ZIKRouter_replaceMethodWithMethodType([XXStoryboard class], @selector(storyboardWithName:bundle:), true, self, @selector(ZIKRouteRegistry_hook_storyboardWithName:bundle:), true);
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
    if (canEnumerateClassesInImage()) {
        // Fast enumeration
        enumerateClassesInMainBundleForParentClass([ZIKRouter class], ^(__unsafe_unretained Class  _Nonnull aClass) {
            for (Class registry in registries) {
                [registry handleEnumerateRouterClass:aClass];
            }
        });
    } else {
        // Slow enumeration
        ZIKRouter_enumerateClassList(^(__unsafe_unretained Class class) {
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
    NSParameterAssert([self isDestinationClassRoutable:destinationClass]);
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
            adapter = adaptee;
        } while (route == nil);
    }
    if (route == nil && [self respondsToSelector:@selector(_swiftRouteForDestinationAdapter:)]) {
        route = [self _swiftRouteForDestinationAdapter:destinationProtocol];
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
            adapter = adaptee;
        } while (route == nil);
    }
    if (route == nil && [self respondsToSelector:@selector(_swiftRouteForModuleAdapter:)]) {
        route = [self _swiftRouteForModuleAdapter:configProtocol];
    }
    return [self _routerTypeForObject:route];
}

+ (nullable ZIKRouterType *)routerToIdentifier:(NSString *)identifier {
    if (identifier == nil) {
        return nil;
    }
    id route = CFDictionaryGetValue(self.identifierToRouterMap, (CFStringRef)identifier);
    return [self _routerTypeForObject:route];
}

+ (void)enumerateRoutersForDestinationClass:(Class)destinationClass handler:(void(^)(ZIKRouterType * route))handler {
    NSParameterAssert([self isDestinationClassRoutable:destinationClass]);
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
    NSCParameterAssert(ZIKRouter_classIsSubclassOfClass(registry, [ZIKRouteRegistry class]));
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
    NSCParameterAssert(ZIKRouter_classIsSubclassOfClass(registry, [ZIKRouteRegistry class]));
    NSCParameterAssert([registry isDestinationClassRoutable:destinationClass]);
    NSCAssert2(!CFDictionaryGetValue([registry destinationToExclusiveRouterMap], (__bridge const void *)(destinationClass)), @"There is already a registered exclusive router (%@) for this destinationClass, can't register this router (%@). You can only specific one exclusive router for each destinationClass. Choose the router used as dependency injector.",CFDictionaryGetValue([registry destinationToExclusiveRouterMap], (__bridge const void *)(destinationClass)),routeObject);
    NSCAssert2(!CFDictionaryGetValue([registry destinationToDefaultRouterMap], (__bridge const void *)(destinationClass)), @"destinationClass already registered with another router (%@), check and remove them. You shall only use this exclusive router (%@) for this destinationClass.",CFDictionaryGetValue([registry destinationToDefaultRouterMap], (__bridge const void *)(destinationClass)),routeObject);
    NSCAssert(!CFDictionaryContainsKey([registry destinationToRoutersMap], (__bridge const void *)(destinationClass)) ||
              (CFDictionaryContainsKey([registry destinationToRoutersMap], (__bridge const void *)(destinationClass)) &&
               !CFSetContainsValue(
                                   (CFMutableSetRef)CFDictionaryGetValue([registry destinationToRoutersMap], (__bridge const void *)(destinationClass)),
                                   (__bridge const void *)(routeObject)
                                   ))
              , @"destinationClass already registered with another router, check and remove them. You shall only use the exclusive router for this destinationClass.");
    
    CFDictionarySetValue([registry destinationToExclusiveRouterMap], (__bridge const void *)(destinationClass), (__bridge const void *)(routeObject));
    
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
    NSCParameterAssert(ZIKRouter_classIsSubclassOfClass(registry, [ZIKRouteRegistry class]));
    NSCAssert3(!CFDictionaryGetValue([registry destinationProtocolToRouterMap], (__bridge const void *)(destinationProtocol)) ||
               (Class)CFDictionaryGetValue([registry destinationProtocolToRouterMap], (__bridge const void *)(destinationProtocol)) == routeObject
               , @"Destination protocol (%@) already registered with another router (%@), can't register with this router (%@). Same destination protocol should only be used by one routeObject.",NSStringFromProtocol(destinationProtocol),CFDictionaryGetValue([registry destinationProtocolToRouterMap], (__bridge const void *)(destinationProtocol)),routeObject);
    
    CFDictionarySetValue([registry destinationProtocolToRouterMap], (__bridge const void *)(destinationProtocol), (__bridge const void *)(routeObject));
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
    NSCParameterAssert(ZIKRouter_classIsSubclassOfClass(registry, [ZIKRouteRegistry class]));
    NSCAssert3(!CFDictionaryGetValue([registry moduleConfigProtocolToRouterMap], (__bridge const void *)(configProtocol)) ||
               (Class)CFDictionaryGetValue([registry moduleConfigProtocolToRouterMap], (__bridge const void *)(configProtocol)) == routeObject
               , @"Module config protocol (%@) already registered with another router (%@), can't register with this router (%@). Same configProtocol should only be used by one routeObject.",NSStringFromProtocol(configProtocol),CFDictionaryGetValue([registry moduleConfigProtocolToRouterMap], (__bridge const void *)(configProtocol)),routeObject);
    
    CFDictionarySetValue([registry moduleConfigProtocolToRouterMap], (__bridge const void *)(configProtocol), (__bridge const void *)(routeObject));
}

static __attribute__((always_inline)) void _registerIdentifierWithRoute(NSString *identifier, id routeObject, Class registry) {
    NSCParameterAssert(ZIKRouter_classIsSubclassOfClass(registry, [ZIKRouteRegistry class]));
    NSCParameterAssert(identifier.length > 0);
    if (identifier == nil) {
        return;
    }
    NSCAssert3(!CFDictionaryGetValue([registry identifierToRouterMap], (CFStringRef)identifier) ||
               (Class)CFDictionaryGetValue([registry identifierToRouterMap], (CFStringRef)identifier) == routeObject
               , @"Identifier (%@) already registered with another router (%@), can't register with this router (%@).",identifier,CFDictionaryGetValue([registry identifierToRouterMap], (CFStringRef)identifier),routeObject);
    
    CFDictionarySetValue([registry identifierToRouterMap], (CFStringRef)identifier, (__bridge const void *)(routeObject));
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
            if (!class_conformsToProtocol(destinationClass, destinationProtocol)) {
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
