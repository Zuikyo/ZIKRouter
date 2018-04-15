//
//  ZIKPerformRouteConfiguration+Route.m
//  ZIKRouter
//
//  Created by zuik on 2018/4/7.
//  Copyright © 2018 zuik. All rights reserved.
//

#import "ZIKPerformRouteConfiguration+Route.h"
#import "ZIKRoute.h"
#import <objc/runtime.h>

static void *kRouteConfigurationRouteKey = &kRouteConfigurationRouteKey;
@implementation ZIKPerformRouteConfiguration (Route)

- (ZIKRoute *)route {
    return objc_getAssociatedObject(self, kRouteConfigurationRouteKey);
}

- (void)setRoute:(ZIKRoute *)route {
    objc_setAssociatedObject(self, kRouteConfigurationRouteKey, route, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
