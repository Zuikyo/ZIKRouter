//
//  ZIKViewRouteRegistry.m
//  ZIKRouter
//
//  Created by zuik on 2017/11/15.
//  Copyright © 2017 zuik. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#if __has_include("ZIKViewRouter.h")

#import "ZIKViewRouteRegistry.h"
#import "ZIKRouterInternal.h"
#import "ZIKRouteRegistryInternal.h"
#import "ZIKRouterRuntime.h"
#import <objc/runtime.h>
#import "ZIKClassCapabilities.h"
#if ZIK_HAS_UIKIT
#import <UIKit/UIKit.h>
#else
#import <AppKit/AppKit.h>
#endif
#import "ZIKViewRouterInternal.h"
#import "ZIKBlockViewRouter.h"
#import "ZIKViewRoutePrivate.h"
#import "ZIKViewRouterType.h"

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
@implementation ZIKViewRouteRegistry

+ (void)load {
    _destinationProtocolToDestinationMap = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, NULL, NULL);
    _moduleConfigProtocolToDestinationMap = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, NULL, NULL);
    _runtimeFactoryDestinationClasses = CFSetCreateMutable(kCFAllocatorDefault, 0, NULL);
    _destinationProtocolToRouterMap = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, NULL, NULL);
    _moduleConfigProtocolToRouterMap = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, NULL, NULL);
    _destinationToRoutersMap = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, NULL, &kCFTypeDictionaryValueCallBacks);
    _destinationToDefaultRouterMap = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, NULL, NULL);
    _destinationToExclusiveRouterMap = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, NULL, NULL);
    _identifierToRouterMap = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &kCFTypeDictionaryKeyCallBacks, NULL);
    _adapterToAdapteeMap = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, NULL, NULL);
    _identifierToDestinationMap = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &kCFTypeDictionaryKeyCallBacks, NULL);
    _destinationProtocolToFactoryMap = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, NULL, NULL);
    _identifierToFactoryMap = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &kCFTypeDictionaryKeyCallBacks, NULL);
    _destinationToDefaultFactoryMap = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, NULL, NULL);
    _moduleConfigProtocolToFactoryMap = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, NULL, NULL);
    _identifierToConfigFactoryMap = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &kCFTypeDictionaryKeyCallBacks, NULL);
    _destinationToDefaultConfigFactoryMap = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, NULL, NULL);
#if ZIKROUTER_CHECK
    _check_routerToDestinationsMap = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, NULL, &kCFTypeDictionaryValueCallBacks);
    _check_routerToDestinationProtocolsMap = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, NULL, &kCFTypeDictionaryValueCallBacks);
#endif
    zix_replaceMethodWithMethod([XXViewController class], @selector(initWithCoder:), self, @selector(ZIKViewRouteRegistry_hook_initWithCoder:));
    zix_replaceMethodWithMethod([XXStoryboardSegue class], @selector(initWithIdentifier:source:destination:), self, @selector(ZIKViewRouteRegistry_hook_initWithIdentifier:source:destination:));
}

- (nullable instancetype)ZIKViewRouteRegistry_hook_initWithCoder:(NSCoder *)aDecoder {
    [ZIKViewRouteRegistry hookPrepareForSegueForViewControllerClass:[self class]];
    return [self ZIKViewRouteRegistry_hook_initWithCoder:aDecoder];
}

#if ZIK_HAS_UIKIT
- (instancetype)ZIKViewRouteRegistry_hook_initWithIdentifier:(nullable NSString *)identifier source:(UIViewController *)source destination:(UIViewController *)destination
#else
- (instancetype)ZIKViewRouteRegistry_hook_initWithIdentifier:(nullable NSString *)identifier source:(NSViewController *)source destination:(NSViewController *)destination
#endif
{
    [ZIKViewRouteRegistry hookPerformForStoryboardSegueClass:[self class]];
    return [self ZIKViewRouteRegistry_hook_initWithIdentifier:identifier source:source destination:destination];
}

+ (void)hookPrepareForSegueForViewControllerClass:(Class)aClass {
    if (aClass == nil) {
        return;
    }
    static Class ZIKViewRouterClass;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ZIKViewRouterClass = [ZIKViewRouter class];
    });
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    //hook all XXViewController's -prepareForSegue:sender:
    zix_replaceMethodWithMethod(aClass, @selector(prepareForSegue:sender:),
                                ZIKViewRouterClass, @selector(ZIKViewRouter_hook_prepareForSegue:sender:));
#pragma clang diagnostic pop
}

+ (void)hookPerformForStoryboardSegueClass:(Class)aClass {
    if (aClass == nil) {
        return;
    }
    static Class ZIKViewRouterClass;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ZIKViewRouterClass = [ZIKViewRouter class];
    });
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    //hook all XXStoryboardSegue's -perform
    zix_replaceMethodWithMethod(aClass, @selector(perform),
                                ZIKViewRouterClass, @selector(ZIKViewRouter_hook_seguePerform));
#pragma clang diagnostic pop
}

+ (ZIKRoute *)easyRouteForDestinationClass:(Class)destinationClass factory:(id(^)(ZIKPerformRouteConfiguration * _Nonnull config, __kindof ZIKRouter * _Nonnull router))factory {
    ZIKViewRoute *route = [[ZIKViewRoute alloc] initWithMakeDestination:^id _Nullable(ZIKPerformRouteConfiguration * _Nonnull config, __kindof ZIKRouter * _Nonnull router) {
        if (!factory) {
            return nil;
        }
        return factory(config, router);
    }];
    if ([destinationClass isKindOfClass:[XXView class]]) {
        route.makeSupportedRouteTypes(^ZIKBlockViewRouteTypeMask{
            return ZIKBlockViewRouteTypeMaskViewDefault;
        });
    }
    return route;
}

+ (ZIKRoute *)easyRouteForDestinationClass:(Class)destinationClass configFactory:(ZIKPerformRouteConfiguration<ZIKConfigurationMakeable> *(^)(void))factory {
    return [[ZIKViewRoute alloc] initWithMakeDestination:^id _Nullable(ZIKPerformRouteConfiguration<ZIKConfigurationMakeable> * _Nonnull config, __kindof ZIKRouter * _Nonnull router) {
        if ([config conformsToProtocol:@protocol(ZIKConfigurationMakeable)]) {
            if ([config respondsToSelector:@selector(makeDestination)] && config.makeDestination) {
                id destination = config.makeDestination();
                return destination;
            }
        }
        return nil;
    }].makeDefaultConfiguration(^ZIKViewRouteConfiguration * _Nonnull{
        return (ZIKViewRouteConfiguration *)factory();
    });
}

+ (Class)routerTypeClass {
    return [ZIKViewRouterType class];
}

+ (nullable id)routeKeyForRouter:(ZIKRouter *)router {
    if ([router isKindOfClass:[ZIKViewRouter class]] == NO) {
        return nil;
    }
    if ([router isKindOfClass:[ZIKBlockViewRouter class]]) {
        return [(ZIKBlockViewRouter *)router route];
    }
    return [router class];
}

+ (CFMutableDictionaryRef)destinationProtocolToDestinationMap {
    return _destinationProtocolToDestinationMap;
}
+ (CFMutableDictionaryRef)moduleConfigProtocolToDestinationMap {
    return _moduleConfigProtocolToDestinationMap;
}
+ (CFMutableSetRef)runtimeFactoryDestinationClasses {
    return _runtimeFactoryDestinationClasses;
}
+ (CFMutableDictionaryRef)destinationProtocolToRouterMap {
    return _destinationProtocolToRouterMap;
}
+ (CFMutableDictionaryRef)moduleConfigProtocolToRouterMap {
    return _moduleConfigProtocolToRouterMap;
}
+ (CFMutableDictionaryRef)destinationToRoutersMap {
    return _destinationToRoutersMap;
}
+ (CFMutableDictionaryRef)destinationToDefaultRouterMap {
    return _destinationToDefaultRouterMap;
}
+ (CFMutableDictionaryRef)destinationToExclusiveRouterMap {
    return _destinationToExclusiveRouterMap;
}
+ (CFMutableDictionaryRef)identifierToRouterMap {
    return _identifierToRouterMap;
}
+ (CFMutableDictionaryRef)adapterToAdapteeMap {
    return _adapterToAdapteeMap;
}
+ (CFMutableDictionaryRef)identifierToDestinationMap {
    return _identifierToDestinationMap;
}
+ (CFMutableDictionaryRef)destinationProtocolToFactoryMap {
    return _destinationProtocolToFactoryMap;
}
+ (CFMutableDictionaryRef)identifierToFactoryMap {
    return _identifierToFactoryMap;
}
+ (CFMutableDictionaryRef)destinationToDefaultFactoryMap {
    return _destinationToDefaultFactoryMap;
}
+ (CFMutableDictionaryRef)moduleConfigProtocolToFactoryMap {
    return _moduleConfigProtocolToFactoryMap;
}
+ (CFMutableDictionaryRef)identifierToConfigFactoryMap {
    return _identifierToConfigFactoryMap;
}
+ (CFMutableDictionaryRef)destinationToDefaultConfigFactoryMap {
    return _destinationToDefaultConfigFactoryMap;
}
+ (CFMutableDictionaryRef)_check_routerToDestinationsMap {
#if ZIKROUTER_CHECK
    return _check_routerToDestinationsMap;
#else
    return NULL;
#endif
}
+ (CFMutableDictionaryRef)_check_routerToDestinationProtocolsMap {
#if ZIKROUTER_CHECK
    return _check_routerToDestinationProtocolsMap;
#else
    return NULL;
#endif
}

+ (void)handleEnumerateRouterClass:(Class)class {
    static Class ZIKViewRouterClass;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ZIKViewRouterClass = [ZIKViewRouter class];
    });
    if (zix_classIsSubclassOfClass(class, ZIKViewRouterClass)) {
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
    static Class ZIKViewRouterClass;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ZIKViewRouterClass = [ZIKViewRouter class];
    });
    if (zix_classIsSubclassOfClass(aClass, ZIKViewRouterClass)) {
        if ([aClass isAbstractRouter]) {
            return NO;
        }
        return YES;
    }
    return NO;
}

+ (BOOL)isDestinationClassRoutable:(Class)aClass {
    Class XXResponderClass = [XXResponder class];
    while (aClass && aClass != XXResponderClass) {
        if (class_conformsToProtocol(aClass, @protocol(ZIKRoutableView))) {
            return YES;
        }
        aClass = class_getSuperclass(aClass);
    }
    return NO;
}

+ (BOOL)isDestinationClass:(Class)destinationClass registeredWithRouter:(Class)routerClass {
    NSParameterAssert([routerClass isSubclassOfClass:[ZIKViewRouter class]]);
    CFDictionaryRef destinationToExclusiveRouterMap = ZIKViewRouteRegistry.destinationToExclusiveRouterMap;
    CFDictionaryRef destinationToRoutersMap = ZIKViewRouteRegistry.destinationToRoutersMap;
    Class XXResponderClass = [XXResponder class];
    while (destinationClass && destinationClass != XXResponderClass) {
        Class exclusiveRouter = (Class)CFDictionaryGetValue(destinationToExclusiveRouterMap, (__bridge const void *)(destinationClass));
        if (exclusiveRouter == routerClass) {
            return YES;
        }
        CFMutableSetRef routers = (CFMutableSetRef)CFDictionaryGetValue(destinationToRoutersMap, (__bridge const void *)(destinationClass));
        if (routers) {
            NSSet *registeredRouters = (__bridge NSSet *)(routers);
            if ([registeredRouters containsObject:routerClass]) {
                return YES;
            }
        }
        destinationClass = class_getSuperclass(destinationClass);
    }
    return NO;
}

+ (void)enumerateAllViewRouters:(void(NS_NOESCAPE ^)(Class _Nullable routerClass, ZIKViewRoute * _Nullable route))handler {
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
        if (zix_classIsSubclassOfClass(class, [XXResponder class])) {
            if (class_conformsToProtocol(class, @protocol(ZIKRoutableView))) {
                if (!(zix_classIsSubclassOfClass(class, [XXView class]) || class == [XXView class] || zix_classIsSubclassOfClass(class, [XXViewController class]) || class == [XXViewController class])) {
                    [errorDescription appendFormat:@"\n\n❌%@ should not conform to ZIKRoutableView. ZIKRoutableView only supports UIView/NSView and UIViewController/NSViewController", class];
                }
                [_routableDestinations addObject:class];
            }
        } else if (zix_classIsSubclassOfClass(class, [ZIKViewRouter class])) {
            if (!(zix_classSelfImplementingMethod(class, @selector(registerRoutableDestination), true) ||
                  [class isAbstractRouter])) {
                [errorDescription appendFormat:@"\n\n❌Router(%@) must override +registerRoutableDestination to register destination.", class];
            }
            if (!(zix_classSelfImplementingMethod(class, @selector(destinationWithConfiguration:), false) ||
                  [class isAbstractRouter] ||
                  [class isAdapter])) {
                [errorDescription appendFormat:@"\n\n❌Router(%@) must override -destinationWithConfiguration: to return destination.", class];
            }
            CFMutableSetRef views = (CFMutableSetRef)CFDictionaryGetValue(self._check_routerToDestinationsMap, (__bridge const void *)(class));
            NSSet *viewSet = (__bridge NSSet *)(views);
            if (!(viewSet.count > 0 || [class isAbstractRouter] || [class isAdapter])) {
                [errorDescription appendFormat:@"\n\n❌Router class(%@) is not resgistered with any view class. Use +[%@ registerView:] to register view in Router(%@)'s +registerRoutableDestination.", class, class, class];
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
            [errorDescription appendFormat:@"\n\n❌Routable view(%@) is not registered with any view router.", destinationClass];
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
    NSMutableString *errorDescription = [NSMutableString string];
    NSDictionary<Class, NSSet *> *destinationToRoutersMap = (__bridge NSDictionary *)self.destinationToRoutersMap;
    [destinationToRoutersMap enumerateKeysAndObjectsUsingBlock:^(Class  _Nonnull key, NSSet * _Nonnull obj, BOOL * _Nonnull stop) {
        [obj enumerateObjectsUsingBlock:^(id  _Nonnull obj, BOOL * _Nonnull stop) {
            if (obj == [obj class]) {
                return;
            }
            NSAssert([obj isKindOfClass:[ZIKViewRoute class]], @"The object is either a ZIKViewRouter class or a ZIKViewRoute");
            ZIKViewRoute *route = obj;
            if (zix_classIsSubclassOfClass(key, [XXView class])) {
                if (!([route supportRouteType:ZIKViewRouteTypeAddAsSubview] || [route supportRouteType:ZIKViewRouteTypeCustom])) {
                    [errorDescription appendFormat:@"\n\n❌If the destination is UIView/NSView type, the router (%@) must set supportedRouteTypes and support ZIKViewRouteTypeAddAsSubview or ZIKViewRouteTypeCustom.", route];
                }
            }
            if ([route supportRouteType:ZIKViewRouteTypeCustom]) {
                if (route.canPerformCustomRouteBlock == nil) {
                    [errorDescription appendFormat:@"\n\n❌The route (%@) supports ZIKViewRouteTypeCustom, but missing  -canPerformCustomRoute.", route];
                }
                if (route.performCustomRouteBlock == nil) {
                    [errorDescription appendFormat:@"\n\n❌The route (%@) supports ZIKViewRouteTypeCustom, but missing  -performCustomRoute.", route];
                }
            }
        }];
    }];
    if (errorDescription.length > 0) {
        NSLog(@"\n❌Found router implementation errors:%@", errorDescription);
        NSAssert(NO, errorDescription);
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
    if (zix_protocolConformsToProtocol(protocol, @protocol(ZIKViewRoutable)) &&
        protocol != @protocol(ZIKViewRoutable)) {
        ZIKRouterType *routerType = [self routerToDestination:protocol];
        if (!routerType) {
            return [NSString stringWithFormat:@"\n\n❌Declared view protocol(%@) is not registered with any router class!", NSStringFromProtocol(protocol)];
        }
        id router = routerType.routerClass;
        if (router == nil) {
            router = routerType.route;
        }
        CFSetRef viewsRef = CFDictionaryGetValue(self._check_routerToDestinationsMap, (__bridge const void *)(router));
        NSSet *views = (__bridge NSSet *)(viewsRef);
        if (!(views.count > 0 ||
              CFDictionaryGetValue(self.destinationProtocolToDestinationMap, (__bridge const void *)(protocol)) ||
              CFDictionaryGetValue(self.destinationProtocolToFactoryMap, (__bridge const void *)(protocol)))) {
            return [NSString stringWithFormat:@"\n\n❌Router(%@) didn't registered with any viewClass", router];
        }
        NSMutableString *error = [NSMutableString string];
        for (Class viewClass in views) {
            if (![viewClass conformsToProtocol:protocol]) {
                [error appendFormat:@"\n\n❌Router(%@)'s viewClass(%@) should conform to registered protocol(%@)",router, viewClass, NSStringFromProtocol(protocol)];
            }
        }
        if (error.length > 0) {
            return error;
        }
    } else if (zix_protocolConformsToProtocol(protocol, @protocol(ZIKViewModuleRoutable)) &&
               protocol != @protocol(ZIKViewModuleRoutable)) {
        ZIKRouterType *routerType = [self routerToModule:protocol];
        if (!routerType) {
            return [NSString stringWithFormat:@"\n\n❌Declared view module config protocol(%@) is not registered with any router class!", NSStringFromProtocol(protocol)];
        }
        ZIKViewRouteConfiguration *config = [routerType defaultRouteConfiguration];
        if (![config conformsToProtocol:protocol]) {
            return [NSString stringWithFormat:@"\n\n❌Router(%@)'s default ZIKViewRouteConfiguration(%@) should conform to registered config protocol(%@)", routerType, [config class], NSStringFromProtocol(protocol)];
        }
    }
    return nil;
}
#endif

+ (void)validateMakeableConfiguration:(ZIKPerformRouteConfiguration<ZIKConfigurationMakeable> *)config {
    [super validateMakeableConfiguration:config];
    NSAssert1([config isKindOfClass:[ZIKViewRouteConfiguration class]], @"Registered module config factory for view router should return a ZIKViewRouteConfiguration type: (%@).", config);
}

#pragma mark Check Override

#if ZIKROUTER_CHECK

+ (void)registerDestination:(Class)destinationClass router:(Class)routerClass {
    NSParameterAssert([routerClass isSubclassOfClass:[ZIKViewRouter class]]);
    if (zix_classIsSubclassOfClass(destinationClass, [XXView class])) {
        NSAssert1([routerClass supportRouteType:ZIKViewRouteTypeAddAsSubview] || [routerClass supportRouteType:ZIKViewRouteTypeCustom], @"If the destination is UIView/NSView type, the router (%@) must override +supportedRouteTypes and support ZIKViewRouteTypeAddAsSubview or ZIKViewRouteTypeCustom.", routerClass);
        if ([routerClass supportRouteType:ZIKViewRouteTypeCustom]) {
            NSAssert1(zix_classSelfImplementingMethod(routerClass, @selector(canPerformCustomRoute), false), @"The router (%@) supports ZIKViewRouteTypeCustom, but doesn't override -canPerformCustomRoute.", routerClass);
            NSAssert1(zix_classSelfImplementingMethod(routerClass, @selector(performCustomRouteOnDestination:fromSource:configuration:), false), @"The router (%@) supports ZIKViewRouteTypeCustom, but doesn't override -performCustomRouteOnDestination:fromSource:configuration:.", routerClass);
        }
    }
    [super registerDestination:destinationClass router:routerClass];
}

+ (void)registerExclusiveDestination:(Class)destinationClass router:(Class)routerClass {
    NSParameterAssert([routerClass isSubclassOfClass:[ZIKViewRouter class]]);
    [super registerExclusiveDestination:destinationClass router:routerClass];
}

+ (void)registerDestinationProtocol:(Protocol *)destinationProtocol router:(Class)routerClass {
    NSParameterAssert([routerClass isSubclassOfClass:[ZIKViewRouter class]]);
    [super registerDestinationProtocol:destinationProtocol router:routerClass];
}

+ (void)registerModuleProtocol:(Protocol *)configProtocol router:(Class)routerClass {
    NSParameterAssert([routerClass isSubclassOfClass:[ZIKViewRouter class]]);
    [super registerModuleProtocol:configProtocol router:routerClass];
}

+ (void)registerIdentifier:(NSString *)identifier router:(Class)routerClass {
    NSParameterAssert([routerClass isSubclassOfClass:[ZIKViewRouter class]]);
    [super registerIdentifier:identifier router:routerClass];
}

+ (void)registerDestination:(Class)destinationClass route:(ZIKViewRoute *)route {
    NSParameterAssert([route isKindOfClass:[ZIKViewRoute class]]);
    [super registerDestination:destinationClass route:route];
}

+ (void)registerExclusiveDestination:(Class)destinationClass route:(ZIKRoute *)route {
    NSParameterAssert([route isKindOfClass:[ZIKViewRoute class]]);
    [super registerExclusiveDestination:destinationClass route:route];
}

+ (void)registerDestinationProtocol:(Protocol *)destinationProtocol route:(ZIKRoute *)route {
    NSParameterAssert([route isKindOfClass:[ZIKViewRoute class]]);
    [super registerDestinationProtocol:destinationProtocol route:route];
}

+ (void)registerModuleProtocol:(Protocol *)configProtocol route:(ZIKRoute *)route {
    NSParameterAssert([route isKindOfClass:[ZIKViewRoute class]]);
    [super registerModuleProtocol:configProtocol route:route];
}

+ (void)registerIdentifier:(NSString *)identifier route:(ZIKRoute *)route {
    NSParameterAssert([route isKindOfClass:[ZIKViewRoute class]]);
    [super registerIdentifier:identifier route:route];
}

#endif

@end

#endif
