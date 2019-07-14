//
//  ZIKServiceModuleRoutable.h
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
 Protocols inheriting from ZIKServiceModuleRoutable can be used to fetch service router with ZIKRouterToServiceModule(), and the router's configuration certainly conforms to the protocol. See +[ZIKServiceRouter toModule].
 
 @discussion
 ZIKServiceModuleRoutable is for:
 
 1. Passing those required parameters when creating destination with custom initializer.
 
 2. Passing those parameters not belonging to the destination, but belonging to other components in the module.
 
 How to create router for LoginService with custom configuration:
 
 1. Declare a routable module protocol for those parameters for LoginService:
 @code
 // LoginServiceModuleInput inherits from ZIKServiceModuleRoutable
 @protocol LoginServiceModuleInput <ZIKServiceModuleRoutable>
 /// Factory method, passsing required parameter and return destination with LoginServiceInput type.
 @property (nonatomic, copy, readonly) id<LoginServiceInput> _Nullable(^makeDestinationWith)(NSString *account);
 @end
 @endcode
 
 2. Create router subclass for LoginService:
 @code
 @import ZIKRouter;
 @interface LoginServiceRouter: ZIKServiceRouter
 @end
 
 @import ZIKRouter.Internal;
 
 // There're 2 ways to use a custom configuration:
 // 1. Override +defaultConfiguration and use ZIKServiceMakeableConfiguration (preferred way for simple parameters)
 // 2. Create subclass (or add category) of ZIKPerformRouteConfiguration (powerful way for complicated parameters)
 
 DeclareRoutableService(LoginService, LoginServiceRouter)
 
 // Let ZIKServiceMakeableConfiguration conform to LoginServiceModuleInput
 DeclareRoutableServiceModuleProtocol(LoginServiceModuleInput)
 
 @implementation LoginServiceRouter
 
 + (void)registerRoutableDestination {
    [self registerService:[LoginService class]];
    [self registerModuleProtocol:ZIKRoutable(LoginServiceModuleInput)];
 }
 
 // Use custom configuration for this router
 + (ZIKPerformRouteConfiguration *)defaultConfiguration {
    ZIKServiceMakeableConfiguration<LoginService *> *config = [ZIKServiceMakeableConfiguration new];
    __weak typeof(config) weakConfig = config;
    // User is responsible for calling makeDestinationWith and giving parameters
    config.makeDestinationWith = id^(NSString *account) {
 
        // Capture parameters in makeDestination, so we don't need configuration subclass to hold the parameters
        // MakeDestination will be used for creating destination instance
        weakConfig.makeDestination = ^LoginService * _Nullable{
            // Use custom initializer
            LoginService *destination = [LoginService alloc] initWithAccount:account];
            return destination;
        };
        // Set makedDestination, so the router won't make destination and prepare destination again when perform with this configuration
        weakConfig.makedDestination = weakConfig.makeDestination();
        return weakConfig.makedDestination;
    };
    return config;
 }
 
 - (id<LoginServiceInput>)destinationWithConfiguration:(LoginServiceModuleConfiguration *)configuration {
    if (configuration.makeDestination) {
        return configuration.makeDestination();
    }
    // LoginService requires account parameter when initializing.
    return nil;
 }
 
 @end
 @endcode
 
 Then you can use the login service module:
 @code
 [ZIKRouterToServiceModule(LoginServiceModuleInput)
    makeDestinationWithConfiguring:^(ZIKPerformRouteConfiguration<LoginServiceModuleInput> *config) {
        id<LoginServiceInput> destination = config.makeDestinationWith(@"account");
 }];
 @endcode
 
 @note
 It's safe to use objc protocols inheriting from ZIKServiceModuleRoutable with ZIKRouterToServiceModule() and won't get nil. When ZIKROUTER_CHECK is enabled, ZIKServiceRouter will validate all ZIKServiceModuleRoutable protocols when registration is finished, then we can make sure all routable module protocols have been registered with a router.
 */
@protocol ZIKServiceModuleRoutable

@end
