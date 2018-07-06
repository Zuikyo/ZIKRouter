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

///Implementation is in ZRouter
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
    for (Class registry in registries) {
        [registry willEnumerateClasses];
    }
    ZIKRouter_enumerateClassList(^(__unsafe_unretained Class class) {
        for (Class registry in registries) {
            [registry handleEnumerateClasses:class];
        }
    });
    for (Class registry in registries) {
        [registry didFinishEnumerateClasses];
    }
#if ZIKROUTER_CHECK
    ZIKRouter_enumerateProtocolList(^(Protocol *protocol) {
        for (Class registry in registries) {
            [registry handleEnumerateProtocoles:protocol];
        }
    });
#endif
    for (Class registry in registries) {
        [registry didFinishRegistration];
    }
    self.registrationFinished = YES;
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
    CFDictionaryRef destinationToDefaultRouterMap = self.destinationToDefaultRouterMap;
    while (destinationClass) {
        if (![self isDestinationClassRoutable:destinationClass]) {
            break;
        }
        id route = CFDictionaryGetValue(destinationToDefaultRouterMap, (__bridge const void *)(destinationClass));
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
    CFDictionaryRef destinationToRoutersMap = self.destinationToRoutersMap;
    while (destinationClass) {
        if (![self isDestinationClassRoutable:destinationClass]) {
            break;
        }
        CFMutableSetRef routers = (CFMutableSetRef)CFDictionaryGetValue(destinationToRoutersMap, (__bridge const void *)(destinationClass));
        NSSet *routes = (__bridge NSSet *)(routers);
        for (id route in routes) {
            if (handler) {
                ZIKRouterType *r = [self _routerTypeForObject:route];
                if (r) {
                    handler(r);
                }
            }
        }
        destinationClass = class_getSuperclass(destinationClass);
    }
}

#pragma mark Register

+ (void)registerDestination:(Class)destinationClass router:(Class)routerClass {
    NSParameterAssert([routerClass isSubclassOfClass:[ZIKRouter class]]);
    [self _registerDestination:destinationClass routeObject:routerClass];
}

+ (void)registerExclusiveDestination:(Class)destinationClass router:(Class)routerClass {
    NSParameterAssert([routerClass isSubclassOfClass:[ZIKRouter class]]);
    [self _registerExclusiveDestination:destinationClass routeObject:routerClass];
}

+ (void)registerDestinationProtocol:(Protocol *)destinationProtocol router:(Class)routerClass {
    NSParameterAssert([routerClass isSubclassOfClass:[ZIKRouter class]]);
    [self _registerDestinationProtocol:destinationProtocol routeObject:routerClass];
}

+ (void)registerModuleProtocol:(Protocol *)configProtocol router:(Class)routerClass {
    NSParameterAssert([routerClass isSubclassOfClass:[ZIKRouter class]]);
    [self _registerModuleProtocol:configProtocol routeObject:routerClass];
}

+ (void)registerIdentifier:(NSString *)identifier router:(Class)routerClass {
    NSParameterAssert([routerClass isSubclassOfClass:[ZIKRouter class]]);
    [self _registerIdentifier:identifier routeObject:routerClass];
}

+ (void)registerDestination:(Class)destinationClass route:(ZIKRoute *)route {
    NSParameterAssert([route isKindOfClass:[ZIKRoute class]]);
    [self _registerDestination:destinationClass routeObject:route];
}

+ (void)registerExclusiveDestination:(Class)destinationClass route:(ZIKRoute *)route {
    NSParameterAssert([route isKindOfClass:[ZIKRoute class]]);
    [self _registerExclusiveDestination:destinationClass routeObject:route];
}

+ (void)registerDestinationProtocol:(Protocol *)destinationProtocol route:(ZIKRoute *)route {
    NSParameterAssert([route isKindOfClass:[ZIKRoute class]]);
    [self _registerDestinationProtocol:destinationProtocol routeObject:route];
}

+ (void)registerModuleProtocol:(Protocol *)configProtocol route:(ZIKRoute *)route {
    NSParameterAssert([route isKindOfClass:[ZIKRoute class]]);
    [self _registerModuleProtocol:configProtocol routeObject:route];
}

+ (void)registerIdentifier:(NSString *)identifier route:(ZIKRoute *)route {
    NSParameterAssert([route isKindOfClass:[ZIKRoute class]]);
    [self _registerIdentifier:identifier routeObject:route];
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

+ (void)_registerDestination:(Class)destinationClass routeObject:(id)routeObject {
    NSCParameterAssert([self isDestinationClassRoutable:destinationClass]);
    NSAssert3(!self.destinationToExclusiveRouterMap ||
              (self.destinationToExclusiveRouterMap && !CFDictionaryGetValue(self.destinationToExclusiveRouterMap, (__bridge const void *)(destinationClass))), @"There is a registered exclusive router (%@), can't register this router (%@) for this destinationClass (%@).",CFDictionaryGetValue(self.destinationToExclusiveRouterMap, (__bridge const void *)(destinationClass)), routeObject, destinationClass);
    
#if ZIKROUTER_CHECK
    BOOL lockResult = [self.lock tryLock];
    NSAssert(lockResult == YES, @"Don't register router in multi threads. It's not thread safe.");
#endif
    
    CFMutableDictionaryRef destinationToDefaultRouterMap = self.destinationToDefaultRouterMap;
    if (!CFDictionaryContainsKey(destinationToDefaultRouterMap, (__bridge const void *)(destinationClass))) {
        CFDictionarySetValue(destinationToDefaultRouterMap, (__bridge const void *)(destinationClass), (__bridge const void *)(routeObject));
    }
    CFMutableDictionaryRef destinationToRoutersMap = self.destinationToRoutersMap;
    CFMutableSetRef routers = (CFMutableSetRef)CFDictionaryGetValue(destinationToRoutersMap, (__bridge const void *)(destinationClass));
    if (routers == NULL) {
        routers = CFSetCreateMutable(kCFAllocatorDefault, 0, NULL);
        CFDictionarySetValue(destinationToRoutersMap, (__bridge const void *)(destinationClass), routers);
    }
    CFSetAddValue(routers, (__bridge const void *)(routeObject));
    
#if ZIKROUTER_CHECK
    CFMutableSetRef destinations = (CFMutableSetRef)CFDictionaryGetValue(self._check_routerToDestinationsMap, (__bridge const void *)(routeObject));
    if (destinations == NULL) {
        destinations = CFSetCreateMutable(kCFAllocatorDefault, 0, NULL);
        CFDictionarySetValue(self._check_routerToDestinationsMap, (__bridge const void *)(routeObject), destinations);
    }
    CFSetAddValue(destinations, (__bridge const void *)(destinationClass));
    
    if (lockResult) {
        [self.lock unlock];
    }
#endif
}

+ (void)_registerExclusiveDestination:(Class)destinationClass routeObject:(id)routeObject {
    NSCParameterAssert([self isDestinationClassRoutable:destinationClass]);
    NSAssert2(!CFDictionaryGetValue(self.destinationToExclusiveRouterMap, (__bridge const void *)(destinationClass)), @"There is already a registered exclusive router (%@) for this destinationClass, can't register this router (%@). You can only specific one exclusive router for each destinationClass. Choose the router used as dependency injector.",CFDictionaryGetValue(self.destinationToExclusiveRouterMap, (__bridge const void *)(destinationClass)),routeObject);
    NSAssert2(!CFDictionaryGetValue(self.destinationToDefaultRouterMap, (__bridge const void *)(destinationClass)), @"destinationClass already registered with another router (%@), check and remove them. You shall only use this exclusive router (%@) for this destinationClass.",CFDictionaryGetValue(self.destinationToDefaultRouterMap, (__bridge const void *)(destinationClass)),routeObject);
    NSAssert(!CFDictionaryContainsKey(self.destinationToRoutersMap, (__bridge const void *)(destinationClass)) ||
             (CFDictionaryContainsKey(self.destinationToRoutersMap, (__bridge const void *)(destinationClass)) &&
              !CFSetContainsValue(
                                  (CFMutableSetRef)CFDictionaryGetValue(self.destinationToRoutersMap, (__bridge const void *)(destinationClass)),
                                  (__bridge const void *)(routeObject)
                                  ))
             , @"destinationClass already registered with another router, check and remove them. You shall only use the exclusive router for this destinationClass.");
    
#if ZIKROUTER_CHECK
    BOOL lockResult = [self.lock tryLock];
    NSAssert(lockResult == YES, @"Don't register router in multi threads. It's not thread safe.");
#endif
    
    CFDictionarySetValue(self.destinationToExclusiveRouterMap, (__bridge const void *)(destinationClass), (__bridge const void *)(routeObject));
    CFDictionarySetValue(self.destinationToDefaultRouterMap, (__bridge const void *)(destinationClass), (__bridge const void *)(routeObject));
    
    CFMutableDictionaryRef destinationToRoutersMap = self.destinationToRoutersMap;
    CFMutableSetRef routers = (CFMutableSetRef)CFDictionaryGetValue(destinationToRoutersMap, (__bridge const void *)(destinationClass));
    if (routers == NULL) {
        routers = CFSetCreateMutable(kCFAllocatorDefault, 0, NULL);
        CFDictionarySetValue(destinationToRoutersMap, (__bridge const void *)(destinationClass), routers);
    }
    CFSetAddValue(routers, (__bridge const void *)(routeObject));
    
#if ZIKROUTER_CHECK
    CFMutableSetRef destinations = (CFMutableSetRef)CFDictionaryGetValue(self._check_routerToDestinationsMap, (__bridge const void *)(routeObject));
    if (destinations == NULL) {
        destinations = CFSetCreateMutable(kCFAllocatorDefault, 0, NULL);
        CFDictionarySetValue(self._check_routerToDestinationsMap, (__bridge const void *)(routeObject), destinations);
    }
    CFSetAddValue(destinations, (__bridge const void *)(destinationClass));
    
    if (lockResult) {
        [self.lock unlock];
    }
#endif
}

+ (void)_registerDestinationProtocol:(Protocol *)destinationProtocol routeObject:(id)routeObject {
    NSAssert3(!CFDictionaryGetValue(self.destinationProtocolToRouterMap, (__bridge const void *)(destinationProtocol)) ||
              (Class)CFDictionaryGetValue(self.destinationProtocolToRouterMap, (__bridge const void *)(destinationProtocol)) == routeObject
              , @"Destination protocol (%@) already registered with another router (%@), can't register with this router (%@). Same destination protocol should only be used by one routeObject.",NSStringFromProtocol(destinationProtocol),CFDictionaryGetValue(self.destinationProtocolToRouterMap, (__bridge const void *)(destinationProtocol)),routeObject);
    
#if ZIKROUTER_CHECK
    BOOL lockResult = [self.lock tryLock];
    NSAssert(lockResult == YES, @"Don't register router in multi threads. It's not thread safe.");
#endif
    
    CFDictionarySetValue(self.destinationProtocolToRouterMap, (__bridge const void *)(destinationProtocol), (__bridge const void *)(routeObject));
#if ZIKROUTER_CHECK
    CFMutableSetRef destinationProtocols = (CFMutableSetRef)CFDictionaryGetValue(self._check_routerToDestinationProtocolsMap, (__bridge const void *)(routeObject));
    if (destinationProtocols == NULL) {
        destinationProtocols = CFSetCreateMutable(kCFAllocatorDefault, 0, NULL);
        CFDictionarySetValue(self._check_routerToDestinationProtocolsMap, (__bridge const void *)(routeObject), destinationProtocols);
    }
    CFSetAddValue(destinationProtocols, (__bridge const void *)(destinationProtocol));
    
    if (lockResult) {
        [self.lock unlock];
    }
#endif
}

+ (void)_registerModuleProtocol:(Protocol *)configProtocol routeObject:(id)routeObject {
    NSAssert3(!CFDictionaryGetValue(self.moduleConfigProtocolToRouterMap, (__bridge const void *)(configProtocol)) ||
              (Class)CFDictionaryGetValue(self.moduleConfigProtocolToRouterMap, (__bridge const void *)(configProtocol)) == routeObject
              , @"Module config protocol (%@) already registered with another router (%@), can't register with this router (%@). Same configProtocol should only be used by one routeObject.",NSStringFromProtocol(configProtocol),CFDictionaryGetValue(self.moduleConfigProtocolToRouterMap, (__bridge const void *)(configProtocol)),routeObject);
    
#if ZIKROUTER_CHECK
    BOOL lockResult = [self.lock tryLock];
    NSAssert(lockResult == YES, @"Don't register router in multi threads. It's not thread safe.");
#endif
    
    CFDictionarySetValue(self.moduleConfigProtocolToRouterMap, (__bridge const void *)(configProtocol), (__bridge const void *)(routeObject));
    
#if ZIKROUTER_CHECK
    if (lockResult) {
        [self.lock unlock];
    }
#endif
}

+ (void)_registerIdentifier:(NSString *)identifier routeObject:(id)routeObject {
    NSParameterAssert(identifier.length > 0);
    if (identifier == nil) {
        return;
    }
    NSAssert3(!CFDictionaryGetValue(self.identifierToRouterMap, (CFStringRef)identifier) ||
              (Class)CFDictionaryGetValue(self.identifierToRouterMap, (CFStringRef)identifier) == routeObject
              , @"Identifier (%@) already registered with another router (%@), can't register with this router (%@).",identifier,CFDictionaryGetValue(self.identifierToRouterMap, (CFStringRef)identifier),routeObject);
    
#if ZIKROUTER_CHECK
    BOOL lockResult = [self.lock tryLock];
    NSAssert(lockResult == YES, @"Don't register router in multi threads. It's not thread safe.");
#endif
    
    CFDictionarySetValue(self.identifierToRouterMap, (CFStringRef)identifier, (__bridge const void *)(routeObject));
    
#if ZIKROUTER_CHECK
    if (lockResult) {
        [self.lock unlock];
    }
#endif
}

#pragma mark Manually Register

+ (void)notifyRegistrationFinished {
    NSAssert(self.autoRegister == NO, @"Only use -notifyRegistrationFinished for manually registration.");
    if (_registrationFinished) {
        NSAssert(NO, @"Registration is already finished.");
        return;
    }
    NSSet *registries = [[self registries] copy];
    for (Class registry in registries) {
        [registry didFinishRegistration];
    }
    
    self.registrationFinished = YES;
}

#pragma mark Debug

+ (NSArray<Class> *)allExternalRouters {
    NSMutableArray<Class> *routers = [NSMutableArray array];
    NSSet *registries = [[self registries] copy];
    for (Class registry in registries) {
        NSMutableArray<Class> *swiftRouters = [NSMutableArray array];
        ZIKRouter_enumerateClassList(^(__unsafe_unretained Class class) {
            if ([registry isRegisterableRouterClass:class]) {
                if ([class isAdapter]) {
                    return;
                }
                if ([NSStringFromClass(class) containsString:@"."]) {
                    [swiftRouters addObject:class];
                } else {
                    [routers addObject:class];
                }
            }
        });
        if (swiftRouters.count > 0) {
            [routers addObjectsFromArray:swiftRouters];
        }
    }
    return routers;
}

+ (NSArray<Class> *)allExternalObjcRouters {
    NSMutableArray<Class> *routers = [NSMutableArray array];
    NSSet *registries = [[self registries] copy];
    for (Class registry in registries) {
        ZIKRouter_enumerateClassList(^(__unsafe_unretained Class class) {
            if ([registry isRegisterableRouterClass:class]) {
                if ([class isAdapter]) {
                    return;
                }
                if ([NSStringFromClass(class) containsString:@"."] == NO) {
                    [routers addObject:class];
                }
            }
        });
    }
    return routers;
}

+ (NSArray<Class> *)allExternalSwiftRouters {
    NSMutableArray<Class> *routers = [NSMutableArray array];
    NSSet *registries = [[self registries] copy];
    for (Class registry in registries) {
        ZIKRouter_enumerateClassList(^(__unsafe_unretained Class class) {
            if ([registry isRegisterableRouterClass:class]) {
                if ([class isAdapter]) {
                    return;
                }
                if ([NSStringFromClass(class) containsString:@"."]) {
                    [routers addObject:class];
                }
            }
        });
    }
    return routers;
}

+ (NSArray<Class> *)allAdapters {
    NSMutableArray<Class> *routers = [NSMutableArray array];
    NSSet *registries = [[self registries] copy];
    for (Class registry in registries) {
        NSMutableArray<Class> *swiftRouters = [NSMutableArray array];
        ZIKRouter_enumerateClassList(^(__unsafe_unretained Class class) {
            if ([registry isRegisterableRouterClass:class]) {
                if ([class isAdapter] == NO) {
                    return;
                }
                if ([NSStringFromClass(class) containsString:@"."]) {
                    [swiftRouters addObject:class];
                } else {
                    [routers addObject:class];
                }
            }
        });
        if (swiftRouters.count > 0) {
            [routers addObjectsFromArray:swiftRouters];
        }
    }
    return routers;
}

+ (NSArray<Class> *)allObjcAdapters {
    NSMutableArray<Class> *routers = [NSMutableArray array];
    NSSet *registries = [[self registries] copy];
    for (Class registry in registries) {
        ZIKRouter_enumerateClassList(^(__unsafe_unretained Class class) {
            if ([registry isRegisterableRouterClass:class]) {
                if ([class isAdapter] == NO) {
                    return;
                }
                if ([NSStringFromClass(class) containsString:@"."] == NO) {
                    [routers addObject:class];
                }
            }
        });
    }
    return routers;
}

+ (NSArray<Class> *)allSwiftAdapters {
    NSMutableArray<Class> *routers = [NSMutableArray array];
    NSSet *registries = [[self registries] copy];
    for (Class registry in registries) {
        ZIKRouter_enumerateClassList(^(__unsafe_unretained Class class) {
            if ([registry isRegisterableRouterClass:class]) {
                if ([class isAdapter] == NO) {
                    return;
                }
                if ([NSStringFromClass(class) containsString:@"."]) {
                    [routers addObject:class];
                }
            }
        });
    }
    return routers;
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

+ (NSLock *)lock {
    NSAssert(NO, @"%@ must override %@",self,NSStringFromSelector(_cmd));
    return nil;
}

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

+ (void)handleEnumerateClasses:(Class)aClass {
    
}

+ (void)didFinishEnumerateClasses {
    
}

+ (void)handleEnumerateProtocoles:(Protocol *)aProtocol {
    
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
