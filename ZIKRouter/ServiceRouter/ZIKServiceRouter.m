//
//  ZIKServiceRouter.m
//  ZIKRouter
//
//  Created by zuik on 2017/8/9.
//  Copyright © 2017 zuik. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "ZIKServiceRouter.h"
#import "ZIKRouterInternal.h"
#import "ZIKServiceRouterPrivate.h"
#import <objc/runtime.h>
#import <UIKit/UIKit.h>
#import "ZIKRouterRuntimeHelper.h"

NSNotificationName kZIKServiceRouterRegisterCompleteNotification = @"kZIKServiceRouterRegisterCompleteNotification";
NSString *const kZIKServiceRouterErrorDomain = @"ZIKServiceRouterErrorDomain";

static BOOL _isLoadFinished = NO;

static CFMutableDictionaryRef g_serviceProtocolToRouterMap;
static CFMutableDictionaryRef g_configProtocolToRouterMap;
static CFMutableDictionaryRef g_serviceToRoutersMap;
static CFMutableDictionaryRef g_serviceToDefaultRouterMap;
static CFMutableDictionaryRef g_serviceToExclusiveRouterMap;
#if ZIKSERVICEROUTER_CHECK
static CFMutableDictionaryRef _check_routerToServicesMap;
#endif

static ZIKServiceRouteGlobalErrorHandler g_globalErrorHandler;
static dispatch_semaphore_t g_globalErrorSema;

@interface ZIKServiceRouter () <ZIKRouterProtocol>

@end

//#pragma clang diagnostic push
//#pragma clang diagnostic ignored "-Wincomplete-implementation"
//#pragma clang diagnostic ignored "-Wobjc-designated-initializers"

@implementation ZIKServiceRouter

//#pragma clang diagnostic pop

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ZIKRouter_replaceMethodWithMethod([UIApplication class], @selector(setDelegate:),
                                          self, @selector(ZIKServiceRouter_hook_setDelegate:));
        ZIKRouter_replaceMethodWithMethodType([UIStoryboard class], @selector(storyboardWithName:bundle:), true, self, @selector(ZIKServiceRouter_hook_storyboardWithName:bundle:), true);
    });
}

+ (void)setup {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _initializeZIKServiceRouter();
    });
}

+ (void)ZIKServiceRouter_hook_setDelegate:(id<UIApplicationDelegate>)delegate {
    [ZIKServiceRouter setup];
    [self ZIKServiceRouter_hook_setDelegate:delegate];
}

+ (UIStoryboard *)ZIKServiceRouter_hook_storyboardWithName:(NSString *)name bundle:(nullable NSBundle *)storyboardBundleOrNil {
    [ZIKServiceRouter setup];
    return [self ZIKServiceRouter_hook_storyboardWithName:name bundle:storyboardBundleOrNil];
}

void _initializeZIKServiceRouter() {
    g_globalErrorSema = dispatch_semaphore_create(1);
    if (!g_serviceProtocolToRouterMap) {
        g_serviceProtocolToRouterMap = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, NULL, NULL);
    }
    if (!g_configProtocolToRouterMap) {
        g_configProtocolToRouterMap = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, NULL, NULL);
    }
#if ZIKSERVICEROUTER_CHECK
    NSMutableSet *routableServices = [NSMutableSet set];
    if (!_check_routerToServicesMap) {
        _check_routerToServicesMap = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, NULL, &kCFTypeDictionaryValueCallBacks);
    }
#endif
    Class ZIKServiceRouterClass = [ZIKServiceRouter class];
    ZIKRouter_enumerateClassList(^(__unsafe_unretained Class class) {
#if ZIKSERVICEROUTER_CHECK
        if (class_conformsToProtocol(class, @protocol(ZIKRoutableService))) {
            [routableServices addObject:class];
        }
#endif
        if (ZIKRouter_classIsSubclassOfClass(class, ZIKServiceRouterClass)) {
            IMP registerIMP = class_getMethodImplementation(objc_getMetaClass(class_getName(class)), @selector(registerRoutableDestination));
            NSCAssert1(({
                BOOL valid = YES;
                Class superClass = class_getSuperclass(class);
                if (superClass == ZIKServiceRouterClass || ZIKRouter_classIsSubclassOfClass(superClass, ZIKServiceRouterClass)) {
                    IMP superClassIMP = class_getMethodImplementation(objc_getMetaClass(class_getName(superClass)), @selector(registerRoutableDestination));
                    valid = (registerIMP != superClassIMP);
                }
                valid;
            }), @"Router(%@) must override +registerRoutableDestination to register destination.",class);
            NSCAssert1(({
                BOOL valid = YES;
                if (!ZIKRouter_classIsSubclassOfClass(class, NSClassFromString(@"ZIKServiceRouteAdapter"))) {
                    IMP destinationIMP = class_getMethodImplementation(objc_getMetaClass(class_getName(class)), @selector(destinationWithConfiguration:));
                    Class superClass = class_getSuperclass(class);
                    if (superClass == ZIKServiceRouterClass || ZIKRouter_classIsSubclassOfClass(superClass, ZIKServiceRouterClass)) {
                        IMP superClassIMP = class_getMethodImplementation(objc_getMetaClass(class_getName(superClass)), @selector(destinationWithConfiguration:));
                        valid = (destinationIMP != superClassIMP);
                    }
                }
                valid;
            }), @"Router(%@) must override -destinationWithConfiguration: to return destination.",class);
            void(*registerFunc)(Class, SEL) = (void(*)(Class,SEL))registerIMP;
            if (registerFunc) {
                registerFunc(class,@selector(registerRoutableDestination));
            }
#if ZIKSERVICEROUTER_CHECK
            CFMutableSetRef services = (CFMutableSetRef)CFDictionaryGetValue(_check_routerToServicesMap, (__bridge const void *)(class));
            NSSet *serviceSet = (__bridge NSSet *)(services);
            NSCAssert2(serviceSet.count > 0 || ZIKRouter_classIsSubclassOfClass(class, NSClassFromString(@"ZIKServiceRouteAdapter")) || class == NSClassFromString(@"ZIKServiceRouteAdapter"), @"This router class(%@) was not resgistered with any service class. Use +registerService: to register service in Router(%@)'s +registerRoutableDestination.",class,class);
#endif
        }
    });
#if ZIKSERVICEROUTER_CHECK
    for (Class serviceClass in routableServices) {
        NSCAssert1(CFDictionaryGetValue(g_serviceToDefaultRouterMap, (__bridge const void *)(serviceClass)) != NULL, @"Routable service(%@) is not registered with any service router.",serviceClass);
    }
    ZIKRouter_enumerateProtocolList(^(Protocol *protocol) {
        if (protocol_conformsToProtocol(protocol, @protocol(ZIKServiceRoutable)) &&
            protocol != @protocol(ZIKServiceRoutable)) {
            Class routerClass = (Class)CFDictionaryGetValue(g_serviceProtocolToRouterMap, (__bridge const void *)(protocol));
            NSCAssert1(routerClass, @"Declared service protocol(%@) is not registered with any router class!",NSStringFromProtocol(protocol));
            
            CFSetRef servicesRef = CFDictionaryGetValue(_check_routerToServicesMap, (__bridge const void *)(routerClass));
            NSSet *services = (__bridge NSSet *)(servicesRef);
            NSCAssert1(services.count > 0, @"Router(%@) didn't registered with any serviceClass", routerClass);
            for (Class serviceClass in services) {
                NSCAssert3([serviceClass conformsToProtocol:protocol], @"Router(%@)'s serviceClass(%@) should conform to registered protocol(%@)",routerClass, serviceClass, NSStringFromProtocol(protocol));
            }
        } else if (protocol_conformsToProtocol(protocol, @protocol(ZIKServiceModuleRoutable)) &&
                   protocol != @protocol(ZIKServiceModuleRoutable)) {
            Class routerClass = (Class)CFDictionaryGetValue(g_configProtocolToRouterMap, (__bridge const void *)(protocol));
            NSCAssert1(routerClass, @"Declared service config protocol(%@) is not registered with any router class!",NSStringFromProtocol(protocol));
            ZIKRouteConfiguration *config = [routerClass defaultRouteConfiguration];
            NSCAssert3([config conformsToProtocol:protocol], @"Router(%@)'s default ZIKRouteConfiguration(%@) should conform to registered config protocol(%@)",routerClass, [config class], NSStringFromProtocol(protocol));
        }
    });
#endif
    
    _isLoadFinished = YES;
    [[NSNotificationCenter defaultCenter] postNotificationName:kZIKServiceRouterRegisterCompleteNotification object:nil];
}

_Nullable Class _ZIKServiceRouterToService(Protocol *serviceProtocol) {
    NSCParameterAssert(serviceProtocol);
    NSCAssert(g_serviceProtocolToRouterMap, @"Didn't register any protocol yet.");
    NSCAssert(_isLoadFinished, @"Only get router after app did finish launch.");
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!g_serviceProtocolToRouterMap) {
            g_serviceProtocolToRouterMap = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, NULL, NULL);
        }
    });
    if (!serviceProtocol) {
//        [ZIKServiceRouter _callbackError_invalidProtocolWithAction:@selector(init) errorDescription:@"ZIKServiceRouter.toService() serviceProtocol is nil"];
        NSCAssert1(NO, @"ZIKServiceRouter.toService() serviceProtocol is nil. callStackSymbols: %@",[NSThread callStackSymbols]);
        return nil;
    }
    
    Class routerClass = CFDictionaryGetValue(g_serviceProtocolToRouterMap, (__bridge const void *)(serviceProtocol));
    if (routerClass) {
        return routerClass;
    }
//    [ZIKServiceRouter _callbackError_invalidProtocolWithAction:@selector(init)
//                                             errorDescription:@"Didn't find service router for service protocol: %@, this protocol was not registered.",serviceProtocol];
    NSCAssert1(NO, @"Didn't find service router for service protocol: %@, this protocol was not registered.",serviceProtocol);
    return nil;
}

_Nullable Class _ZIKServiceRouterToModule(Protocol *configProtocol) {
    NSCParameterAssert(configProtocol);
    NSCAssert(g_configProtocolToRouterMap, @"Didn't register any protocol yet.");
    NSCAssert(_isLoadFinished, @"Only get router after app did finish launch.");
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!g_configProtocolToRouterMap) {
            g_configProtocolToRouterMap = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, NULL, NULL);
        }
    });
    if (!configProtocol) {
//        [ZIKServiceRouter _callbackError_invalidProtocolWithAction:@selector(init) errorDescription:@"ZIKServiceRouter.toModule() configProtocol is nil"];
        NSCAssert1(NO, @"ZIKServiceRouter.toModule() configProtocol is nil. callStackSymbols: %@",[NSThread callStackSymbols]);
        return nil;
    }
    
    Class routerClass = CFDictionaryGetValue(g_configProtocolToRouterMap, (__bridge const void *)(configProtocol));
    if (routerClass) {
        return routerClass;
    }
    
//    [ZIKServiceRouter _callbackError_invalidProtocolWithAction:@selector(init)
//                                             errorDescription:@"Didn't find service router for config protocol: %@, this protocol was not registered.",configProtocol];
    NSCAssert1(NO, @"Didn't find service router for config protocol: %@, this protocol was not registered.",configProtocol);
    return nil;
}

- (void)performWithConfiguration:(__kindof ZIKServiceRouteConfiguration *)configuration {
    [[self class] increaseRecursiveDepth];
    if ([[self class] _validateInfiniteRecursion] == NO) {
        [self _callbackError_infiniteRecursionWithAction:@selector(performRoute) errorDescription:@"Infinite recursion for performing route detected. Recursive call stack:\n%@",[NSThread callStackSymbols]];
        [[self class] decreaseRecursiveDepth];
        return;
    }
    [super performWithConfiguration:configuration];
    [[self class] decreaseRecursiveDepth];
}

#pragma mark ZIKRouterProtocol

+ (void)registerRoutableDestination {
    NSAssert2(NO, @"subclass(%@) must implement +registerRoutableDestination to register destination with %@",self,self);
}

- (void)performRouteOnDestination:(id)destination configuration:(__kindof ZIKServiceRouteConfiguration *)configuration {
    [self beginPerformRoute];
    
    if (!destination) {
        [self endPerformRouteWithError:[[self class] errorWithCode:ZIKServiceRouteErrorServiceUnavailable localizedDescriptionFormat:@"Router(%@) returns nil for destination, you can't use this service now. Maybe your configuration is invalid (%@), or there is a bug in the router.",self,configuration]];
        return;
    }
    if (configuration.prepareForRoute) {
        configuration.prepareForRoute(destination);
    }
    if (configuration.routeCompletion) {
        configuration.routeCompletion(destination);
    }
    [self endPerformRouteWithSuccess];
}

#pragma mark State

- (void)beginPerformRoute {
    NSAssert(self.state != ZIKRouterStateRouting, @"state should not be routing when begin to route.");
    [self notifyRouteState:ZIKRouterStateRouting];
}

- (void)endPerformRouteWithSuccess {
    NSAssert(self.state == ZIKRouterStateRouting, @"state should be routing when end to route.");
    [self notifyRouteState:ZIKRouterStateRouted];
    [self notifySuccessWithAction:@selector(performRoute)];
}

- (void)endPerformRouteWithError:(NSError *)error {
    NSAssert(self.state == ZIKRouterStateRouting, @"state should be routing when end to route.");
    [self notifyRouteState:ZIKRouterStateRouteFailed];
    [self notifyError:error routeAction:@selector(performRoute)];
}

- (void)beginRemoveRoute {
    NSAssert(self.state != ZIKRouterStateRemoving, @"state should not be removing when begin remove route.");
    [self notifyRouteState:ZIKRouterStateRemoving];
}

- (void)endRemoveRouteWithSuccessOnDestination:(id)destination {
    NSAssert(self.state == ZIKRouterStateRemoving, @"state should be removing when end remove route.");
    [self notifyRouteState:ZIKRouterStateRemoved];
}

- (void)endRemoveRouteWithError:(NSError *)error {
    NSAssert(self.state == ZIKRouterStateRemoving, @"state should be removing when end remove route.");
    [self notifyRouteState:ZIKRouterStateRemoveFailed];
    [self notifyError:error routeAction:@selector(removeRoute)];
}

+ (__kindof ZIKRouteConfiguration *)defaultRouteConfiguration {
    return [ZIKServiceRouteConfiguration new];
}

+ (__kindof ZIKRouteConfiguration *)defaultRemoveConfiguration {
    return [ZIKRouteConfiguration new];
}

- (NSString *)errorDomain {
    return kZIKServiceRouterErrorDomain;
}

+ (BOOL)completeSynchronously {
    return YES;
}

#pragma mark Validate

+ (BOOL)_validateInfiniteRecursion {
    NSUInteger maxRecursiveDepth = 200;
    if ([self recursiveDepth] > maxRecursiveDepth) {
        return NO;
    }
    return YES;
}

#pragma mark Error Handle

+ (void)setGlobalErrorHandler:(ZIKServiceRouteGlobalErrorHandler)globalErrorHandler {
    dispatch_semaphore_wait(g_globalErrorSema, DISPATCH_TIME_FOREVER);
    
    g_globalErrorHandler = globalErrorHandler;
    
    dispatch_semaphore_signal(g_globalErrorSema);
}

- (void)_callbackErrorWithAction:(SEL)routeAction error:(NSError *)error {
    [[self class] _callbackGlobalErrorHandlerWithRouter:self action:routeAction error:error];
    [super notifyError:error routeAction:routeAction];
}

+ (void)_callbackGlobalErrorHandlerWithRouter:(__kindof ZIKServiceRouter *)router action:(SEL)action error:(NSError *)error {
    dispatch_semaphore_wait(g_globalErrorSema, DISPATCH_TIME_FOREVER);
    
    ZIKServiceRouteGlobalErrorHandler errorHandler = g_globalErrorHandler;
    if (errorHandler) {
        errorHandler(router, action, error);
    } else {
#ifdef DEBUG
        NSLog(@"❌ZIKServiceRouter Error: router's action (%@) catch error: (%@),\nrouter:(%@)", NSStringFromSelector(action), error,router);
#endif
    }
    
    dispatch_semaphore_signal(g_globalErrorSema);
}

- (void)_callbackError_infiniteRecursionWithAction:(SEL)action errorDescription:(NSString *)format ,... {
    va_list argList;
    va_start(argList, format);
    NSString *description = [[NSString alloc] initWithFormat:format arguments:argList];
    va_end(argList);
    [self _callbackErrorWithAction:action error:[[self class] errorWithCode:ZIKServiceRouteErrorInfiniteRecursion localizedDescription:description]];
}

#pragma mark Getter/Setter

+ (NSUInteger)recursiveDepth {
    NSNumber *depth = objc_getAssociatedObject(self, @"ZIKServiceRouter_recursiveDepth");
    if ([depth isKindOfClass:[NSNumber class]]) {
        return [depth unsignedIntegerValue];
    }
    return 0;
}

+ (void)setRecursiveDepth:(NSUInteger)depth {
    objc_setAssociatedObject(self, @"ZIKServiceRouter_recursiveDepth", @(depth), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

+ (void)increaseRecursiveDepth {
    NSUInteger depth = [self recursiveDepth];
    [self setRecursiveDepth:++depth];
}

+ (void)decreaseRecursiveDepth {
    NSUInteger depth = [self recursiveDepth];
    [self setRecursiveDepth:--depth];
}

@end

@implementation ZIKServiceRouter (Factory)

+ (nullable id)makeDestinationWithPreparation:(void(^ _Nullable)(id destination))prepare {
    NSAssert(self != [ZIKServiceRouter class], @"Only get destination from router subclass");
    NSAssert1([self completeSynchronously] == YES, @"The router (%@) should return the destination Synchronously when use +destinationForConfigure",self);
    ZIKServiceRouter *router = [[self alloc] initWithConfiguring:(void(^)(ZIKRouteConfiguration*))^(ZIKServiceRouteConfiguration * _Nonnull config) {
        if (prepare) {
            config.prepareForRoute = ^(id  _Nonnull destination) {
                prepare(destination);
            };
        }
    } removing:nil];
    [router performRoute];
    id destination = router.destination;
    return destination;
}

+ (nullable id)makeDestination {
    return [self makeDestinationWithPreparation:nil];
}

@end

@implementation ZIKServiceRouter (Register)

+ (void)registerService:(Class)serviceClass {
    Class routerClass = self;
    NSParameterAssert(serviceClass);
    NSParameterAssert([serviceClass conformsToProtocol:@protocol(ZIKRoutableService)]);
    NSParameterAssert([routerClass isSubclassOfClass:[ZIKServiceRouter class]]);
    NSAssert(!_isLoadFinished, @"Only register in +registerRoutableDestination.");
    NSAssert([NSThread isMainThread], @"Call in main thread for thread safety.");
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!g_serviceToDefaultRouterMap) {
            g_serviceToDefaultRouterMap = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, NULL, NULL);
        }
        if (!g_serviceToRoutersMap) {
            g_serviceToRoutersMap = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, NULL, &kCFTypeDictionaryValueCallBacks);
        }
#if ZIKSERVICEROUTER_CHECK
        if (!_check_routerToServicesMap) {
            _check_routerToServicesMap = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, NULL, &kCFTypeDictionaryValueCallBacks);
        }
#endif
    });
    NSAssert(!g_serviceToExclusiveRouterMap ||
             (g_serviceToExclusiveRouterMap && !CFDictionaryGetValue(g_serviceToExclusiveRouterMap, (__bridge const void *)(serviceClass))), @"There is a registered exclusive router, can't use another router for this serviceClass.");
    
    if (!CFDictionaryContainsKey(g_serviceToDefaultRouterMap, (__bridge const void *)(serviceClass))) {
        CFDictionarySetValue(g_serviceToDefaultRouterMap, (__bridge const void *)(serviceClass), (__bridge const void *)(routerClass));
    }
    CFMutableSetRef routers = (CFMutableSetRef)CFDictionaryGetValue(g_serviceToRoutersMap, (__bridge const void *)(serviceClass));
    if (routers == NULL) {
        routers = CFSetCreateMutable(kCFAllocatorDefault, 0, NULL);
        CFDictionarySetValue(g_serviceToRoutersMap, (__bridge const void *)(serviceClass), routers);
    }
    CFSetAddValue(routers, (__bridge const void *)(routerClass));
    
#if ZIKSERVICEROUTER_CHECK
    CFMutableSetRef services = (CFMutableSetRef)CFDictionaryGetValue(_check_routerToServicesMap, (__bridge const void *)(routerClass));
    if (services == NULL) {
        services = CFSetCreateMutable(kCFAllocatorDefault, 0, NULL);
        CFDictionarySetValue(_check_routerToServicesMap, (__bridge const void *)(routerClass), services);
    }
    CFSetAddValue(services, (__bridge const void *)(serviceClass));
#endif
}

+ (void)registerExclusiveService:(Class)serviceClass {
    Class routerClass = self;
    NSParameterAssert([serviceClass conformsToProtocol:@protocol(ZIKRoutableService)]);
    NSParameterAssert([routerClass isSubclassOfClass:[ZIKServiceRouter class]]);
    NSAssert(!_isLoadFinished, @"Only register in +registerRoutableDestination.");
    NSAssert([NSThread isMainThread], @"Call in main thread for thread safety.");
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!g_serviceToExclusiveRouterMap) {
            g_serviceToExclusiveRouterMap = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, NULL, NULL);
        }
        if (!g_serviceToDefaultRouterMap) {
            g_serviceToDefaultRouterMap = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, NULL, NULL);
        }
        if (!g_serviceToRoutersMap) {
            g_serviceToRoutersMap = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, NULL, &kCFTypeDictionaryValueCallBacks);
        }
#if ZIKSERVICEROUTER_CHECK
        if (!_check_routerToServicesMap) {
            _check_routerToServicesMap = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, NULL, &kCFTypeDictionaryValueCallBacks);
        }
#endif
    });
    NSAssert(!CFDictionaryGetValue(g_serviceToExclusiveRouterMap, (__bridge const void *)(serviceClass)), @"There is already a registered exclusive router for this serviceClass, you can only specific one exclusive router for each serviceClass. Choose the one used inside service.");
    NSAssert(!CFDictionaryGetValue(g_serviceToDefaultRouterMap, (__bridge const void *)(serviceClass)), @"serviceClass already registered with another router, check and remove them. You shall only use the exclusive router for this serviceClass.");
    NSAssert(!CFDictionaryContainsKey(g_serviceToRoutersMap, (__bridge const void *)(serviceClass)) ||
             (CFDictionaryContainsKey(g_serviceToRoutersMap, (__bridge const void *)(serviceClass)) &&
              !CFSetContainsValue(
                                  (CFMutableSetRef)CFDictionaryGetValue(g_serviceToRoutersMap, (__bridge const void *)(serviceClass)),
                                  (__bridge const void *)(routerClass)
                                  ))
             , @"serviceClass already registered with another router, check and remove them. You shall only use the exclusive router for this serviceClass.");
    
    CFDictionarySetValue(g_serviceToExclusiveRouterMap, (__bridge const void *)(serviceClass), (__bridge const void *)(routerClass));
    CFDictionarySetValue(g_serviceToDefaultRouterMap, (__bridge const void *)(serviceClass), (__bridge const void *)(routerClass));
    CFMutableSetRef routers = (CFMutableSetRef)CFDictionaryGetValue(g_serviceToRoutersMap, (__bridge const void *)(serviceClass));
    if (routers == NULL) {
        routers = CFSetCreateMutable(kCFAllocatorDefault, 0, NULL);
        CFDictionarySetValue(g_serviceToRoutersMap, (__bridge const void *)(serviceClass), routers);
    }
    CFSetAddValue(routers, (__bridge const void *)(routerClass));
    
#if ZIKSERVICEROUTER_CHECK
    CFMutableSetRef services = (CFMutableSetRef)CFDictionaryGetValue(_check_routerToServicesMap, (__bridge const void *)(routerClass));
    if (services == NULL) {
        services = CFSetCreateMutable(kCFAllocatorDefault, 0, NULL);
        CFDictionarySetValue(_check_routerToServicesMap, (__bridge const void *)(routerClass), services);
    }
    CFSetAddValue(services, (__bridge const void *)(serviceClass));
#endif
}

+ (void)registerServiceProtocol:(Protocol *)serviceProtocol {
    Class routerClass = self;
    NSParameterAssert([routerClass isSubclassOfClass:[ZIKServiceRouter class]]);
    NSAssert(!_isLoadFinished, @"Only register in +registerRoutableDestination.");
    NSAssert([NSThread isMainThread], @"Call in main thread for thread safety.");
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!g_serviceProtocolToRouterMap) {
            g_serviceProtocolToRouterMap = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, NULL, NULL);
        }
    });
    NSAssert(!CFDictionaryGetValue(g_serviceProtocolToRouterMap, (__bridge const void *)(serviceProtocol)) ||
             (Class)CFDictionaryGetValue(g_serviceProtocolToRouterMap, (__bridge const void *)(serviceProtocol)) == routerClass
             , @"Protocol already registered by another router, serviceProtocol should only be used by this routerClass.");
    
    CFDictionarySetValue(g_serviceProtocolToRouterMap, (__bridge const void *)(serviceProtocol), (__bridge const void *)(routerClass));
}

+ (void)registerModuleProtocol:(Protocol *)configProtocol {
    Class routerClass = self;
    NSParameterAssert([routerClass isSubclassOfClass:[ZIKServiceRouter class]]);
    NSAssert([[routerClass defaultRouteConfiguration] conformsToProtocol:configProtocol], @"configProtocol should be conformed by this router's defaultRouteConfiguration.");
    NSAssert(!_isLoadFinished, @"Only register in +registerRoutableDestination.");
    NSAssert([NSThread isMainThread], @"Call in main thread for thread safety.");
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!g_configProtocolToRouterMap) {
            g_configProtocolToRouterMap = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, NULL, NULL);
        }
    });
    NSAssert(!CFDictionaryGetValue(g_configProtocolToRouterMap, (__bridge const void *)(configProtocol)) ||
             (Class)CFDictionaryGetValue(g_configProtocolToRouterMap, (__bridge const void *)(configProtocol)) == routerClass
             , @"Protocol already registered by another router, configProtocol should only be used by this routerClass.");
    
    CFDictionarySetValue(g_configProtocolToRouterMap, (__bridge const void *)(configProtocol), (__bridge const void *)(routerClass));
}

_Nullable Class _swift_ZIKServiceRouterToService(id serviceProtocol) {
    return _ZIKServiceRouterToService(serviceProtocol);
}

extern _Nullable Class _swift_ZIKServiceRouterToModule(id configProtocol) {
    return _ZIKServiceRouterToModule(configProtocol);
}

@end

@implementation ZIKServiceRouter (Discover)

+ (Class(^)(Protocol *))toService {
    return ^(Protocol *serviceProtocol) {
        return _ZIKServiceRouterToService(serviceProtocol);
    };
}

+ (Class(^)(Protocol *))toModule {
    return ^(Protocol *configProtocol) {
        return _ZIKServiceRouterToModule(configProtocol);
    };
}

@end

@implementation ZIKServiceRouter (Private)

+ (BOOL)_isLoadFinished {
    return _isLoadFinished;
}

+ (void)_swift_registerServiceProtocol:(id)serviceProtocol {
    NSCParameterAssert(ZIKRouter_isObjcProtocol(serviceProtocol));
    [self registerServiceProtocol:serviceProtocol];
}

+ (void)_swift_registerConfigProtocol:(id)configProtocol {
    NSCParameterAssert(ZIKRouter_isObjcProtocol(configProtocol));
    [self registerModuleProtocol:configProtocol];
}

+ (_Nullable Class)validateRegisteredServiceClasses:(ZIKServiceClassValidater)handler {
#if ZIKSERVICEROUTER_CHECK
    Class routerClass = self;
    CFMutableSetRef services = (CFMutableSetRef)CFDictionaryGetValue(_check_routerToServicesMap, (__bridge const void *)(routerClass));
    __block Class badClass = nil;
    [(__bridge NSSet *)(services) enumerateObjectsUsingBlock:^(Class  _Nonnull serviceClass, BOOL * _Nonnull stop) {
        if (handler) {
            if (!handler(serviceClass)) {
                badClass = serviceClass;
                *stop = YES;
            }
        }
    }];
    return badClass;
#else
    return nil;
#endif
}

@end
