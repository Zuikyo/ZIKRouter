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

NS_ASSUME_NONNULL_BEGIN

@class ZIKPerformRouteConfiguration;
@class ZIKRemoveRouteConfiguration;

NS_SWIFT_UNAVAILABLE("ZIKRouterType is a fake class")
///Fake class to use ZIKRouter class type with compile time checking. The real object is Class of ZIKRouter, so these instance methods are actually class methods in ZIKRouter class. Don't check whether a type is kind of ZIKRouterType.
@interface ZIKRouterType<__covariant Destination: id, __covariant RouteConfig: ZIKPerformRouteConfiguration *, __covariant RemoveConfig: ZIKRemoveRouteConfiguration *> : NSObject

#pragma mark Factory

///Whether the destination is instantiated synchronously.
- (BOOL)canMakeDestinationSynchronously;

///The router may can't make destination synchronously, or it's not for providing a destination but only for performing some actions.
- (BOOL)canMakeDestination;

///Synchronously get destination.
- (nullable Destination)makeDestination;

///Synchronously get destination, and prepare the destination with destination protocol.
- (nullable Destination)makeDestinationWithPreparation:(void(^ _Nullable)(Destination destination))prepare;

///Synchronously get destination, and prepare the destination.
- (nullable Destination)makeDestinationWithConfiguring:(void(^ _Nullable)(RouteConfig config))configBuilder;

/**
 Synchronously get destination, and prepare the destination in a type safe way inferred by generic parameters.
 
 @param configBuilder Type safe builder to build configuration, `prepareDest` is for setting `prepareDestination` block for configuration (it's an escaping block so use weakSelf in it), `prepareModule` is for setting custom route config.
 @return The prepared destination.
 */
- (nullable Destination)makeDestinationWithStrictConfiguring:(void(^ _Nullable)(RouteConfig config,
                                                                                void(^prepareDest)(void(^prepare)(Destination dest)),
                                                                                void(^prepareModule)(void(NS_NOESCAPE ^prepare)(RouteConfig module))
                                                                                ))configBuilder;

- (nullable Destination)makeDestinationWithRouteConfiguring:(void(^ _Nullable)(RouteConfig config,
                                                                               void(^prepareDest)(void(^prepare)(Destination dest)),
                                                                               void(^prepareModule)(void(NS_NOESCAPE ^prepare)(RouteConfig module))
                                                                               ))configBuilder API_DEPRECATED_WITH_REPLACEMENT("-makeDestinationWithStrictConfiguring:", ios(7.0, 7.0));

#pragma mark Unavailable

- (instancetype)init NS_UNAVAILABLE;
- (id)copy NS_UNAVAILABLE;
- (id)mutableCopy NS_UNAVAILABLE;
- (IMP)methodForSelector:(SEL)aSelector NS_UNAVAILABLE;
- (void)doesNotRecognizeSelector:(SEL)aSelector NS_UNAVAILABLE;
- (id)forwardingTargetForSelector:(SEL)aSelector NS_UNAVAILABLE;
- (void)forwardInvocation:(NSInvocation *)anInvocation NS_UNAVAILABLE;
- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
