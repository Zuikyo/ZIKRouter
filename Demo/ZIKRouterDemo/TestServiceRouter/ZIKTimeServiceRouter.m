//
//  ZIKTimeServiceRouter.m
//  ZIKRouterDemo
//
//  Created by zuik on 2017/8/9.
//  Copyright © 2017年 zuik. All rights reserved.
//

#import "ZIKTimeServiceRouter.h"
#import "ZIKTimeService.h"

RegisterRoutableService(ZIKTimeService, ZIKTimeServiceRouter)
RegisterRoutableServiceProtocol(ZIKTimeServiceInput, ZIKTimeServiceRouter)

@implementation ZIKTimeServiceRouter

- (id)destinationWithConfiguration:(__kindof ZIKRouteConfiguration *)configuration {
    return [ZIKTimeService sharedInstance];
}

@end
