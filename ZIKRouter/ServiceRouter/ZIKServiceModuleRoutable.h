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
 
 1. Passing those parameters not belonging to the destination, but belonging to other components in the module.
 
 2. Passing those required parameters when creating destination with custom initializer.
 
 How to create router for LoginService with custom configuration:
 
 1. Declare a routable module protocol for those parameters for LoginService:
 @code
 // LoginServiceModuleInput inherits from ZIKServiceModuleRoutable
 @protocol LoginServiceModuleInput <ZIKServiceModuleRoutable>
 - (void)constructWithAccount:(NSString *)account;
 // Return the destination
 @property (nonatomic, copy, nullable) void(^makingLoginServiceHandler)(id<LoginServiceInput> destination);
 @end
 @endcode
 
 2. Create router subclass for LoginService:
 @code
 @import ZIKRouter;
 @interface LoginServiceRouter: ZIKServiceRouter
 @end
 
 @import ZIKRouter.Internal;
 
 // Custom configuration conforming to LoginServiceModuleInput
 // If you don't wan't to use subclass, you can use category to let ZIKPerformRouteConfiguration conform to LoginServiceModuleInput
 @interface LoginServiceModuleConfiguration: ZIKPerformRouteConfiguration <LoginServiceModuleInput>
 @property (nonatomic, copy, nullable) NSString *account;
 @property (nonatomic, copy, nullable) void(^makingLoginDestinationHandler)(id<LoginServiceInput> destination);
 @end
 
 @implementation LoginServiceModuleConfiguration
 - (void)constructWithAccount:(NSString *)account {
    self.account = account;
 }
 @end
 
 DeclareRoutableService(LoginService, LoginServiceRouter)
 @implementation LoginServiceRouter
 
 + (void)registerRoutableDestination {
    [self registerService:[LoginService class]];
    [self registerModuleProtocol:ZIKRoutable(LoginServiceModuleInput)];
 }
 
 // Use custom configuration for this router
 + (ZIKPerformRouteConfiguration *)defaultConfiguration {
    return [[LoginServiceModuleConfiguration alloc] init];
 }
 
 - (id<LoginServiceInput>)destinationWithConfiguration:(LoginServiceModuleConfiguration *)configuration {
    if (configuration.account == nil) {
        return nil;
    }
    // LoginService requires account parameter when initializing.
    LoginService *destination = [[LoginService alloc] initWithAccount:configuration.account];
    return destination;
 }
 
 - (void)didFinishPrepareDestination:(id<LoginServiceInput>)destination configuration:(LoginServiceModuleConfiguration *)configuration {
    // Give the destination to the caller
    if (configuration.makingLoginDestinationHandler) {
        configuration.makingLoginDestinationHandler(destination);
        configuration.makingLoginDestinationHandler = nil;
    }
 }
 
 @end
 @endcode
 
 Then you can use the login service module:
 @code
 [ZIKRouterToServiceModule(LoginServiceModuleInput)
    makeDestinationWithConfiguring:^(ZIKPerformRouteConfiguration<LoginServiceModuleInput> *config) {
        [config constructWithAccount:@"account"];
        config.makingLoginServiceHandler = ^(id<LoginServiceInput> destination) {
            // Did get the destination
        };
 }];
 @endcode
 
 @note
 It's safe to use objc protocols inheriting from ZIKServiceModuleRoutable with ZIKRouterToServiceModule() and won't get nil. When ZIKROUTER_CHECK is enabled, ZIKServiceRouter will validate all ZIKServiceModuleRoutable protocols when registration is finished, then we can make sure all routable module protocols have been registered with a router.
 */
@protocol ZIKServiceModuleRoutable

@end
