//
//  ZIKBlockCustomViewRouter.m
//  ZIKRouter
//
//  Created by zuik on 2018/4/20.
//  Copyright © 2018 zuik. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "ZIKBlockCustomViewRouter.h"

@implementation ZIKBlockCustomViewRouter

+ (ZIKViewRouteTypeMask)supportedRouteTypes {
    return ZIKViewRouteTypeMaskViewControllerDefault | ZIKViewRouteTypeMaskCustom;
}

@end
