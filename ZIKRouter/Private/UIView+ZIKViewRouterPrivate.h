//
//  UIView+ZIKViewRouterPrivate.h
//  ZIKRouter
//
//  Created by zuik on 2017/9/18.
//  Copyright © 2017年 zuik. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIView ()
- (void)setZIK_routed:(BOOL)routed;
@end

@class ZIKViewRouter;
@interface UIView (ZIKViewRouterPrivate)
///Temporary bind auto created router to a UIView when it's not addSubView: by router. Reset to nil when view is removed.
- (__kindof ZIKViewRouter *)ZIK_destinationViewRouter;
- (void)setZIK_destinationViewRouter:(nullable ZIKViewRouter *)viewRouter;
///Route type when view is routed from a router, will reset to nil when view is removed
- (nullable NSNumber *)ZIK_routeTypeFromRouter;
- (void)setZIK_routeTypeFromRouter:(nullable NSNumber *)routeType;
@end

NS_ASSUME_NONNULL_END
