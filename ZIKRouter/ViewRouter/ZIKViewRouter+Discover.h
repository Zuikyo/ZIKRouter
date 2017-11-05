//
//  ZIKViewRouter+Discover.h
//  ZIKRouter
//
//  Created by zuik on 2017/10/27.
//  Copyright © 2017 zuik. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "ZIKViewRouter.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZIKViewRouter (Discover)

/**
Get the view router class registered with a view protocol.
 
The parameter viewProtocol of the block is: the protocol conformed by the view. Should be a ZIKViewRoutable protocol when ZIKVIEWROUTER_CHECK is enabled. When ZIKVIEWROUTER_CHECK is disabled, the protocol doesn't need to inherit from ZIKViewRoutable.
 
The return Class of the block is: a router class matched with the view. Return nil if protocol is nil or not registered. There will be an assert failure when result is nil.
@discussion
This function is for decoupling route behavior with router class. If a view conforms to a protocol for configuring it's dependencies, and the protocol is only used by this view, you can use +registerViewProtocol: to register the protocol, then you don't need to import the router's header when performing route.
@code
//ZIKLoginViewProtocol
@protocol ZIKLoginViewProtocol <ZIKViewRoutable>
@property (nonatomic, copy) NSString *account;
@end

//ZIKLoginViewController.h
@interface ZIKLoginViewController : UIViewController <ZIKLoginViewProtocol>
@property (nonatomic, copy) NSString *account;
@end

//in ZIKLoginViewRouter.m
//Mark ZIKLoginViewController routable
@interface ZIKLoginViewController (ZIKLoginViewRouter) <ZIKRoutableView>
@end
@implementation ZIKLoginViewController (ZIKLoginViewRouter)
@end

@implementation ZIKLoginViewRouter
+ (void)registerRoutableDestination {
    [self registerView:[ZIKLoginViewController class]];
    [self registerViewProtocol:@protocol(ZIKLoginViewProtocol)];
}
@end

//Get ZIKLoginViewRouter and perform route
[ZIKViewRouter.forView(@protocol(ZIKLoginViewProtocol))
  performWithConfigure:^(ZIKViewRouteConfiguration *config) {
    config.source = self;
    config.prepareForRoute = ^(id<ZIKLoginViewProtocol> destination) {
        destination.account = @"my account";
    };
}];
@endcode
See +registerViewProtocol: and ZIKViewRoutable for more info.
*/
@property (nonatomic,class,readonly) Class _Nullable (^forView)(Protocol *viewProtocol);

/**
 Get the view router class combined with a custom ZIKViewRouteConfiguration conforming to a module config protocol.
 
 The parameter configProtocol of the block is: The protocol conformed by defaultConfiguration of router. Should be a ZIKViewModuleRoutable protocol when ZIKVIEWROUTER_CHECK is enabled. When ZIKVIEWROUTER_CHECK is disabled, the protocol doesn't need to inherit from ZIKViewModuleRoutable.
 
 The return Class of the block is: a router class matched with the view. Return nil if protocol is nil or not registered. There will be an assert failure when result is nil.
 @discussion
 Similar to ZIKViewRouter.forView(), this function is for decoupling route behavior with router class. If configurations of a module can't be set directly with a protocol the view conforms, you can use a custom ZIKViewRouteConfiguration to config these configurations. Use +registerModuleProtocol: to register the protocol, then you don't need to import the router's header when performing route.
 @code
 //ZIKLoginViewProtocol
 @protocol ZIKLoginViewConfigProtocol <ZIKViewModuleRoutable>
 @property (nonatomic, copy) NSString *account;
 @end
 
 //ZIKLoginViewController.h
 @interface ZIKLoginViewController : UIViewController
 @property (nonatomic, copy) NSString *account;
 @end
 
 @interface ZIKLoginViewConfiguration : ZIKViewRouteConfiguration <NSCopying, ZIKLoginViewConfigProtocol>
 @property (nonatomic, copy) NSString *account;
 @end
 
 //in ZIKLoginViewRouter.m
 //Mark ZIKLoginViewController routable
 @interface ZIKLoginViewController (ZIKLoginViewRouter) <ZIKRoutableView>
 @end
 @implementation ZIKLoginViewController (ZIKLoginViewRouter)
 @end
 
 @interface ZIKLoginViewRouter : ZIKViewRouter<ZIKViewRouteConfiguration<ZIKLoginViewConfigProtocol> *, ZIKViewRemoveConfiguration *> <ZIKViewRouterProtocol>
 @end
 @implementation ZIKLoginViewRouter
 + (void)registerRoutableDestination {
     [self registerView:[ZIKLoginViewController class]];
     [self registerModuleProtocol:@protocol(ZIKLoginViewConfigProtocol)];
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
 [ZIKViewRouter.forModule(@protocol(ZIKLoginViewConfigProtocol))
   performWithConfigure:^(ZIKViewRouteConfiguration<ZIKLoginViewConfigProtocol> *config) {
     config.source = self;
     config.account = @"my account";
 }];
 @endcode
 See +registerModuleProtocol: and ZIKViewModuleRoutable for more info.
 */
@property (nonatomic,class,readonly) Class _Nullable (^forModule)(Protocol *configProtocol);

@end

NS_ASSUME_NONNULL_END
