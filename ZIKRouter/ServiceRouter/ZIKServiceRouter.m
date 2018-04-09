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
#import "ZIKServiceRouteRegistry.h"
#import "ZIKRouteRegistryInternal.h"
#import <objc/runtime.h>
#import <UIKit/UIKit.h>
#import "ZIKRouterRuntime.h"

ZIKRouteAction const ZIKRouteActionToService = @"ZIKRouteActionToService";
ZIKRouteAction const ZIKRouteActionToServiceModule = @"ZIKRouteActionToServiceModule";

NSString *const kZIKServiceRouterErrorDomain = @"ZIKServiceRouterErrorDomain";

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

- (void)performWithConfiguration:(__kindof ZIKPerformRouteConfiguration *)configuration {
    [[self class] increaseRecursiveDepth];
    if ([[self class] _validateInfiniteRecursion] == NO) {
        [self _callbackError_infiniteRecursionWithAction:ZIKRouteActionPerformRoute errorDescription:@"Infinite recursion for performing route detected. Recursive call stack:\n%@",[NSThread callStackSymbols]];
        [[self class] decreaseRecursiveDepth];
        return;
    }
    [super performWithConfiguration:configuration];
    [[self class] decreaseRecursiveDepth];
}

+ (BOOL)isAbstractRouter {
    return self == [ZIKServiceRouter class];
}

+ (void)registerRoutableDestination {
    NSAssert1(NO, @"subclass(%@) must override +registerRoutableDestination to register destination.",self);
}

- (void)performRouteOnDestination:(id)destination configuration:(__kindof ZIKPerformRouteConfiguration *)configuration {
    [self beginPerformRoute];
    
    if (!destination) {
        [self endPerformRouteWithError:[[self class] errorWithCode:ZIKServiceRouteErrorServiceUnavailable localizedDescriptionFormat:@"Router(%@) returns nil for destination, you can't use this service now. Maybe your configuration is invalid (%@), or there is a bug in the router.",self,configuration]];
        return;
    }
#if ZIKROUTER_CHECK
    [self _validateDestinationConformance:destination];
#endif
    [self prepareForPerformRouteOnDestination:destination configuration:configuration];
    if (configuration.routeCompletion) {
        configuration.routeCompletion(destination);
    }
    [self endPerformRouteWithSuccess];
}

- (void)prepareForPerformRouteOnDestination:(id)destination configuration:(__kindof ZIKPerformRouteConfiguration *)configuration {
    if (configuration.prepareDestination) {
        configuration.prepareDestination(destination);
    }
    [self prepareDestination:destination configuration:configuration];
    [self didFinishPrepareDestination:destination configuration:configuration];
}

- (void)prepareDestination:(id)destination configuration:(__kindof ZIKPerformRouteConfiguration *)configuration {
    NSAssert([self class] != [ZIKServiceRouter class], @"Prepare destination with it's router.");
}

- (void)didFinishPrepareDestination:(id)destination configuration:(__kindof ZIKPerformRouteConfiguration *)configuration {
    NSAssert([self class] != [ZIKServiceRouter class], @"Prepare destination with it's router.");
}

#pragma mark State

- (void)beginPerformRoute {
    NSAssert(self.state != ZIKRouterStateRouting, @"state should not be routing when begin to route.");
    [self notifyRouteState:ZIKRouterStateRouting];
}

- (void)prepareDestinationBeforeRemoving {
    id destination = self.destination;
    ZIKRemoveRouteConfiguration *configuration = self.original_removeConfiguration;
    if (configuration.prepareDestination && destination) {
        configuration.prepareDestination(destination);
    }
}

- (void)endPerformRouteWithSuccess {
    NSAssert(self.state == ZIKRouterStateRouting, @"state should be routing when end to route.");
    [self notifyRouteState:ZIKRouterStateRouted];
    [self notifySuccessWithAction:ZIKRouteActionPerformRoute];
}

- (void)endPerformRouteWithError:(NSError *)error {
    NSAssert(self.state == ZIKRouterStateRouting, @"state should be routing when end to route.");
    [self notifyRouteState:self.preState];
    [self notifyError:error routeAction:ZIKRouteActionPerformRoute];
}

- (void)beginRemoveRoute {
    NSAssert(self.state != ZIKRouterStateRemoving, @"state should not be removing when begin remove route.");
    [self notifyRouteState:ZIKRouterStateRemoving];
}

- (void)endRemoveRouteWithSuccess {
    NSAssert(self.state == ZIKRouterStateRemoving, @"state should be removing when end remove route.");
    [self notifyRouteState:ZIKRouterStateRemoved];
    [self notifySuccessWithAction:ZIKRouteActionRemoveRoute];
}

- (void)endRemoveRouteWithError:(NSError *)error {
    NSAssert(self.state == ZIKRouterStateRemoving, @"state should be removing when end remove route.");
    [self notifyRouteState:self.preState];
    [self notifyError:error routeAction:ZIKRouteActionRemoveRoute];
}

+ (__kindof ZIKPerformRouteConfiguration *)defaultRouteConfiguration {
    return [ZIKPerformRouteConfiguration new];
}

+ (__kindof ZIKRemoveRouteConfiguration *)defaultRemoveConfiguration {
    return [ZIKRemoveRouteConfiguration new];
}

- (NSString *)errorDomain {
    return kZIKServiceRouterErrorDomain;
}

+ (BOOL)canMakeDestinationSynchronously {
    return YES;
}

#pragma mark Validate

- (void)_validateDestinationConformance:(id)destination {
#if ZIKROUTER_CHECK
    Protocol *destinationProtocol;
    BOOL result = [ZIKServiceRouteRegistry validateDestinationConformance:[destination class] forRouter:self protocol:&destinationProtocol];
    NSAssert(result, @"Bad implementation in router (%@)'s -destinationWithConfiguration:. The destiantion (%@) doesn't conforms to registered service protocol (%@).",self, destination, NSStringFromProtocol(destinationProtocol));
#endif
}

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

- (void)_callbackErrorWithAction:(ZIKRouteAction)routeAction error:(NSError *)error {
    [[self class] _callbackGlobalErrorHandlerWithRouter:self action:routeAction error:error];
    [super notifyError:error routeAction:routeAction];
}

- (void)_callbackError_actionFailedWithAction:(ZIKRouteAction)action errorDescription:(NSString *)format ,... {
    va_list argList;
    va_start(argList, format);
    NSString *description = [[NSString alloc] initWithFormat:format arguments:argList];
    va_end(argList);
    [self _callbackErrorWithAction:action error:[[self class] errorWithCode:ZIKServiceRouteErrorActionFailed localizedDescription:description]];
}

- (void)_callbackError_infiniteRecursionWithAction:(ZIKRouteAction)action errorDescription:(NSString *)format ,... {
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

@implementation ZIKServiceRouter (Register)

+ (void)registerService:(Class)serviceClass {
    NSParameterAssert(serviceClass);
    NSParameterAssert([serviceClass conformsToProtocol:@protocol(ZIKRoutableService)]);
    NSAssert(!ZIKServiceRouteRegistry.registrationFinished, @"Only register in +registerRoutableDestination.");
    NSAssert([NSThread isMainThread], @"Call in main thread for thread safety.");
    [ZIKServiceRouteRegistry registerDestination:serviceClass router:self];
}

+ (void)registerExclusiveService:(Class)serviceClass {
    NSParameterAssert([serviceClass conformsToProtocol:@protocol(ZIKRoutableService)]);
    NSAssert(!ZIKServiceRouteRegistry.registrationFinished, @"Only register in +registerRoutableDestination.");
    NSAssert([NSThread isMainThread], @"Call in main thread for thread safety.");
    [ZIKServiceRouteRegistry registerExclusiveDestination:serviceClass router:self];
}

+ (void)registerServiceProtocol:(Protocol *)serviceProtocol {
    NSAssert(!ZIKServiceRouteRegistry.registrationFinished, @"Only register in +registerRoutableDestination.");
    NSAssert([NSThread isMainThread], @"Call in main thread for thread safety.");
    [ZIKServiceRouteRegistry registerDestinationProtocol:serviceProtocol router:self];
}

+ (void)registerModuleProtocol:(Protocol *)configProtocol {
    NSAssert([[self defaultRouteConfiguration] conformsToProtocol:configProtocol], @"configProtocol should be conformed by this router's defaultRouteConfiguration.");
    NSAssert(!ZIKServiceRouteRegistry.registrationFinished, @"Only register in +registerRoutableDestination.");
    NSAssert([NSThread isMainThread], @"Call in main thread for thread safety.");
    [ZIKServiceRouteRegistry registerModuleProtocol:configProtocol router:self];
}

@end

@implementation ZIKServiceRouter (Private)

+ (BOOL)shouldCheckImplementation {
#if ZIKROUTER_CHECK
    return YES;
#else
    return NO;
#endif
}

+ (BOOL)_isRegistrationFinished {
    return ZIKServiceRouteRegistry.registrationFinished;
}

+ (void)_swift_registerServiceProtocol:(id)serviceProtocol {
    NSCParameterAssert(ZIKRouter_isObjcProtocol(serviceProtocol));
    [self registerServiceProtocol:serviceProtocol];
}

+ (void)_swift_registerConfigProtocol:(id)configProtocol {
    NSCParameterAssert(ZIKRouter_isObjcProtocol(configProtocol));
    [self registerModuleProtocol:configProtocol];
}

+ (void)_callbackError_invalidProtocolWithAction:(ZIKRouteAction)action errorDescription:(NSString *)format ,... {
    va_list argList;
    va_start(argList, format);
    NSString *description = [[NSString alloc] initWithFormat:format arguments:argList];
    va_end(argList);
    [self _callbackGlobalErrorHandlerWithRouter:nil action:action error:[[self class] errorWithCode:ZIKServiceRouteErrorInvalidProtocol localizedDescription:description]];
    NSAssert(NO, @"Error when get router for serviceProtocol: %@",description);
}

+ (void)_callbackGlobalErrorHandlerWithRouter:(nullable __kindof ZIKServiceRouter *)router action:(ZIKRouteAction)action error:(NSError *)error {
    dispatch_semaphore_wait(g_globalErrorSema, DISPATCH_TIME_FOREVER);
    
    ZIKServiceRouteGlobalErrorHandler errorHandler = g_globalErrorHandler;
    if (errorHandler) {
        errorHandler(router, action, error);
    } else {
#ifdef DEBUG
        NSLog(@"❌ZIKServiceRouter Error: router's action (%@) catch error: (%@),\nrouter:(%@)", action, error,router);
#endif
    }
    
    dispatch_semaphore_signal(g_globalErrorSema);
}

@end
