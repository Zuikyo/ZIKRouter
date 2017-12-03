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
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "ZIKRouterRuntime.h"
#import "ZIKRouter.h"

static NSMutableSet<Class> *_registries;
static BOOL _autoRegistrationFinished = NO;

@interface ZIKRouteRegistry()
@property (nonatomic, class, readonly) NSMutableSet *registries;
@property (nonatomic, class) BOOL autoRegistrationFinished;
@end

@implementation ZIKRouteRegistry

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ZIKRouter_replaceMethodWithMethod([UIApplication class], @selector(setDelegate:),
                                          self, @selector(ZIKRouteRegistry_hook_setDelegate:));
        ZIKRouter_replaceMethodWithMethodType([UIStoryboard class], @selector(storyboardWithName:bundle:), true, self, @selector(ZIKRouteRegistry_hook_storyboardWithName:bundle:), true);
    });
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

+ (BOOL)autoRegistrationFinished {
    return _autoRegistrationFinished;
}

+ (void)setAutoRegistrationFinished:(BOOL)autoRegistrationFinished {
    _autoRegistrationFinished = autoRegistrationFinished;
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

+ (void)didFinishAutoRegistration {
    
}

+ (void)setup {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
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
            [registry didFinishAutoRegistration];
        }
        self.autoRegistrationFinished = YES;
    });
}

+ (void)ZIKRouteRegistry_hook_setDelegate:(id<UIApplicationDelegate>)delegate {
    [ZIKRouteRegistry setup];
    [self ZIKRouteRegistry_hook_setDelegate:delegate];
}

+ (UIStoryboard *)ZIKRouteRegistry_hook_storyboardWithName:(NSString *)name bundle:(nullable NSBundle *)storyboardBundleOrNil {
    [ZIKRouteRegistry setup];
    return [self ZIKRouteRegistry_hook_storyboardWithName:name bundle:storyboardBundleOrNil];
}

#pragma mark Discover

+ (_Nullable Class)routerToDestination:(Protocol *)destinationProtocol {
    NSParameterAssert(destinationProtocol);
    NSAssert(self.destinationProtocolToRouterMap != nil, @"Didn't register any protocol yet.");
    if (!destinationProtocol) {
        NSAssert1(NO, @"+routerToDestination: destinationProtocol is nil. callStackSymbols: %@",[NSThread callStackSymbols]);
        return nil;
    }
    return CFDictionaryGetValue(self.destinationProtocolToRouterMap, (__bridge const void *)(destinationProtocol));
}

+ (_Nullable Class)routerToModule:(Protocol *)configProtocol {
    NSParameterAssert(configProtocol);
    NSAssert(self.moduleConfigProtocolToRouterMap != nil, @"Didn't register any protocol yet.");
    if (!configProtocol) {
        NSAssert1(NO, @"+routerToModule: module configProtocol is nil. callStackSymbols: %@",[NSThread callStackSymbols]);
        return nil;
    }
    return CFDictionaryGetValue(self.moduleConfigProtocolToRouterMap, (__bridge const void *)(configProtocol));
}

#pragma mark Register

+ (void)registerDestination:(Class)destinationClass router:(Class)routerClass {
    NSParameterAssert([routerClass isSubclassOfClass:[ZIKRouter class]]);
    NSAssert3(!self.destinationToExclusiveRouterMap ||
              (self.destinationToExclusiveRouterMap && !CFDictionaryGetValue(self.destinationToExclusiveRouterMap, (__bridge const void *)(destinationClass))), @"There is a registered exclusive router (%@), can't register this router (%@) for this destinationClass (%@).",CFDictionaryGetValue(self.destinationToExclusiveRouterMap, (__bridge const void *)(destinationClass)), routerClass,destinationClass);
    
    CFMutableDictionaryRef destinationToDefaultRouterMap = self.destinationToDefaultRouterMap;
    if (!CFDictionaryContainsKey(destinationToDefaultRouterMap, (__bridge const void *)(destinationClass))) {
        CFDictionarySetValue(destinationToDefaultRouterMap, (__bridge const void *)(destinationClass), (__bridge const void *)(routerClass));
    }
    CFMutableDictionaryRef destinationToRoutersMap = self.destinationToRoutersMap;
    CFMutableSetRef routers = (CFMutableSetRef)CFDictionaryGetValue(destinationToRoutersMap, (__bridge const void *)(destinationClass));
    if (routers == NULL) {
        routers = CFSetCreateMutable(kCFAllocatorDefault, 0, NULL);
        CFDictionarySetValue(destinationToRoutersMap, (__bridge const void *)(destinationClass), routers);
    }
    CFSetAddValue(routers, (__bridge const void *)(routerClass));
    
#if ZIKROUTER_CHECK
    CFMutableSetRef destinations = (CFMutableSetRef)CFDictionaryGetValue(self._check_routerToDestinationsMap, (__bridge const void *)(routerClass));
    if (destinations == NULL) {
        destinations = CFSetCreateMutable(kCFAllocatorDefault, 0, NULL);
        CFDictionarySetValue(self._check_routerToDestinationsMap, (__bridge const void *)(routerClass), destinations);
    }
    CFSetAddValue(destinations, (__bridge const void *)(destinationClass));
#endif
}

+ (void)registerExclusiveDestination:(Class)destinationClass router:(Class)routerClass {
    NSParameterAssert([routerClass isSubclassOfClass:[ZIKRouter class]]);
    NSAssert2(!CFDictionaryGetValue(self.destinationToExclusiveRouterMap, (__bridge const void *)(destinationClass)), @"There is already a registered exclusive router (%@) for this destinationClass, can't register this router (%@). You can only specific one exclusive router for each destinationClass. Choose the router used as dependency injector.",CFDictionaryGetValue(self.destinationToExclusiveRouterMap, (__bridge const void *)(destinationClass)),routerClass);
    NSAssert2(!CFDictionaryGetValue(self.destinationToDefaultRouterMap, (__bridge const void *)(destinationClass)), @"destinationClass already registered with another router (%@), check and remove them. You shall only use this exclusive router (%@) for this destinationClass.",CFDictionaryGetValue(self.destinationToDefaultRouterMap, (__bridge const void *)(destinationClass)),routerClass);
    NSAssert(!CFDictionaryContainsKey(self.destinationToRoutersMap, (__bridge const void *)(destinationClass)) ||
              (CFDictionaryContainsKey(self.destinationToRoutersMap, (__bridge const void *)(destinationClass)) &&
               !CFSetContainsValue(
                                   (CFMutableSetRef)CFDictionaryGetValue(self.destinationToRoutersMap, (__bridge const void *)(destinationClass)),
                                   (__bridge const void *)(routerClass)
                                   ))
              , @"destinationClass already registered with another router, check and remove them. You shall only use the exclusive router for this destinationClass.");
    
    CFDictionarySetValue(self.destinationToExclusiveRouterMap, (__bridge const void *)(destinationClass), (__bridge const void *)(routerClass));
    CFDictionarySetValue(self.destinationToDefaultRouterMap, (__bridge const void *)(destinationClass), (__bridge const void *)(routerClass));
    
    CFMutableDictionaryRef destinationToRoutersMap = self.destinationToRoutersMap;
    CFMutableSetRef routers = (CFMutableSetRef)CFDictionaryGetValue(destinationToRoutersMap, (__bridge const void *)(destinationClass));
    if (routers == NULL) {
        routers = CFSetCreateMutable(kCFAllocatorDefault, 0, NULL);
        CFDictionarySetValue(destinationToRoutersMap, (__bridge const void *)(destinationClass), routers);
    }
    CFSetAddValue(routers, (__bridge const void *)(routerClass));
    
#if ZIKROUTER_CHECK
    CFMutableSetRef destinations = (CFMutableSetRef)CFDictionaryGetValue(self._check_routerToDestinationsMap, (__bridge const void *)(routerClass));
    if (destinations == NULL) {
        destinations = CFSetCreateMutable(kCFAllocatorDefault, 0, NULL);
        CFDictionarySetValue(self._check_routerToDestinationsMap, (__bridge const void *)(routerClass), destinations);
    }
    CFSetAddValue(destinations, (__bridge const void *)(destinationClass));
#endif
}

+ (void)registerDestinationProtocol:(Protocol *)destinationProtocol router:(Class)routerClass {
    NSParameterAssert([routerClass isSubclassOfClass:[ZIKRouter class]]);
    NSAssert3(!CFDictionaryGetValue(self.destinationProtocolToRouterMap, (__bridge const void *)(destinationProtocol)) ||
             (Class)CFDictionaryGetValue(self.destinationProtocolToRouterMap, (__bridge const void *)(destinationProtocol)) == routerClass
             , @"Destination protocol (%@) already registered with another router (%@), can't register with this router (%@). Same destination protocol should only be used by one routerClass.",NSStringFromProtocol(destinationProtocol),CFDictionaryGetValue(self.destinationProtocolToRouterMap, (__bridge const void *)(destinationProtocol)),routerClass);
    
    CFDictionarySetValue(self.destinationProtocolToRouterMap, (__bridge const void *)(destinationProtocol), (__bridge const void *)(routerClass));
#if ZIKROUTER_CHECK
    CFMutableSetRef destinationProtocols = (CFMutableSetRef)CFDictionaryGetValue(self._check_routerToDestinationProtocolsMap, (__bridge const void *)(routerClass));
    if (destinationProtocols == NULL) {
        destinationProtocols = CFSetCreateMutable(kCFAllocatorDefault, 0, NULL);
        CFDictionarySetValue(self._check_routerToDestinationProtocolsMap, (__bridge const void *)(routerClass), destinationProtocols);
    }
    CFSetAddValue(destinationProtocols, (__bridge const void *)(destinationProtocol));
#endif
}

+ (void)registerModuleProtocol:(Protocol *)configProtocol router:(Class)routerClass {
    NSParameterAssert([routerClass isSubclassOfClass:[ZIKRouter class]]);
    NSAssert3(!CFDictionaryGetValue(self.moduleConfigProtocolToRouterMap, (__bridge const void *)(configProtocol)) ||
             (Class)CFDictionaryGetValue(self.moduleConfigProtocolToRouterMap, (__bridge const void *)(configProtocol)) == routerClass
             , @"Module config protocol (%@) already registered with another router (%@), can't register with this router (%@). Same configProtocol should only be used by one routerClass.",NSStringFromProtocol(configProtocol),CFDictionaryGetValue(self.moduleConfigProtocolToRouterMap, (__bridge const void *)(configProtocol)),routerClass);
    
    CFDictionarySetValue(self.moduleConfigProtocolToRouterMap, (__bridge const void *)(configProtocol), (__bridge const void *)(routerClass));
}

@end
