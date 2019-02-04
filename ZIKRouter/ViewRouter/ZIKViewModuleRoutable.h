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
 - (void)constructWithAccount:(NSString *)account;
 // Return the destination
 @property (nonatomic, copy, nullable) void(^didMakeDestination)(id<LoginViewInput> destination);
 @end
 @endcode
 
 2. Create router subclass for LoginViewController:
 @code
 @import ZIKRouter;
 @interface LoginViewRouter: ZIKViewRouter
 @end
 
 @import ZIKRouter.Internal;
 
 // Custom configuration conforming to LoginViewModuleInput
 // If you don't wan't to use subclass, you can use category to let ZIKViewRouteConfiguration conform to LoginViewModuleInput
 @interface LoginViewModuleConfiguration: ZIKViewRouteConfiguration <LoginViewModuleInput>
 @property (nonatomic, copy, nullable) NSString *account;
 @property (nonatomic, copy, nullable) void(^didMakeDestination)(id<LoginViewInput> destination);
 @end
 
 @implementation LoginViewModuleConfiguration
 - (void)constructWithAccount:(NSString *)account {
    self.account = account;
 }
 @end
 
 DeclareRoutableView(LoginViewController, LoginViewRouter)
 @implementation LoginViewRouter
 
 + (void)registerRoutableDestination {
    [self registerView:[LoginViewController class]];
    [self registerModuleProtocol:ZIKRoutable(LoginViewModuleInput)];
 }
 
 // Use custom configuration for this router
 + (ZIKViewRouteConfiguration *)defaultConfiguration {
    return [[LoginViewModuleConfiguration alloc] init];
 }
 
 - (id<LoginViewInput>)destinationWithConfiguration:(LoginViewModuleConfiguration *)configuration {
    if (configuration.account == nil) {
        return nil;
    }
    // LoginViewController requires account parameter when initializing.
    LoginViewController *destination = [[LoginViewController alloc] initWithAccount:configuration.account];
    return destination;
 }
 
 - (void)didFinishPrepareDestination:(id<LoginViewInput>)destination configuration:(LoginViewModuleConfiguration *)configuration {
    // Give the destination to the caller
    if (configuration.didMakeDestination) {
        configuration.didMakeDestination(destination);
        configuration.didMakeDestination = nil;
    }
 }
 
 @end
 @endcode
 
 Then you can show the login view module:
 @code
 // Show the view controller
 [ZIKRouterToViewModule(LoginViewModuleInput)
    performPath:ZIKViewRoutePath.pushFrom(self)
    configuring:^(ZIKViewRouteConfiguration<LoginViewModuleInput> *config) {
        [config constructWithAccount:@"account"];
        config.didMakeDestination = ^(id<LoginViewInput> destination) {
            // Did get the destination
        };
 }];
 @endcode
 
 @note
 It's safe to use objc protocols inheriting from ZIKViewModuleRoutable with ZIKRouterToViewModule() and won't get nil. When ZIKROUTER_CHECK is enabled, ZIKViewRouter will validate all ZIKViewModuleRoutable protocols when registration is finished, then we can make sure all routable module protocols have been registered with a router.
 */
@protocol ZIKViewModuleRoutable

@end
