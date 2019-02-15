//
//  ZIKViewRouter+Discover.h
//  ZIKRouter
//
//  Created by zuik on 2018/1/22.
//  Copyright © 2017 zuik. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "ZIKViewRouter.h"
#import "ZIKViewRouterType.h"

NS_ASSUME_NONNULL_BEGIN

/// Get view router in a type safe way. There will be compile error if the view protocol is not ZIKViewRoutable.
#define ZIKRouterToView(ViewProtocol) [ZIKViewRouter<id<ViewProtocol>,ZIKViewRouteConfiguration *> toView](ZIKRoutable(ViewProtocol))

#define ZIKRouterToViewModule(ModuleProtocol) [ZIKViewRouter<id,ZIKViewRouteConfiguration<ModuleProtocol> *> toModule](ZIKRoutable(ModuleProtocol))
/// Get view router in a type safe way. There will be compile error if the module protocol is not ZIKViewModuleRoutable.

@interface ZIKViewRouter<__covariant Destination: id, __covariant RouteConfig: ZIKViewRouteConfiguration *> (Discover)

/**
 Get the view router class registered with a view protocol. Always use macro `ZIKRouterToView`, don't use this method directly.
 
 The parameter viewProtocol of the block is the protocol conformed by the view. Should be a ZIKViewRoutable protocol.
 
 The return value `ZIKViewRouterType` of the block is a router matched with the view. Return nil if protocol is nil or not registered. There will be an assert failure when result is nil.
 @discussion
 This function is for decoupling route behavior with router class. If a view conforms to a protocol for configuring its dependencies, and the protocol is only used by this view, you can use +registerViewProtocol: to register the protocol, then you don't need to import the router's header when performing route.
 @code
 //ZIKLoginViewInput
 @protocol ZIKLoginViewInput <ZIKViewRoutable>
 @property (nonatomic, copy) NSString *account;
 @end
 
 //ZIKLoginViewController.h
 @interface ZIKLoginViewController : UIViewController <ZIKLoginViewInput>
 @property (nonatomic, copy) NSString *account;
 @end
 
 //in ZIKLoginViewRouter.m
 //Mark ZIKLoginViewController routable
 DeclareRoutableView(ZIKLoginViewController, ZIKLoginViewRouter)
 
 @implementation ZIKLoginViewRouter
 + (void)registerRoutableDestination {
     [self registerView:[ZIKLoginViewController class]];
     [self registerViewProtocol:ZIKRoutable(ZIKLoginViewInput)];
 }
 @end
 
 //Get ZIKLoginViewRouter and perform route
 [ZIKRouterToView(ZIKLoginViewInput)
     performPath:ZIKViewRoutePath.presentModallyFrom(self)
     configuring:^(ZIKViewRouteConfiguration *config) {
         config.prepareDestination = ^(id<ZIKLoginViewInput> destination) {
         destination.account = @"my account";
     };
 }];
 @endcode
 See +registerViewProtocol: and ZIKViewRoutable for more info.
 */
@property (nonatomic, class, readonly) ZIKViewRouterType<Destination, RouteConfig> * _Nullable (^toView)(Protocol<ZIKViewRoutable> *viewProtocol) NS_SWIFT_UNAVAILABLE("Use `Router.to(RoutableView<ViewProtocol>())` in ZRouter instead");

/**
 Get the view router class combined with a custom ZIKViewRouteConfiguration conforming to a module config protocol. Always use macro `ZIKRouterToModule`, don't use this method directly.
 
 The parameter configProtocol of the block is: The protocol conformed by defaultConfiguration of router. Should be a ZIKViewModuleRoutable protocol.
 
 The return value `ZIKViewRouterType` of the block is a router matched with the view. Return nil if protocol is nil or not registered. There will be an assert failure when result is nil.
 @discussion
 Similar to ZIKViewRouter.toView(), this function is for decoupling route behavior with router class. If configurations of a module can't be set directly with a protocol the view conforms, you can use a custom ZIKViewRouteConfiguration to config these configurations. Use +registerModuleProtocol: to register the protocol, then you don't need to import the router's header when performing route.
 @code
 //ZIKLoginViewConfigInput
 @protocol ZIKLoginViewConfigInput <ZIKViewModuleRoutable>
 @property (nonatomic, copy) NSString *account;
 @end
 
 //ZIKLoginViewController.h
 @interface ZIKLoginViewController : UIViewController
 @property (nonatomic, copy) NSString *account;
 @end
 
 @interface ZIKLoginViewConfiguration : ZIKViewRouteConfiguration <NSCopying, ZIKLoginViewConfigInput>
 @property (nonatomic, copy) NSString *account;
 @end
 
 //in ZIKLoginViewRouter.m
 //Mark ZIKLoginViewController routable
 @interface ZIKLoginViewController (ZIKLoginViewRouter) <ZIKRoutableView>
 @end
 @implementation ZIKLoginViewController (ZIKLoginViewRouter)
 @end
 
 @interface ZIKLoginViewRouter : ZIKViewRouter<ZIKViewRouteConfiguration<ZIKLoginViewConfigInput> *, ZIKViewRemoveConfiguration *>
 @end
 @implementation ZIKLoginViewRouter
 + (void)registerRoutableDestination {
     [self registerView:[ZIKLoginViewController class]];
     [self registerModuleProtocol:ZIKRoutable(ZIKLoginViewConfigInput)];
 }
 - (id)destinationWithConfiguration:(ZIKLoginViewConfiguration *)configuration {
     ZIKLoginViewController *destination = [ZIKLoginViewController new];
     return destination;
 }
 - (void)prepareDestination:(ZIKLoginViewController *)destination configuration:(ZIKLoginViewConfiguration *)configuration {
     destination.account = configuration.account;
 }
 @end
 
 //Get ZIKLoginViewRouter and perform route
 [ZIKRouterToViewModule(ZIKLoginViewConfigInput)
     performPath:ZIKViewRoutePath.presentModallyFrom(self)
     configuring:^(ZIKViewRouteConfiguration<ZIKLoginViewConfigInput> *config) {
         config.account = @"my account";
     }];
 @endcode
 See +registerModuleProtocol: and ZIKViewModuleRoutable for more info.
 */
@property (nonatomic, class, readonly) ZIKViewRouterType<Destination, RouteConfig> * _Nullable (^toModule)(Protocol<ZIKViewModuleRoutable> *configProtocol) NS_SWIFT_UNAVAILABLE("Use `Router.to(RoutableViewModule<ModuleProtocol>())` in ZRouter instead");

/**
 Get all view routers for the destination class and its super class. The result will be empty if destination class doesn't conform to ZIKRoutableView. This method is for handling external destination. You can prepare the external destination when you don't know its router.
 
 @note
 It searchs routers for the destination class, then its super class. If you want to perform route on the destination, choose the first router in the array.
 @warning
 If the router requires to prepare the destination with its protocol, the route action may fail. So only use this method when necessary.
 */
@property (nonatomic, class, readonly) NSArray<ZIKAnyViewRouterType *> * (^routersToClass)(Class destinationClass);

/// Find view router registered with the unique identifier.
@property (nonatomic, class, readonly) ZIKAnyViewRouterType * _Nullable (^toIdentifier)(NSString *identifier);

@end

NS_ASSUME_NONNULL_END
