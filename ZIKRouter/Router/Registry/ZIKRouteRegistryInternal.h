//
//  ZIKRouteRegistryInternal.h
//  ZIKRouter
//
//  Created by zuik on 2017/11/15.
//  Copyright © 2017 zuik. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "ZIKRouteRegistry.h"

NS_ASSUME_NONNULL_BEGIN

@class ZIKRouter, ZIKRoute, ZIKRouterType, ZIKPerformRouteConfiguration;

@interface ZIKRouteRegistry ()

/// Add registry subclass.
+ (void)addRegistry:(Class)registryClass;

#pragma mark Override

+ (ZIKRoute *)easyRouteForFactory:(id(^)(ZIKPerformRouteConfiguration * _Nonnull config, __kindof ZIKRouter * _Nonnull router))factory;
+ (ZIKRoute *)easyRouteForDestinationClass:(Class)destinationClass;

+ (Class)routerTypeClass;

+ (nullable id)routeKeyForRouter:(ZIKRouter *)router;

/// key: destination protocol, value: router class or ZIKRoute
@property (nonatomic, class, readonly) CFMutableDictionaryRef destinationProtocolToRouterMap;
/// key: module config protocol, value: router class or ZIKRoute
@property (nonatomic, class, readonly) CFMutableDictionaryRef moduleConfigProtocolToRouterMap;
/// key: destination class, value: router class or ZIKRoute set
@property (nonatomic, class, readonly) CFMutableDictionaryRef destinationToRoutersMap;
/// key: destination class, value: default router class or ZIKRoute
@property (nonatomic, class, readonly) CFMutableDictionaryRef destinationToDefaultRouterMap;
/// key: destination class, value: the exclusive router class or ZIKRoute
@property (nonatomic, class, readonly) CFMutableDictionaryRef destinationToExclusiveRouterMap;
/// key: identifier string, value: router class or ZIKRoute
@property (nonatomic, class, readonly) CFMutableDictionaryRef identifierToRouterMap;

/// key: adapter protocol, value: adaptee protocol
@property (nonatomic, class, readonly) CFMutableDictionaryRef adapterToAdapteeMap;

/// key: destination protocol, value: destination class
@property (nonatomic, class, readonly) CFMutableDictionaryRef destinationProtocolToDestinationMap;
/// key: identifier string, value: destination class
@property (nonatomic, class, readonly) CFMutableDictionaryRef identifierToDestinationMap;
/// destination classes which registered with `registerDestinationProtocol:forMakingDestination:`, `registerIdentifier:forMakingDestination:`
@property (nonatomic, class, readonly) CFMutableSetRef runtimeFactoryDestinationClasses;

/// key: destination protocol, value: destination factory function or block
@property (nonatomic, class, readonly) CFMutableDictionaryRef destinationProtocolToFactoryMap;
/// key: identifier string, value: destination factory function or block
@property (nonatomic, class, readonly) CFMutableDictionaryRef identifierToFactoryMap;
/// key: destination class, value: destination factory function / block set
@property (nonatomic, class, readonly) CFMutableDictionaryRef destinationToFactoriesMap;

#if ZIKROUTER_CHECK
/// key: router class or ZIKRoute, value: destination class set
@property (nonatomic, class, readonly) CFMutableDictionaryRef _check_routerToDestinationsMap;
/// key: router class or ZIKRoute, value: destination protocol set
@property (nonatomic, class, readonly) CFMutableDictionaryRef _check_routerToDestinationProtocolsMap;
#endif

+ (void)handleEnumerateRouterClass:(Class)aClass;
+ (void)didFinishRegistration;

/// Whether the class can be registered into this registry.
+ (BOOL)isRegisterableRouterClass:(Class)aClass;

+ (BOOL)isDestinationClassRoutable:(Class)aClass;

#pragma mark Discover

+ (nullable ZIKRouterType *)routerToRegisteredDestinationClass:(Class)destinationClass;
+ (nullable ZIKRouterType *)routerToDestination:(Protocol *)destinationProtocol;
+ (nullable ZIKRouterType *)routerToModule:(Protocol *)configProtocol;
+ (nullable ZIKRouterType *)routerToIdentifier:(NSString *)identifier;

+ (void)enumerateRoutersForDestinationClass:(Class)destinationClass handler:(void(^)(ZIKRouterType * route))handler;

#pragma mark Register

+ (void)registerDestination:(Class)destinationClass router:(Class)routerClass;
+ (void)registerExclusiveDestination:(Class)destinationClass router:(Class)routerClass;
+ (void)registerDestinationProtocol:(Protocol *)destinationProtocol router:(Class)routerClass;
+ (void)registerModuleProtocol:(Protocol *)configProtocol router:(Class)routerClass;
+ (void)registerIdentifier:(NSString *)identifier router:(Class)routerClass;

+ (void)registerDestination:(Class)destinationClass route:(ZIKRoute *)route;
+ (void)registerExclusiveDestination:(Class)destinationClass route:(ZIKRoute *)route;
+ (void)registerDestinationProtocol:(Protocol *)destinationProtocol route:(ZIKRoute *)route;
+ (void)registerModuleProtocol:(Protocol *)configProtocol route:(ZIKRoute *)route;
+ (void)registerIdentifier:(NSString *)identifier route:(ZIKRoute *)route;

+ (void)registerDestinationAdapter:(Protocol *)adapterProtocol forAdaptee:(Protocol *)adapteeProtocol;
+ (void)registerModuleAdapter:(Protocol *)adapterProtocol forAdaptee:(Protocol *)adapteeProtocol;

+ (void)registerDestinationProtocol:(Protocol *)destinationProtocol forMakingDestination:(Class)destinationClass;
+ (void)registerIdentifier:(NSString *)identifier forMakingDestination:(Class)destinationClass;

+ (void)registerDestinationProtocol:(Protocol *)destinationProtocol forMakingDestination:(Class)destinationClass factoryBlock:(id _Nullable(^ _Nonnull)(ZIKPerformRouteConfiguration * _Nonnull))block;
+ (void)registerIdentifier:(NSString *)identifier forMakingDestination:(Class)destinationClass factoryBlock:(id _Nullable(^ _Nonnull)(ZIKPerformRouteConfiguration * _Nonnull))block;

+ (void)registerDestinationProtocol:(Protocol *)destinationProtocol forMakingDestination:(Class)destinationClass factoryFunction:(id _Nullable(* _Nonnull)(ZIKPerformRouteConfiguration * _Nonnull))function;
+ (void)registerIdentifier:(NSString *)identifier forMakingDestination:(Class)destinationClass factoryFunction:(id _Nullable(* _Nonnull)(ZIKPerformRouteConfiguration * _Nonnull))function;

#pragma mark Check

//Validate whether the destination conforms to all destination protocols of the router. Only available when ZIKROUTER_CHECK is true.
+ (BOOL)validateDestinationConformance:(Class)destinationClass forRouter:(ZIKRouter *)router protocol:(Protocol *_Nullable*_Nullable)protocol;
//Validate all registered view classes of this router class, return the class when the validater return false. Only available when ZIKROUTER_CHECK is true.
+ (nullable Class)validateDestinationsForRoute:(id)route handler:(BOOL(^)(Class destinationClass))handler;

@end

NS_ASSUME_NONNULL_END
