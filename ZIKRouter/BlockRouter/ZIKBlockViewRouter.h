//
//  ZIKBlockViewRouter.h
//  ZIKRouter
//
//  Created by zuik on 2018/4/7.
//  Copyright © 2018 zuik. All rights reserved.
//

#import "ZIKViewRouter.h"

NS_ASSUME_NONNULL_BEGIN

@class ZIKViewRoute;

@interface ZIKBlockViewRouter : ZIKViewRouter<id<ZIKRoutableView>, ZIKViewRouteConfiguration *>

- (ZIKViewRoute *)route;

@end

NS_ASSUME_NONNULL_END
