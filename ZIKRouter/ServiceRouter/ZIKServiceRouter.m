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
#import "ZIKServiceRouterInternal.h"
#import "ZIKServiceRouteRegistry.h"
#import "ZIKRouteRegistryInternal.h"
#import "ZIKServiceRoute.h"
#import <objc/runtime.h>
#import "ZIKRouterRuntime.h"

ZIKRouteAction const ZIKRouteActionToService = @"ZIKRouteActionToService";
ZIKRouteAction const ZIKRouteActionToServiceModule = @"ZIKRouteActionToServiceModule";

static ZIKServiceRouteGlobalErrorHandler g_globalErrorHandler;
static dispatch_semaphore_t g_globalErrorSema;

@interface ZIKServiceRouter ()

@end

@implementation ZIKServiceRouter

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [ZIKRouteRegistry addRegistry:[ZIKServiceRouteRegistry class]];
        g_globalErrorSema = dispatch_semaphore_create(1);
    });
}

+ (void)_didFinishRegistration {
    
}

+ (BOOL)isAbstractRouter {
    return self == [ZIKServiceRouter class];
}

+ (void)registerRoutableDestination {
    NSAssert1([self isAbstractRouter], @"subclass(%@) must override +registerRoutableDestination to register destination.",self);
}

- (BOOL)shouldRemoveBeforePerform {
    return NO;
}

- (void)performRouteOnDestination:(id)destination configuration:(__kindof ZIKPerformRouteConfiguration *)configuration {
#if ZIKROUTER_CHECK
    if (destination) {
        [self _validateDestinationConformance:destination];
    }
#endif
    [self prepareDestinationForPerforming];
    [self endPerformRouteWithSuccess];
}

- (void)attachDestination:(id)destination {
#if ZIKROUTER_CHECK
    if (destination) {
        [self _validateDestinationConformance:destination];
    }
#endif
    [super attachDestination:destination];
}

- (void)prepareDestination:(id)destination configuration:(__kindof ZIKPerformRouteConfiguration *)configuration {
    NSAssert([self class] != [ZIKServiceRouter class], @"Prepare destination with its router.");
}

- (void)didFinishPrepareDestination:(id)destination configuration:(__kindof ZIKPerformRouteConfiguration *)configuration {
    NSAssert([self class] != [ZIKServiceRouter class], @"Prepare destination with its router.");
}

+ (__kindof ZIKPerformRouteConfiguration *)defaultRouteConfiguration {
    return [ZIKPerformRouteConfiguration new];
}

+ (__kindof ZIKRemoveRouteConfiguration *)defaultRemoveConfiguration {
    return [ZIKRemoveRouteConfiguration new];
}

+ (BOOL)canMakeDestinationSynchronously {
    return YES;
}

#pragma mark Validate

- (void)_validateDestinationConformance:(id)destination {
#if ZIKROUTER_CHECK
    Protocol *destinationProtocol;
    BOOL result = [ZIKServiceRouteRegistry validateDestinationConformance:[destination class] forRouter:self protocol:&destinationProtocol];
    NSAssert(result, @"Bad implementation in router (%@)'s -destinationWithConfiguration:. The destination (%@) doesn't conforms to registered service protocol (%@).",self, destination, NSStringFromProtocol(destinationProtocol));
#endif
}

#pragma mark Error Handle

+ (void)setGlobalErrorHandler:(ZIKServiceRouteGlobalErrorHandler)globalErrorHandler {
    dispatch_semaphore_wait(g_globalErrorSema, DISPATCH_TIME_FOREVER);
    g_globalErrorHandler = globalErrorHandler;
    dispatch_semaphore_signal(g_globalErrorSema);
}

+ (ZIKServiceRouteGlobalErrorHandler)globalErrorHandler {
    return g_globalErrorHandler;
}

+ (void)notifyGlobalErrorWithRouter:(nullable __kindof ZIKServiceRouter *)router action:(ZIKRouteAction)action error:(NSError *)error {
    void(^errorHandler)(__kindof ZIKServiceRouter *_Nullable router, ZIKRouteAction action, NSError *error) = self.globalErrorHandler;
    if (errorHandler) {
        errorHandler(router, action, error);
    } else {
#ifdef DEBUG
        NSLog(@"❌ZIKServiceRouter Error: router's action (%@) catch error: (%@),\nrouter:(%@)", action, error,router);
#endif
    }
}

@end

@implementation ZIKServiceRouter (Register)

+ (BOOL)isRegistrationFinished {
    return ZIKServiceRouteRegistry.registrationFinished;
}

+ (void)registerService:(Class)serviceClass {
    NSParameterAssert(serviceClass);
    NSParameterAssert([serviceClass conformsToProtocol:@protocol(ZIKRoutableService)]);
    NSAssert(!ZIKServiceRouteRegistry.registrationFinished, @"Only register in +registerRoutableDestination.");
    [ZIKServiceRouteRegistry registerDestination:serviceClass router:self];
}

+ (void)registerExclusiveService:(Class)serviceClass {
    NSParameterAssert([serviceClass conformsToProtocol:@protocol(ZIKRoutableService)]);
    NSAssert(!ZIKServiceRouteRegistry.registrationFinished, @"Only register in +registerRoutableDestination.");
    [ZIKServiceRouteRegistry registerExclusiveDestination:serviceClass router:self];
}

+ (void)registerServiceProtocol:(Protocol *)serviceProtocol {
    NSAssert(!ZIKServiceRouteRegistry.registrationFinished, @"Only register in +registerRoutableDestination.");
#if ZIKROUTER_CHECK
    NSAssert1(protocol_conformsToProtocol(serviceProtocol, @protocol(ZIKServiceRoutable)), @"Routable destination protocol %@ should conforms to ZIKServiceRoutable", NSStringFromProtocol(serviceProtocol));
#endif
    [ZIKServiceRouteRegistry registerDestinationProtocol:serviceProtocol router:self];
}

+ (void)registerModuleProtocol:(Protocol *)configProtocol {
    NSAssert3([[self defaultRouteConfiguration] conformsToProtocol:configProtocol], @"The module config protocol (%@) should be conformed by the router (%@)'s defaultRouteConfiguration (%@).", NSStringFromProtocol(configProtocol), self, NSStringFromClass([[self defaultRouteConfiguration] class]));
    NSAssert(!ZIKServiceRouteRegistry.registrationFinished, @"Only register in +registerRoutableDestination.");
    [ZIKServiceRouteRegistry registerModuleProtocol:configProtocol router:self];
}

+ (void)registerIdentifier:(NSString *)identifier {
    NSAssert(!ZIKServiceRouteRegistry.registrationFinished, @"Only register in +registerRoutableDestination.");
    [ZIKServiceRouteRegistry registerIdentifier:identifier router:self];
}

@end

@implementation ZIKServiceRouter (RegisterMaking)

+ (void)registerServiceProtocol:(Protocol<ZIKServiceRoutable> *)serviceProtocol forMakingService:(Class)serviceClass {
    NSAssert(!ZIKServiceRouteRegistry.registrationFinished, @"Only register in +registerRoutableDestination.");
    [ZIKServiceRouteRegistry registerDestinationProtocol:serviceProtocol forMakingDestination:serviceClass];
}

+ (void)registerServiceProtocol:(Protocol<ZIKServiceRoutable> *)serviceProtocol forMakingService:(Class)serviceClass factory:(id _Nullable(*)(ZIKPerformRouteConfiguration *_Nonnull))function {
    NSAssert(!ZIKServiceRouteRegistry.registrationFinished, @"Only register in +registerRoutableDestination.");
    [ZIKServiceRouteRegistry registerDestinationProtocol:serviceProtocol forMakingDestination:serviceClass factoryFunction:function];
}

+ (void)registerServiceProtocol:(Protocol<ZIKServiceRoutable> *)serviceProtocol forMakingService:(Class)serviceClass making:(id  _Nullable (^)(ZIKPerformRouteConfiguration * _Nonnull))makeDestination {
    NSParameterAssert([serviceClass conformsToProtocol:serviceProtocol]);
    NSAssert(!ZIKServiceRouteRegistry.registrationFinished, @"Only register in +registerRoutableDestination.");
    [ZIKServiceRouteRegistry registerDestinationProtocol:serviceProtocol forMakingDestination:serviceClass factoryBlock:makeDestination];
}

+ (void)registerModuleProtocol:(Protocol<ZIKServiceModuleRoutable> *)configProtocol forMakingService:(Class)serviceClass factory:(ZIKPerformRouteConfiguration<ZIKConfigurationMakeable> * _Nonnull (*_Nonnull)(void))function {
    NSAssert(!ZIKServiceRouteRegistry.registrationFinished, @"Only register in +registerRoutableDestination.");
    [ZIKServiceRouteRegistry registerModuleProtocol:configProtocol forMakingDestination:serviceClass factoryFunction:function];
}

+ (void)registerModuleProtocol:(Protocol<ZIKServiceModuleRoutable> *)configProtocol forMakingService:(Class)serviceClass making:(ZIKPerformRouteConfiguration<ZIKConfigurationMakeable> *(^)(void))makeConfiguration {
    NSAssert(!ZIKServiceRouteRegistry.registrationFinished, @"Only register in +registerRoutableDestination.");
    [ZIKServiceRouteRegistry registerModuleProtocol:configProtocol forMakingDestination:serviceClass factoryBlock:makeConfiguration];
}

+ (void)registerIdentifier:(NSString *)identifier forMakingService:(Class)serviceClass {
    NSAssert(!ZIKServiceRouteRegistry.registrationFinished, @"Only register in +registerRoutableDestination.");
    [ZIKServiceRouteRegistry registerIdentifier:identifier forMakingDestination:serviceClass];
}

+ (void)registerIdentifier:(NSString *)identifier forMakingService:(Class)serviceClass factory:(id _Nullable(*_Nonnull)(ZIKPerformRouteConfiguration *_Nonnull))function {
    NSAssert(!ZIKServiceRouteRegistry.registrationFinished, @"Only register in +registerRoutableDestination.");
    [ZIKServiceRouteRegistry registerIdentifier:identifier forMakingDestination:serviceClass factoryFunction:function];
}

+ (void)registerIdentifier:(NSString *)identifier forMakingService:(Class)serviceClass making:(id  _Nullable (^)(ZIKPerformRouteConfiguration * _Nonnull))makeDestination {
    NSAssert(!ZIKServiceRouteRegistry.registrationFinished, @"Only register in +registerRoutableDestination.");
    [ZIKServiceRouteRegistry registerIdentifier:identifier forMakingDestination:serviceClass factoryBlock:(id)makeDestination];
}

+ (void)registerIdentifier:(NSString *)identifier forMakingService:(Class)serviceClass configurationFactory:(ZIKPerformRouteConfiguration<ZIKConfigurationMakeable> * _Nonnull (*_Nonnull)(void))function {
    NSAssert(!ZIKServiceRouteRegistry.registrationFinished, @"Only register in +registerRoutableDestination.");
    [ZIKServiceRouteRegistry registerIdentifier:identifier forMakingDestination:serviceClass configFactoryFunction:function];
}

+ (void)registerIdentifier:(NSString *)identifier forMakingService:(Class)serviceClass configurationMaking:(ZIKPerformRouteConfiguration<ZIKConfigurationMakeable> *(^)(void))makeConfiguration {
    NSAssert(!ZIKServiceRouteRegistry.registrationFinished, @"Only register in +registerRoutableDestination.");
    [ZIKServiceRouteRegistry registerIdentifier:identifier forMakingDestination:serviceClass configFactoryBlock:makeConfiguration];
}

@end

void _registerServiceProtocolWithSwiftFactory(Protocol<ZIKServiceRoutable> *serviceProtocol, Class serviceClass, id _Nullable (^block)(ZIKPerformRouteConfiguration * _Nonnull)) {
    NSCAssert(!ZIKServiceRouteRegistry.registrationFinished, @"Only register in +registerRoutableDestination.");
    [ZIKServiceRouteRegistry registerDestinationProtocol:serviceProtocol forMakingDestination:serviceClass factoryBlock:block];
}

void _registerServiceModuleProtocolWithSwiftFactory(Protocol<ZIKServiceModuleRoutable> *moduleProtocol, Class serviceClass, id(^block)(void)) {
    NSCAssert(!ZIKServiceRouteRegistry.registrationFinished, @"Only register in +registerRoutableDestination.");
    [ZIKServiceRouteRegistry registerModuleProtocol:moduleProtocol forMakingDestination:serviceClass factoryBlock:block];
}

void _registerServiceIdentifierWithSwiftFactory(NSString *identifier, Class serviceClass, id _Nullable (^block)(ZIKPerformRouteConfiguration * _Nonnull)) {
    NSCAssert(!ZIKServiceRouteRegistry.registrationFinished, @"Only register in +registerRoutableDestination.");
    [ZIKServiceRouteRegistry registerIdentifier:identifier forMakingDestination:serviceClass factoryBlock:block];
}

void _registerServiceModuleIdentifierWithSwiftFactory(NSString *identifier, Class serviceClass, id(^block)(void)) {
    NSCAssert(!ZIKServiceRouteRegistry.registrationFinished, @"Only register in +registerRoutableDestination.");
    [ZIKServiceRouteRegistry registerIdentifier:identifier forMakingDestination:serviceClass configFactoryBlock:block];
}

@implementation ZIKServiceRouter (Private)

+ (BOOL)shouldCheckImplementation {
#if ZIKROUTER_CHECK
    return YES;
#else
    return NO;
#endif
}

Protocol<ZIKServiceRoutable> *_Nullable _routableServiceProtocolFromObject(id object) {
    if (zix_isObjcProtocol(object) == NO) {
        return nil;
    }
    Protocol *p = object;
    if (protocol_conformsToProtocol(p, @protocol(ZIKServiceRoutable))) {
        return object;
    }
    return nil;
}

Protocol<ZIKServiceModuleRoutable> *_Nullable _routableServiceModuleProtocolFromObject(id object) {
    if (zix_isObjcProtocol(object) == NO) {
        return nil;
    }
    Protocol *p = object;
    if (protocol_conformsToProtocol(p, @protocol(ZIKServiceModuleRoutable))) {
        return object;
    }
    return nil;
}

@end

@implementation ZIKServiceRouter (Utility)

+ (void)enumerateAllServiceRouters:(void(NS_NOESCAPE ^)(Class routerClass))handler {
    if (handler == nil) {
        return;
    }
    [ZIKServiceRouteRegistry enumerateAllServiceRouters:^(Class  _Nullable __unsafe_unretained routerClass, ZIKServiceRoute * _Nullable route) {
        if (routerClass) {
            handler(routerClass);
        }
    }];
}

@end
