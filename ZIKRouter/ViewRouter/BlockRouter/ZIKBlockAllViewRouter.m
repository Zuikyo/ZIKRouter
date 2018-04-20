//
//  ZIKBlockAllViewRouter.m
//  ZIKRouter
//
//  Created by zuik on 2018/4/20.
//  Copyright © 2018年 zuik. All rights reserved.
//

#import "ZIKBlockAllViewRouter.h"

@implementation ZIKBlockAllViewRouter

+ (ZIKViewRouteTypeMask)supportedRouteTypes {
    return ZIKViewRouteTypeMaskUIViewControllerDefault | ZIKViewRouteTypeMaskUIViewDefault | ZIKViewRouteTypeMaskCustom;
}

@end
