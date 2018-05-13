//
//  ZIKBlockViewRouter.h
//  ZIKRouter
//
//  Created by zuik on 2018/4/7.
//  Copyright © 2018 zuik. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "ZIKViewRouter.h"

NS_ASSUME_NONNULL_BEGIN

@class ZIKViewRoute;

///Wrapper view router for ZIKViewRoute.
@interface ZIKBlockViewRouter : ZIKViewRouter<id, ZIKViewRouteConfiguration *>

- (ZIKViewRoute *)route;

@end

NS_ASSUME_NONNULL_END
