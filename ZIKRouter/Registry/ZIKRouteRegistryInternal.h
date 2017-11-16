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

@interface ZIKRouteRegistry ()
///key: destination protocol, value: router class
@property (nonatomic, class, readonly) CFMutableDictionaryRef destinationProtocolToRouterMap;
///key: module config protocol, value: router class
@property (nonatomic, class, readonly) CFMutableDictionaryRef moduleConfigProtocolToRouterMap;
///key: destination class, value: router class set
@property (nonatomic, class, readonly) CFMutableDictionaryRef destinationToRoutersMap;
///key: destination class, value: default router class
@property (nonatomic, class, readonly) CFMutableDictionaryRef destinationToDefaultRouterMap;
///key: destination class, value: the exclusive router class
@property (nonatomic, class, readonly) CFMutableDictionaryRef destinationToExclusiveRouterMap;

///key: router class, value: destination class set
@property (nonatomic, class, readonly) CFMutableDictionaryRef _check_routerToDestinationsMap;
///key: router class, value: destination protocol set
@property (nonatomic, class, readonly) CFMutableDictionaryRef _check_routerToDestinationProtocolsMap;

+ (void)willEnumerateClasses;
+ (void)handleEnumerateClasses:(Class)aClass;
+ (void)didFinishEnumerateClasses;
+ (void)handleEnumerateProtocoles:(Protocol *)aProtocol;
+ (void)didFinishAutoRegistration;

+ (void)addRegistry:(Class)registryClass;

#pragma mark Discover

+ (_Nullable Class)routerToDestination:(Protocol *)destinationProtocol;
+ (_Nullable Class)routerToModule:(Protocol *)configProtocol;

#pragma mark Register

+ (void)registerDestination:(Class)destinationClass router:(Class)routerClass;
+ (void)registerExclusiveDestination:(Class)destinationClass router:(Class)routerClass;
+ (void)registerDestinationProtocol:(Protocol *)destinationProtocol router:(Class)routerClass;
+ (void)registerModuleProtocol:(Protocol *)configProtocol router:(Class)routerClass;

@end

NS_ASSUME_NONNULL_END
