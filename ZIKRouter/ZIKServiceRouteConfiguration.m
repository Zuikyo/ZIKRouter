//
//  ZIKServiceRouteConfiguration.m
//  ZIKRouter
//
//  Created by zuik on 2017/10/13.
//  Copyright © 2017 zuik. All rights reserved.
//

#import "ZIKServiceRouteConfiguration.h"

@implementation ZIKServiceRouteConfiguration

- (id)copyWithZone:(NSZone *)zone {
    ZIKServiceRouteConfiguration *config = [super copyWithZone:zone];
    config.prepareForRoute = self.prepareForRoute;
    config.routeCompletion = self.routeCompletion;
    return config;
}

@end
