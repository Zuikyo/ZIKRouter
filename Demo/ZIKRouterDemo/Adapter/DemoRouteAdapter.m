//
//  DemoRouteAdapter.m
//  ZIKRouterDemo
//
//  Created by zuik on 2018/1/25.
//  Copyright © 2018 zuik. All rights reserved.
//

#import "DemoRouteAdapter.h"
#import "RequiredCompatibleAlertModuleInput.h"
#import <ZIKLoginModule/ZIKLoginModule.h>

@implementation DemoRouteAdapter

+ (void)registerRoutableDestination {
    // Let ZIKCompatibleAlertViewRouter support RequiredCompatibleAlertModuleInput and ZIKLoginModuleRequiredAlertInput
    
    // Instead of writing adapting code in the host app, the module itself can provide a default registration function
//    registerDependencyOfZIKLoginModule();
    
    // The host app can ignore the default registration and registering other adaptee
    
    // If you can get the router, you can just register the protocol to the provided module
    [ZIKCompatibleAlertViewRouter registerModuleProtocol:ZIKRoutable(ZIKLoginModuleRequiredAlertInput)];
    
    // If you don't know the router, you can register adapter
    [self registerModuleAdapter:ZIKRoutable(RequiredCompatibleAlertModuleInput) forAdaptee:ZIKRoutable(ZIKCompatibleAlertModuleInput)];
    
    // You can adapt other alert module. In ZIKRouterDemo-macOS, it's `NSAlert` in `AlertViewRouter`. in ZIKRouterDemo, it's ZIKAlertModule
}

@end

ADAPT_DEFAULT_DEPENDENCY_ZIKLoginModule

// Add adapter protocols to the provided adaptee class
@interface ZIKCompatibleAlertViewConfiguration (Adapter) <RequiredCompatibleAlertModuleInput>
@end
@implementation ZIKCompatibleAlertViewConfiguration (Adapter)
@end
