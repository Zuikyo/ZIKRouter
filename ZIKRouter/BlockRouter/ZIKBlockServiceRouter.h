//
//  ZIKBlockServiceRouter.h
//  ZIKRouter
//
//  Created by zuik on 2018/4/7.
//  Copyright © 2018 zuik. All rights reserved.
//

#import "ZIKServiceRouter.h"

NS_ASSUME_NONNULL_BEGIN

@class ZIKServiceRoute;

@interface ZIKBlockServiceRouter : ZIKServiceRouter<id, ZIKPerformRouteConfiguration *>

- (ZIKServiceRoute *)route;

@end

NS_ASSUME_NONNULL_END
