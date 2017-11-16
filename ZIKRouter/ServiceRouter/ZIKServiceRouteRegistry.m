//
//  ZIKServiceRouteRegistry.m
//  ZIKRouter
//
//  Created by zuik on 2017/11/16.
//  Copyright © 2017年 zuik. All rights reserved.
//

#import "ZIKServiceRouteRegistry.h"
#import "ZIKServiceRouterInternal.h"
#import "ZIKRouterRuntimeHelper.h"
#import <objc/runtime.h>
#import <UIKit/UIKit.h>

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

@implementation ZIKServiceRouteRegistry

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
        NSCAssert1(({
            BOOL valid = YES;
            Class superClass = class_getSuperclass(class);
            if (superClass == ZIKServiceRouterClass || ZIKRouter_classIsSubclassOfClass(superClass, ZIKServiceRouterClass)) {
                IMP registerIMP = class_getMethodImplementation(objc_getMetaClass(class_getName(class)), @selector(registerRoutableDestination));
                IMP superClassIMP = class_getMethodImplementation(objc_getMetaClass(class_getName(superClass)), @selector(registerRoutableDestination));
                valid = (registerIMP != superClassIMP);
            }
            valid;
        }), @"Router(%@) must override +registerRoutableDestination to register destination.",class);
        NSCAssert1(({
            BOOL valid = YES;
            if (class != NSClassFromString(@"ZIKServiceRouteAdapter") && !ZIKRouter_classIsSubclassOfClass(class, NSClassFromString(@"ZIKServiceRouteAdapter"))) {
                IMP destinationIMP = class_getMethodImplementation(class, @selector(destinationWithConfiguration:));
                Class superClass = class_getSuperclass(class);
                if (superClass == ZIKServiceRouterClass || ZIKRouter_classIsSubclassOfClass(superClass, ZIKServiceRouterClass)) {
                    IMP superClassIMP = class_getMethodImplementation(superClass, @selector(destinationWithConfiguration:));
                    valid = (destinationIMP != superClassIMP);
                }
            }
            valid;
        }), @"Router(%@) must override -destinationWithConfiguration: to return destination.",class);
        [class registerRoutableDestination];
#if ZIKROUTER_CHECK
        CFMutableSetRef services = (CFMutableSetRef)CFDictionaryGetValue(self._check_routerToDestinationsMap, (__bridge const void *)(class));
        NSSet *serviceSet = (__bridge NSSet *)(services);
        NSCAssert2(serviceSet.count > 0 || ZIKRouter_classIsSubclassOfClass(class, NSClassFromString(@"ZIKServiceRouteAdapter")) || class == NSClassFromString(@"ZIKServiceRouteAdapter"), @"This router class(%@) was not resgistered with any service class. Use +registerService: to register service in Router(%@)'s +registerRoutableDestination.",class,class);
        [_routerClasses addObject:class];
#endif
    }
}

+ (void)didFinishEnumerateClasses {
#if ZIKROUTER_CHECK
    for (Class destinationClass in _routableDestinations) {
        NSCAssert1(CFDictionaryGetValue(self.destinationToDefaultRouterMap, (__bridge const void *)(destinationClass)) != NULL, @"Routable service (%@) is not registered with any view router.",destinationClass);
    }
#endif
}

+ (void)handleEnumerateProtocoles:(Protocol *)protocol {
#if ZIKROUTER_CHECK
    if (protocol_conformsToProtocol(protocol, @protocol(ZIKServiceRoutable)) &&
        protocol != @protocol(ZIKServiceRoutable)) {
        Class routerClass = (Class)CFDictionaryGetValue(self.destinationProtocolToRouterMap, (__bridge const void *)(protocol));
        NSCAssert1(routerClass, @"Declared service protocol(%@) is not registered with any router class!",NSStringFromProtocol(protocol));
        
        CFSetRef servicesRef = CFDictionaryGetValue(self._check_routerToDestinationsMap, (__bridge const void *)(routerClass));
        NSSet *services = (__bridge NSSet *)(servicesRef);
        NSCAssert1(services.count > 0, @"Router(%@) didn't registered with any serviceClass", routerClass);
        for (Class serviceClass in services) {
            NSCAssert3([serviceClass conformsToProtocol:protocol], @"Router(%@)'s serviceClass(%@) should conform to registered protocol(%@)",routerClass, serviceClass, NSStringFromProtocol(protocol));
        }
    } else if (protocol_conformsToProtocol(protocol, @protocol(ZIKServiceModuleRoutable)) &&
               protocol != @protocol(ZIKServiceModuleRoutable)) {
        Class routerClass = (Class)CFDictionaryGetValue(self.moduleConfigProtocolToRouterMap, (__bridge const void *)(protocol));
        NSCAssert1(routerClass, @"Declared service config protocol(%@) is not registered with any router class!",NSStringFromProtocol(protocol));
        ZIKRouteConfiguration *config = [routerClass defaultRouteConfiguration];
        NSCAssert3([config conformsToProtocol:protocol], @"Router(%@)'s default ZIKRouteConfiguration(%@) should conform to registered config protocol(%@)",routerClass, [config class], NSStringFromProtocol(protocol));
    }
#endif
}

+ (void)didFinishAutoRegistration {
#if ZIKROUTER_CHECK
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        for (Class class in _routerClasses) {
            [class _autoRegistrationDidFinished];
        }
    }];
#endif
}

@end
