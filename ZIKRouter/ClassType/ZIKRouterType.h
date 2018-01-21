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
///This is a fake class to use ZIKRouter class type with compile time checking. The real object is Class of ZIKRouter. Don't check whether a type is kind of ZIKRouterType.
@interface ZIKRouterType<__covariant Destination: id, __covariant RouteConfig: ZIKPerformRouteConfiguration *, __covariant RemoveConfig: ZIKRemoveRouteConfiguration *> : NSObject

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
- (BOOL)isKindOfClass:(Class)aClass NS_UNAVAILABLE;
- (BOOL)isMemberOfClass:(Class)aClass NS_UNAVAILABLE;

#pragma mark Perform

///If this route action doesn't need any arguments, just perform directly.
- (nullable instancetype)performRoute;
///Set dependencies required by destination and perform route.
- (nullable instancetype)performWithConfiguring:(void(NS_NOESCAPE ^)(RouteConfig config))configBuilder;
///Set dependencies required by destination and perform route, and you can remove the route with remove configuration later.
- (nullable instancetype)performWithConfiguring:(void(NS_NOESCAPE ^)(RouteConfig config))configBuilder
                                       removing:(void(NS_NOESCAPE ^ _Nullable)(RemoveConfig config))removeConfigBuilder;

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

@end

NS_ASSUME_NONNULL_END
