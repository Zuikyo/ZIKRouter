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
#import <UIKit/UIKit.h>
#import "ZIKViewRouterInternal.h"

static CFMutableDictionaryRef _destinationProtocolToRouterMap;
static CFMutableDictionaryRef _moduleConfigProtocolToRouterMap;
static CFMutableDictionaryRef _destinationToRoutersMap;
static CFMutableDictionaryRef _destinationToDefaultRouterMap;
static CFMutableDictionaryRef _destinationToExclusiveRouterMap;
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
#if ZIKROUTER_CHECK
    _check_routerToDestinationsMap = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, NULL, &kCFTypeDictionaryValueCallBacks);
    _check_routerToDestinationProtocolsMap = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, NULL, &kCFTypeDictionaryValueCallBacks);
#endif
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
    static Class UIResponderClass;
    static Class UIViewControllerClass;
    static Class UIStoryboardSegueClass;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ZIKViewRouterClass = [ZIKViewRouter class];
        UIResponderClass = [UIResponder class];
        UIViewControllerClass = [UIViewController class];
        UIStoryboardSegueClass = [UIStoryboardSegue class];
    });
    if (ZIKRouter_classIsSubclassOfClass(class, UIResponderClass)) {
#if ZIKROUTER_CHECK
        if (class_conformsToProtocol(class, @protocol(ZIKRoutableView))) {
            NSCAssert(ZIKRouter_classIsSubclassOfClass(class, [UIView class]) || ZIKRouter_classIsSubclassOfClass(class, UIViewControllerClass), @"ZIKRoutableView only suppourt UIView and UIViewController");
            [_routableDestinations addObject:class];
        }
#endif
        
        if (ZIKRouter_classIsSubclassOfClass(class, UIViewControllerClass)) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
            //hook all UIViewController's -prepareForSegue:sender:
            ZIKRouter_replaceMethodWithMethod(class, @selector(prepareForSegue:sender:),
                                              ZIKViewRouterClass, @selector(ZIKViewRouter_hook_prepareForSegue:sender:));
        }
    }
    else if (ZIKRouter_classIsSubclassOfClass(class,UIStoryboardSegueClass)) {//hook all UIStoryboardSegue's -perform
        ZIKRouter_replaceMethodWithMethod(class, @selector(perform),
                                          ZIKViewRouterClass, @selector(ZIKViewRouter_hook_seguePerform));
#pragma clang diagnostic pop
    }
    else if (ZIKRouter_classIsSubclassOfClass(class, ZIKViewRouterClass)) {
        NSCAssert1(ZIKRouter_classSelfImplementingMethod(class, @selector(registerRoutableDestination), true), @"Router(%@) must override +registerRoutableDestination to register destination.",class);
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
    for (Class destinationClass in _routableDestinations) {
        NSCAssert1(CFDictionaryGetValue(self.destinationToDefaultRouterMap, (__bridge const void *)(destinationClass)) != NULL, @"Routable view(%@) is not registered with any view router.",destinationClass);
    }
#endif
}

+ (void)handleEnumerateProtocoles:(Protocol *)protocol {
#if ZIKROUTER_CHECK
    if (protocol_conformsToProtocol(protocol, @protocol(ZIKViewRoutable)) &&
        protocol != @protocol(ZIKViewRoutable)) {
        Class routerClass = (Class)CFDictionaryGetValue(self.destinationProtocolToRouterMap, (__bridge const void *)(protocol));
        NSCAssert1(routerClass, @"Declared view protocol(%@) is not registered with any router class!",NSStringFromProtocol(protocol));
        
        CFSetRef viewsRef = CFDictionaryGetValue(self._check_routerToDestinationsMap, (__bridge const void *)(routerClass));
        NSSet *views = (__bridge NSSet *)(viewsRef);
        NSCAssert1(views.count > 0, @"Router(%@) didn't registered with any viewClass", routerClass);
        for (Class viewClass in views) {
            NSCAssert3([viewClass conformsToProtocol:protocol], @"Router(%@)'s viewClass(%@) should conform to registered protocol(%@)",routerClass, viewClass, NSStringFromProtocol(protocol));
        }
    } else if (protocol_conformsToProtocol(protocol, @protocol(ZIKViewModuleRoutable)) &&
               protocol != @protocol(ZIKViewModuleRoutable)) {
        Class routerClass = (Class)CFDictionaryGetValue(self.moduleConfigProtocolToRouterMap, (__bridge const void *)(protocol));
        NSCAssert1(routerClass, @"Declared routable config protocol(%@) is not registered with any router class!",NSStringFromProtocol(protocol));
        ZIKViewRouteConfiguration *config = [routerClass defaultRouteConfiguration];
        NSCAssert3([config conformsToProtocol:protocol], @"Router(%@)'s default ZIKViewRouteConfiguration(%@) should conform to registered config protocol(%@)",routerClass, [config class], NSStringFromProtocol(protocol));
    }
#endif
}

+ (void)didFinishAutoRegistration {
#if ZIKROUTER_CHECK
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        for (Class class in _routerClasses) {
            [class _didFinishRegistration];
        }
    }];
#endif
}

+ (BOOL)isDestinationClass:(Class)destinationClass registeredWithRouter:(Class)routerClass {
    NSParameterAssert([routerClass isSubclassOfClass:[ZIKViewRouter class]]);
    CFDictionaryRef destinationToExclusiveRouterMap = ZIKViewRouteRegistry.destinationToExclusiveRouterMap;
    CFDictionaryRef destinationToRoutersMap = ZIKViewRouteRegistry.destinationToRoutersMap;
    Class UIResponderClass = [UIResponder class];
    while (destinationClass != UIResponderClass) {
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

@end
