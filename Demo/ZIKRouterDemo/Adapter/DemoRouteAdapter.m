//
//  DemoRouteAdapter.m
//  ZIKRouterDemo
//
//  Created by zuik on 2018/1/25.
//  Copyright © 2018 zuik. All rights reserved.
//

#import "DemoRouteAdapter.h"
#import "RequiredCompatibleAlertConfigProtocol.h"

@implementation DemoRouteAdapter

+ (void)registerRoutableDestination {
    //Let ZIKCompatibleAlertViewRouter support RequiredCompatibleAlertConfigProtocol
    [ZIKCompatibleAlertViewRouter registerModuleProtocol:ZIKRoutableProtocol(RequiredCompatibleAlertConfigProtocol)];
}

@end

@interface ZIKCompatibleAlertViewConfiguration (Adapter) <RequiredCompatibleAlertConfigProtocol>
@end
@implementation ZIKCompatibleAlertViewConfiguration (Adapter)
@end
