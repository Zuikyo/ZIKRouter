//
//  UIStoryboardSegue+ZIKViewRouterPrivate.h
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
@interface UIStoryboardSegue (ZIKViewRouterPrivate)
#else
@interface NSStoryboardSegue (ZIKViewRouterPrivate)
#endif
- (nullable Class)zix_currentClassCallingPerform;
- (void)setZix_currentClassCallingPerform:(nullable Class)vcClass;
@end

NS_ASSUME_NONNULL_END
