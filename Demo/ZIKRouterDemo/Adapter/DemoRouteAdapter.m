//
//  DemoRouteAdapter.m
//  ZIKRouterDemo
//
//  Created by zuik on 2018/1/25.
//  Copyright © 2018 zuik. All rights reserved.
//

#import "DemoRouteAdapter.h"
#import "RequiredCompatibleAlertModuleInput.h"

@implementation DemoRouteAdapter

+ (void)registerRoutableDestination {
    //Let ZIKCompatibleAlertViewRouter support RequiredCompatibleAlertConfigProtocol
    //If you can get the router, you can just register
//    [ZIKCompatibleAlertViewRouter registerModuleProtocol:ZIKRoutable(RequiredCompatibleAlertConfigProtocol)];
    
    //If you don't know the router, you can use adapter
    [self registerModuleAdapter:ZIKRoutable(RequiredCompatibleAlertModuleInput) forAdaptee:ZIKRoutable(ZIKCompatibleAlertModuleInput)];
}

@end

@interface ZIKCompatibleAlertViewConfiguration (Adapter) <RequiredCompatibleAlertModuleInput>
@end
@implementation ZIKCompatibleAlertViewConfiguration (Adapter)
@end
