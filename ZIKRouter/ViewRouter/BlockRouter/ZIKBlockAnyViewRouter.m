//
//  ZIKBlockAnyViewRouter.m
//  ZIKRouter
//
//  Created by zuik on 2018/4/20.
//  Copyright © 2018 zuik. All rights reserved.
//

#import "ZIKBlockAnyViewRouter.h"

@implementation ZIKBlockAnyViewRouter

+ (ZIKViewRouteTypeMask)supportedRouteTypes {
    return ZIKViewRouteTypeMaskUIViewControllerDefault | ZIKViewRouteTypeMaskUIViewDefault;
}

@end
