//
//  ZIKTimeServiceRouter.m
//  ZIKRouterDemo
//
//  Created by zuik on 2017/8/9.
//  Copyright © 2017 zuik. All rights reserved.
//

#import "ZIKTimeServiceRouter.h"
#import "ZIKTimeService.h"

@interface ZIKTimeService (ZIKTimeServiceRouter) <ZIKRoutableService>
@end
@implementation ZIKTimeService (ZIKTimeServiceRouter)
@end

@implementation ZIKTimeServiceRouter

+ (void)registerRoutableDestination {
    [self registerService:[ZIKTimeService class]];
    [self registerServiceProtocol:ZIKRoutable(ZIKTimeServiceInput)];
    [self registerIdentifier:@"com.zuik.service.timeService"];
}

- (id)destinationWithConfiguration:(__kindof ZIKRouteConfiguration *)configuration {
    return [ZIKTimeService sharedInstance];
}

+ (void)applicationDidEnterBackground:(UIApplication *)application {
    NSLog(@"%@ handle applicationDidEnterBackground event", NSStringFromClass(self));
}

@end
