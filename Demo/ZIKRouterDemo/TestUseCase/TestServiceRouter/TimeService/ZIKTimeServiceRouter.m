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
}

- (id)destinationWithConfiguration:(__kindof ZIKRouteConfiguration *)configuration {
    return [ZIKTimeService sharedInstance];
}

@end
