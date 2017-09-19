//
//  UIStoryboardSegue+ZIKViewRouterPrivate.h
//  ZIKRouter
//
//  Created by zuik on 2017/9/18.
//  Copyright © 2017年 zuik. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIStoryboardSegue (ZIKViewRouterPrivate)
- (nullable Class)ZIK_currentClassCallingPerform;
- (void)setZIK_currentClassCallingPerform:(nullable Class)vcClass;
@end

NS_ASSUME_NONNULL_END
