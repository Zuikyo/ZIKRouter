//
//  UIStoryboardSegue+ZIKViewRouterPrivate.m
//  ZIKRouter
//
//  Created by zuik on 2017/9/18.
//  Copyright © 2017年 zuik. All rights reserved.
//

#import "UIStoryboardSegue+ZIKViewRouterPrivate.h"
#import <objc/runtime.h>

@implementation UIStoryboardSegue (ZIKViewRouterPrivate)
- (nullable Class)ZIK_currentClassCallingPerform {
    return objc_getAssociatedObject(self, "ZIK_CurrentClassCallingPerform");
}
- (void)setZIK_currentClassCallingPerform:(nullable Class)vcClass {
    objc_setAssociatedObject(self, "ZIK_CurrentClassCallingPerform", vcClass, OBJC_ASSOCIATION_RETAIN);
}
@end
