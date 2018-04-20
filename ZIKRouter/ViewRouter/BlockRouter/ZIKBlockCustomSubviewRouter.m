//
//  ZIKBlockCustomSubviewRouter.m
//  ZIKRouter
//
//  Created by zuik on 2018/4/20.
//  Copyright © 2018年 zuik. All rights reserved.
//

#import "ZIKBlockCustomSubviewRouter.h"

@implementation ZIKBlockCustomSubviewRouter

+ (ZIKViewRouteTypeMask)supportedRouteTypes {
    return ZIKViewRouteTypeMaskUIViewDefault | ZIKViewRouteTypeMaskCustom;
}

@end
