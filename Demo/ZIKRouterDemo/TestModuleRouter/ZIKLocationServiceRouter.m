//
//  ZIKLocationServiceRouter.m
//  ZIKRouterDemo
//
//  Created by zuik on 2017/7/14.
//  Copyright © 2017年 zuik. All rights reserved.
//

#import "ZIKLocationServiceRouter.h"
#import "ZIKLocationManager.h"

@implementation ZIKLocationServiceRouter

- (id)destinationWithConfiguration:(__kindof ZIKRouteConfiguration *)configuration {
    ZIKLocationManager *destination = [ZIKLocationManager new];
    return destination;
}

@end
