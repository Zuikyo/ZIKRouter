//
//  ZIKViewModuleRoutable.h
//  ZIKRouter
//
//  Created by zuik on 2017/8/21.
//  Copyright © 2017 zuik. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import <Foundation/Foundation.h>

/**
 Protocols inheriting from ZIKViewModuleRoutable can be used to fetch view router with ZIKRouterToViewModule(), and the router's configuration certainly conforms to the protocol. See +[ZIKViewRouter toModule].
 
 @discussion
 ZIKViewModuleRoutable is for:
 
 1. Passing those required parameters when creating destination with custom initializer.
 
 2. Passing those parameters not belonging to the destination, but belonging to other components in the module. Such as models which doesn't belonging to view controller.
 
 How to create router for LoginViewController with custom configuration:
 
 1. Declare a routable module protocol for those parameters for LoginViewController:
 @code
 // LoginViewModuleInput inherits from ZIKViewModuleRoutable
 @protocol LoginViewModuleInput <ZIKViewModuleRoutable>
 /// Factory method, passing required parameter and return destination with LoginViewInput type
 @property (nonatomic, copy, readonly) id<LoginViewInput> _Nullable(^makeDestinationWith)(NSString *account);
 @end
 @endcode
 
 2. Create router subclass for LoginViewController:
 @code
 @import ZIKRouter;
 @interface LoginViewRouter: ZIKViewRouter
 @end
 
 @import ZIKRouter.Internal;
 
 // There're 2 ways to use a custom configuration:
 // 1. Override +defaultConfiguration and use ZIKViewMakeableConfiguration (preferred way for simple parameters)
 // 2. Create subclass (or add category) of ZIKViewRouteConfiguration (powerful way for complicated parameters)
 
 DeclareRoutableView(LoginViewController, LoginViewRouter)
 
 // Let ZIKViewMakeableConfiguration conform to LoginViewModuleInput
 DeclareRoutableViewModuleProtocol(LoginViewModuleInput)
 
 @implementation LoginViewRouter
 
 + (void)registerRoutableDestination {
    [self registerView:[LoginViewController class]];
    [self registerModuleProtocol:ZIKRoutable(LoginViewModuleInput)];
 }
 
 // Use custom configuration for this router
 + (ZIKViewRouteConfiguration *)defaultConfiguration {
    ZIKViewMakeableConfiguration<LoginViewController *> *config = [ZIKViewMakeableConfiguration new];
    __weak typeof(config) weakConfig = config;
    // User is responsible for calling makeDestinationWith and giving parameters
    config.makeDestinationWith = id^(NSString *account) {
 
        // Capture parameters in makeDestination, so we don't need configuration subclass to hold the parameters
        // MakeDestination will be used for creating destination instance
        weakConfig.makeDestination = ^LoginViewController * _Nullable{
            // Use custom initializer
            LoginViewController *destination = [LoginViewController alloc] initWithAccount:account];
            return destination;
        };
        // Set makedDestination, so the router won't make destination and prepare destination again when perform with this configuration
        weakConfig.makedDestination = weakConfig.makeDestination();
        return weakConfig.makedDestination;
    };
    return config;
 }
 
 - (id<LoginViewInput>)destinationWithConfiguration:(LoginViewModuleConfiguration *)configuration {
    if (configuration.makeDestination) {
        return configuration.makeDestination();
    }
    // LoginViewController requires account parameter when initializing.
    return nil;
 }
 
 @end
 @endcode
 
 Then you can show the login view module:
 @code
 // Show the view controller
 [ZIKRouterToViewModule(LoginViewModuleInput)
    performPath:ZIKViewRoutePath.pushFrom(self)
    configuring:^(ZIKViewRouteConfiguration<LoginViewModuleInput> *config) {
        // Give parameters and make destination
        id<LoginViewInput> destination = config.makeDestinationWith(@"account");
 }];
 @endcode
 
 @note
 It's safe to use objc protocols inheriting from ZIKViewModuleRoutable with ZIKRouterToViewModule() and won't get nil. When ZIKROUTER_CHECK is enabled, ZIKViewRouter will validate all ZIKViewModuleRoutable protocols when registration is finished, then we can make sure all routable module protocols have been registered with a router.
 */
@protocol ZIKViewModuleRoutable

@end
