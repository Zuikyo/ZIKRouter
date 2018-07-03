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
#if ZIKROUTER_CHECK
static CFMutableDictionaryRef _check_routerToDestinationsMap;
static CFMutableDictionaryRef _check_routerToDestinationProtocolsMap;
static NSMutableArray<Class> *_routableDestinations;
static NSMutableArray<Class> *_routerClasses;
#endif
@implementation ZIKViewRouteRegistry

+ (void)load {
    _destinationProtocolToRouterMap = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, NULL, NULL);
    _moduleConfigProtocolToRouterMap = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, NULL, NULL);
    _destinationToRoutersMap = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, NULL, &kCFTypeDictionaryValueCallBacks);
    _destinationToDefaultRouterMap = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, NULL, NULL);
    _destinationToExclusiveRouterMap = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, NULL, NULL);
    _identifierToRouterMap = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &kCFTypeDictionaryKeyCallBacks, NULL);
    _adapterToAdapteeMap = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, NULL, NULL);
#if ZIKROUTER_CHECK
    _check_routerToDestinationsMap = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, NULL, &kCFTypeDictionaryValueCallBacks);
    _check_routerToDestinationProtocolsMap = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, NULL, &kCFTypeDictionaryValueCallBacks);
#endif
    ZIKRouter_replaceMethodWithMethod([XXViewController class], @selector(initWithCoder:), self, @selector(ZIKViewRouteRegistry_hook_initWithCoder:));
    ZIKRouter_replaceMethodWithMethod([XXStoryboardSegue class], @selector(initWithIdentifier:source:destination:), self, @selector(ZIKViewRouteRegistry_hook_initWithIdentifier:source:destination:));
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
    ZIKRouter_replaceMethodWithMethod(aClass, @selector(prepareForSegue:sender:),
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
    ZIKRouter_replaceMethodWithMethod(aClass, @selector(perform),
                                      ZIKViewRouterClass, @selector(ZIKViewRouter_hook_seguePerform));
#pragma clang diagnostic pop
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

+ (NSLock *)lock {
    static NSLock *_lock;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _lock = [[NSLock alloc] init];
    });
    return _lock;
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

+ (void)willEnumerateClasses {
#if ZIKROUTER_CHECK
    _routableDestinations = [NSMutableArray array];
    _routerClasses = [NSMutableArray array];
#endif
}

+ (void)handleEnumerateClasses:(Class)class {
    static Class ZIKViewRouterClass;
    static Class XXResponderClass;
    static Class XXViewControllerClass;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ZIKViewRouterClass = [ZIKViewRouter class];
        XXResponderClass = [XXResponder class];
        XXViewControllerClass = [XXViewController class];
    });
#if ZIKROUTER_CHECK
    if (ZIKRouter_classIsSubclassOfClass(class, XXResponderClass)) {
        if (class_conformsToProtocol(class, @protocol(ZIKRoutableView))) {
            NSCAssert(ZIKRouter_classIsSubclassOfClass(class, [XXView class]) || class == [XXView class] || ZIKRouter_classIsSubclassOfClass(class, XXViewControllerClass) || class == [XXViewController class], @"ZIKRoutableView only suppourt UIView/NSView and UIViewController/NSViewController");
            [_routableDestinations addObject:class];
        }
    }
#endif
    if (ZIKRouter_classIsSubclassOfClass(class, ZIKViewRouterClass)) {
        NSCAssert1(ZIKRouter_classSelfImplementingMethod(class, @selector(registerRoutableDestination), true) || [class isAbstractRouter], @"Router(%@) must override +registerRoutableDestination to register destination.",class);
        NSCAssert1(ZIKRouter_classSelfImplementingMethod(class, @selector(destinationWithConfiguration:), false) || [class isAbstractRouter] || [class isAdapter], @"Router(%@) must override -destinationWithConfiguration: to return destination.",class);
        [class registerRoutableDestination];
#if ZIKROUTER_CHECK
        CFMutableSetRef views = (CFMutableSetRef)CFDictionaryGetValue(self._check_routerToDestinationsMap, (__bridge const void *)(class));
        NSSet *viewSet = (__bridge NSSet *)(views);
        NSCAssert3(viewSet.count > 0 || [class isAbstractRouter] || [class isAdapter], @"This router class(%@) was not resgistered with any view class. Use +[%@ registerView:] to register view in Router(%@)'s +registerRoutableDestination.",class,class,class);
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
    static Class ZIKViewRouterClass;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ZIKViewRouterClass = [ZIKViewRouter class];
    });
    if (ZIKRouter_classIsSubclassOfClass(aClass, ZIKViewRouterClass)) {
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

#pragma mark Check

#if ZIKROUTER_CHECK

+ (void)_searchAllRoutersAndDestinations {
    _routableDestinations = [NSMutableArray array];
    _routerClasses = [NSMutableArray array];
    ZIKRouter_enumerateClassList(^(__unsafe_unretained Class class) {
        if (class == nil) {
            return;
        }
        if (ZIKRouter_classIsSubclassOfClass(class, [XXResponder class])) {
            if (class_conformsToProtocol(class, @protocol(ZIKRoutableView))) {
                NSCAssert(ZIKRouter_classIsSubclassOfClass(class, [XXView class]) || class == [XXView class] || ZIKRouter_classIsSubclassOfClass(class, [XXViewController class]) || class == [XXViewController class], @"ZIKRoutableView only suppourt UIView/NSView and UIViewController/NSViewController");
                [_routableDestinations addObject:class];
            }
        } else if (ZIKRouter_classIsSubclassOfClass(class, [ZIKViewRouter class])) {
            
            CFMutableSetRef views = (CFMutableSetRef)CFDictionaryGetValue(self._check_routerToDestinationsMap, (__bridge const void *)(class));
            NSSet *viewSet = (__bridge NSSet *)(views);
            NSCAssert3(viewSet.count > 0 || [class isAbstractRouter] || [class isAdapter], @"This router class(%@) was not resgistered with any view class. Use +[%@ registerView:] to register view in Router(%@)'s +registerRoutableDestination.",class,class,class);
            [_routerClasses addObject:class];
        }
    });
}

+ (void)_checkAllRoutableDestinations {
    for (Class destinationClass in _routableDestinations) {
        NSCAssert1(CFDictionaryGetValue(self.destinationToDefaultRouterMap, (__bridge const void *)(destinationClass)) != NULL, @"Routable view(%@) is not registered with any view router.",destinationClass);
    }
}

+ (void)_checkAllRouters {
    for (Class class in _routerClasses) {
        [class _didFinishRegistration];
    }
    
    NSDictionary<Class, NSSet *> *destinationToRoutersMap = (__bridge NSDictionary *)self.destinationToRoutersMap;
    [destinationToRoutersMap enumerateKeysAndObjectsUsingBlock:^(Class  _Nonnull key, NSSet * _Nonnull obj, BOOL * _Nonnull stop) {
        [obj enumerateObjectsUsingBlock:^(id  _Nonnull obj, BOOL * _Nonnull stop) {
            if (obj == [obj class]) {
                return;
            }
            NSAssert([obj isKindOfClass:[ZIKViewRoute class]], @"The object is either a ZIKViewRouter class or a ZIKViewRoute");
            ZIKViewRoute *route = obj;
            if (ZIKRouter_classIsSubclassOfClass(key, [XXView class])) {
                NSAssert1([route supportRouteType:ZIKViewRouteTypeAddAsSubview] || [route supportRouteType:ZIKViewRouteTypeCustom], @"If the destination is UIView/NSView type, the router (%@) must set supportedRouteTypes and support ZIKViewRouteTypeAddAsSubview or ZIKViewRouteTypeCustom.", route);
            }
            if ([route supportRouteType:ZIKViewRouteTypeCustom]) {
                NSAssert1(route.canPerformCustomRouteBlock != nil, @"The route (%@) supports ZIKViewRouteTypeCustom, but missing  -canPerformCustomRoute.", route);
                NSAssert1(route.performCustomRouteBlock != nil, @"The route (%@) supports ZIKViewRouteTypeCustom, but missing  -performCustomRoute.", route);
            }
        }];
    }];
}

+ (void)_checkAllRoutableProtocols {
    ZIKRouter_enumerateProtocolList(^(Protocol *protocol) {
        if (protocol) {
            [self _checkProtocol:protocol];
        }
    });
}

+ (void)_checkProtocol:(Protocol *)protocol {
    if (protocol_conformsToProtocol(protocol, @protocol(ZIKViewRoutable)) &&
        protocol != @protocol(ZIKViewRoutable)) {
        ZIKRouterType *routerType = [self routerToDestination:protocol];
        NSCAssert1(routerType, @"Declared view protocol(%@) is not registered with any router class!",NSStringFromProtocol(protocol));
        id router = routerType.routerClass;
        if (router == nil) {
            router = routerType.route;
        }
        CFSetRef viewsRef = CFDictionaryGetValue(self._check_routerToDestinationsMap, (__bridge const void *)(router));
        NSSet *views = (__bridge NSSet *)(viewsRef);
        NSCAssert1(views.count > 0, @"Router(%@) didn't registered with any viewClass", router);
        for (Class viewClass in views) {
            NSCAssert3([viewClass conformsToProtocol:protocol], @"Router(%@)'s viewClass(%@) should conform to registered protocol(%@)",router, viewClass, NSStringFromProtocol(protocol));
        }
    } else if (protocol_conformsToProtocol(protocol, @protocol(ZIKViewModuleRoutable)) &&
               protocol != @protocol(ZIKViewModuleRoutable)) {
        ZIKRouterType *routerType = [self routerToModule:protocol];
        NSCAssert1(routerType, @"Declared routable config protocol(%@) is not registered with any router class!",NSStringFromProtocol(protocol));
        ZIKViewRouteConfiguration *config = [routerType defaultRouteConfiguration];
        NSCAssert3([config conformsToProtocol:protocol], @"Router(%@)'s default ZIKViewRouteConfiguration(%@) should conform to registered config protocol(%@)",routerType, [config class], NSStringFromProtocol(protocol));
    }
}
#endif

#pragma mark Check Override

#if ZIKROUTER_CHECK

+ (void)registerDestination:(Class)destinationClass router:(Class)routerClass {
    NSParameterAssert([routerClass isSubclassOfClass:[ZIKViewRouter class]]);
    if (ZIKRouter_classIsSubclassOfClass(destinationClass, [XXView class])) {
        NSAssert1([routerClass supportRouteType:ZIKViewRouteTypeAddAsSubview] || [routerClass supportRouteType:ZIKViewRouteTypeCustom], @"If the destination is UIView/NSView type, the router (%@) must override +supportedRouteTypes and support ZIKViewRouteTypeAddAsSubview or ZIKViewRouteTypeCustom.", routerClass);
        if ([routerClass supportRouteType:ZIKViewRouteTypeCustom]) {
            NSAssert1(ZIKRouter_classSelfImplementingMethod(routerClass, @selector(canPerformCustomRoute), false), @"The router (%@) supports ZIKViewRouteTypeCustom, but doesn't override -canPerformCustomRoute.", routerClass);
            NSAssert1(ZIKRouter_classSelfImplementingMethod(routerClass, @selector(performCustomRouteOnDestination:fromSource:configuration:), false), @"The router (%@) supports ZIKViewRouteTypeCustom, but doesn't override -performCustomRouteOnDestination:fromSource:configuration:.", routerClass);
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
