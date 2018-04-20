//
//  ZIKBlockCustomViewRouter.m
//  ZIKRouter
//
//  Created by zuik on 2018/4/20.
//  Copyright © 2018年 zuik. All rights reserved.
//

#import "ZIKBlockCustomViewRouter.h"

@implementation ZIKBlockCustomViewRouter

+ (ZIKViewRouteTypeMask)supportedRouteTypes {
    return ZIKViewRouteTypeMaskUIViewControllerDefault | ZIKViewRouteTypeMaskCustom;
}

@end
