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

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIStoryboardSegue (ZIKViewRouterPrivate)
- (nullable Class)zix_currentClassCallingPerform;
- (void)setZix_currentClassCallingPerform:(nullable Class)vcClass;
@end

NS_ASSUME_NONNULL_END
