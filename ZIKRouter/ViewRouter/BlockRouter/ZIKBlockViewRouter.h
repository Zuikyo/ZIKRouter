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

/// Wrapper view router for ZIKViewRoute.
@interface ZIKBlockViewRouter : ZIKViewRouter<id, ZIKViewRouteConfiguration *>

- (ZIKViewRoute *)route;

@end

/// Block view router for route type: ZIKViewRouteTypeMaskViewControllerDefault | ZIKViewRouteTypeMaskCustom.
@interface ZIKBlockCustomViewRouter : ZIKBlockViewRouter

@end

/// Block view router for route type: ZIKViewRouteTypeMaskViewDefault.
@interface ZIKBlockSubviewRouter : ZIKBlockViewRouter

@end

/// Block view router for route type: ZIKViewRouteTypeMaskViewDefault | ZIKViewRouteTypeMaskCustom.
@interface ZIKBlockCustomSubviewRouter : ZIKBlockViewRouter

@end

/// Block view router for route type: ZIKViewRouteTypeMaskCustom.
@interface ZIKBlockCustomOnlyViewRouter : ZIKBlockViewRouter

@end

/// Block view router for route type: ZIKViewRouteTypeMaskViewControllerDefault | ZIKViewRouteTypeMaskViewDefault.
@interface ZIKBlockAnyViewRouter : ZIKBlockViewRouter

@end

/// Block view router for route type: ZIKViewRouteTypeMaskViewControllerDefault | ZIKViewRouteTypeMaskViewDefault | ZIKViewRouteTypeMaskCustom.
@interface ZIKBlockAllViewRouter : ZIKBlockViewRouter

@end

NS_ASSUME_NONNULL_END
