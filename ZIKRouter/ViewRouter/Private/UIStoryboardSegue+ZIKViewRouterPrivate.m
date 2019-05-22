//
//  UIStoryboardSegue+ZIKViewRouterPrivate.m
//  ZIKRouter
//
//  Created by zuik on 2017/9/18.
//  Copyright © 2017 zuik. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "UIStoryboardSegue+ZIKViewRouterPrivate.h"
#import <objc/runtime.h>

#if ZIK_HAS_UIKIT
@implementation UIStoryboardSegue (ZIKViewRouterPrivate)
#else
@implementation NSStoryboardSegue (ZIKViewRouterPrivate)
#endif
- (nullable Class)zix_currentClassCallingPerform {
    return objc_getAssociatedObject(self, @selector(zix_currentClassCallingPerform));
}
- (void)setZix_currentClassCallingPerform:(nullable Class)vcClass {
    objc_setAssociatedObject(self, @selector(zix_currentClassCallingPerform), vcClass, OBJC_ASSOCIATION_RETAIN);
}
@end
