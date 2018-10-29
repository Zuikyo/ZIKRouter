//
//  UIView+ZIKViewRouterPrivate.h
//  ZIKRouter
//
//  Created by zuik on 2017/9/18.
//  Copyright © 2017 zuik. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "ZIKPlatformCapabilities.h"
#if ZIK_HAS_UIKIT
#import <UIKit/UIKit.h>
#else
#import <AppKit/AppKit.h>
#endif

NS_ASSUME_NONNULL_BEGIN

#if ZIK_HAS_UIKIT
@interface UIView ()
#else
@interface NSView ()
#endif
- (void)setZix_routed:(BOOL)routed;
- (void)setZix_removing:(BOOL)removing;
@end

@class ZIKViewRouter;
#if ZIK_HAS_UIKIT
@interface UIView (ZIKViewRouterPrivate)
#else
@interface NSView (ZIKViewRouterPrivate)
#endif
/// Temporary bind auto created router to an UIView when it's not addSubView: by router. Reset to nil when finish routing.
- (__kindof ZIKViewRouter *)zix_destinationViewRouter;
- (void)setZix_destinationViewRouter:(nullable ZIKViewRouter *)viewRouter;
/// Route type when view is routed from a router, will reset to nil when finish routing.
- (nullable NSNumber *)zix_routeTypeFromRouter;
- (void)setZix_routeTypeFromRouter:(nullable NSNumber *)routeType;
@end

NS_ASSUME_NONNULL_END
