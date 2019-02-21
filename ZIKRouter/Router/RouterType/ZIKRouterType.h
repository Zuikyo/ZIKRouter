//
//  ZIKRouterType.h
//  ZIKRouter
//
//  Created by zuik on 2018/1/21.
//  Copyright © 2017 zuik. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import <Foundation/Foundation.h>
#import "ZIKRouteConfiguration.h"

NS_ASSUME_NONNULL_BEGIN

@class ZIKRoute;

/// Proxy to use ZIKRouter class type or ZIKRoute with compile time checking. These instance methods are actually class methods in ZIKRouter class.
@interface ZIKRouterType<__covariant Destination, __covariant RouteConfig: ZIKPerformRouteConfiguration *, __covariant RemoveConfig: ZIKRemoveRouteConfiguration *> : NSObject
@property (nonatomic, strong, readonly, nullable) Class routerClass;
@property (nonatomic, strong, readonly, nullable) ZIKRoute *route;
// routerClass or ZIKRoute
@property (nonatomic, strong, readonly) id routeObject;

- (nullable instancetype)initWithRouterClass:(Class)routerClass NS_DESIGNATED_INITIALIZER;
- (nullable instancetype)initWithRoute:(ZIKRoute *)route NS_DESIGNATED_INITIALIZER;

+ (nullable instancetype)tryMakeRouterTypeForRoute:(id)route;

/// Default configuration to perform route.
- (RouteConfig)defaultRouteConfiguration;

/// Default configuration to remove route.
- (RemoveConfig)defaultRemoveConfiguration;

#pragma mark Factory

/// Whether the destination is instantiated synchronously.
- (BOOL)canMakeDestinationSynchronously;

/// The router may can't make destination synchronously, or it's not for providing a destination but only for performing some actions.
- (BOOL)canMakeDestination;

/// Synchronously get destination.
- (nullable Destination)makeDestination;

/// Synchronously get destination, and prepare the destination with destination protocol. The block is an escaping block, use weak self in it.
- (nullable Destination)makeDestinationWithPreparation:(void(^ _Nullable)(Destination destination))prepare;

/// Synchronously get destination, and prepare the destination.
- (nullable Destination)makeDestinationWithConfiguring:(void(NS_NOESCAPE ^ _Nullable)(RouteConfig config))configBuilder;

/**
 Synchronously get destination, and prepare the destination in a type safe way inferred by generic parameters.
 
 @param configBuilder Type safe builder to build configuration, type of `config`'s properties are inferred by generic parameters.
 @return The prepared destination.
 */
- (nullable Destination)makeDestinationWithStrictConfiguring:(void(NS_NOESCAPE ^ _Nullable)(ZIKPerformRouteStrictConfiguration<Destination> *config, RouteConfig module))configBuilder;

#pragma mark Unavailable

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
- (id)copy NS_UNAVAILABLE;
- (id)mutableCopy NS_UNAVAILABLE;
- (IMP)methodForSelector:(SEL)aSelector NS_UNAVAILABLE;
- (void)doesNotRecognizeSelector:(SEL)aSelector NS_UNAVAILABLE;
- (id)forwardingTargetForSelector:(SEL)aSelector NS_UNAVAILABLE;
- (void)forwardInvocation:(NSInvocation *)anInvocation NS_UNAVAILABLE;
- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
