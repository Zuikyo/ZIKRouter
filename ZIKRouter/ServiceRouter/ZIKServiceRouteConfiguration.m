//
//  ZIKServiceRouteConfiguration.m
//  ZIKRouter
//
//  Created by zuik on 2017/10/13.
//  Copyright © 2017 zuik. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "ZIKServiceRouteConfiguration.h"

@implementation ZIKServiceRouteConfiguration

- (id)copyWithZone:(NSZone *)zone {
    ZIKServiceRouteConfiguration *config = [super copyWithZone:zone];
    config.prepareDestination = self.prepareDestination;
    config.routeCompletion = self.routeCompletion;
    return config;
}

@end
