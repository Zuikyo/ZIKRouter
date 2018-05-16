//
//  ZIKBlockCustomSubviewRouter.m
//  ZIKRouter
//
//  Created by zuik on 2018/4/20.
//  Copyright © 2018 zuik. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "ZIKBlockCustomSubviewRouter.h"

@implementation ZIKBlockCustomSubviewRouter

+ (ZIKViewRouteTypeMask)supportedRouteTypes {
    return ZIKViewRouteTypeMaskViewDefault | ZIKViewRouteTypeMaskCustom;
}

@end
