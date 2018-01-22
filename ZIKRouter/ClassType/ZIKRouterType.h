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

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
- (BOOL)isKindOfClass:(Class)aClass NS_UNAVAILABLE;
- (BOOL)isMemberOfClass:(Class)aClass NS_UNAVAILABLE;

#pragma mark Factory

///Whether the destination is instantiated synchronously.
- (BOOL)makeDestinationSynchronously;

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
 
 @param configBuilder Type safe builder to build configuration, `prepareDest` is for setting `prepareDestination` block for configuration (it's an escapting block so use weakSelf in it), `prepareModule` is for setting custom route config.
 @return The prepared destination.
 */
- (nullable Destination)makeDestinationWithRouteConfiguring:(void(^ _Nullable)(RouteConfig config,
                                                                               void(^prepareDest)(void(^prepare)(Destination dest)),
                                                                               void(^prepareModule)(void(NS_NOESCAPE ^prepare)(RouteConfig module))
                                                                               ))configBuilder;

@end

NS_ASSUME_NONNULL_END
