//
//  ZIKServiceRouterProtocol.h
//  ZIKRouter
//
//  Created by zuik on 2017/11/8.
//  Copyright © 2017年 zuik. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ZIKRoutableService;
@class ZIKServiceRouteConfiguration;

@protocol ZIKServiceRouterProtocol <NSObject>

///Register the destination class with those +registerXXX: methods. ZIKServiceRouter will call this method before app did finish launch. If a router was not registered with any service class, there'll be an assert failure.
+ (void)registerRoutableDestination;

///Create and initialize destination with configuration.
- (nullable id<ZIKRoutableService>)destinationWithConfiguration:(__kindof ZIKServiceRouteConfiguration *)configuration;

@end

NS_ASSUME_NONNULL_END
