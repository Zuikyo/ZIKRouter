//
//  ZIKViewRoutePath+CompatibleAlert.m
//  ZIKAlertModule
//
//  Created by zuik on 2018/4/24.
//  Copyright © 2018 zuik. All rights reserved.
//

#import "ZIKViewRoutePath+CompatibleAlert.h"

@implementation ZIKViewRoutePath (CompatibleAlert)

+ (ZIKViewRoutePath *(^)(UIViewController *))presentCompatibleAlertFrom {
    return ^(UIViewController *source) {
        return [[ZIKViewRoutePath alloc] initWithRouteType:ZIKViewRouteTypeCustom source:source];
    };
}

@end
