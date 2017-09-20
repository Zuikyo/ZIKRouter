//
//  ZIKViewRouteConfiguration+Private.h
//  ZIKRouter
//
//  Created by zuik on 2017/9/18.
//  Copyright © 2017 zuik. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "ZIKViewRouteConfiguration.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZIKViewRouteConfiguration ()
@property (nonatomic, assign) BOOL autoCreated;
@property (nonatomic, strong, nullable) ZIKViewRouteSegueConfiguration *segueConfiguration;
@property (nonatomic, strong, nullable) ZIKViewRoutePopoverConfiguration *popoverConfiguration;
@end

@interface ZIKViewRoutePopoverConfiguration ()
@property (nonatomic, assign) BOOL sourceRectConfiged;
@property (nonatomic, assign) BOOL popoverLayoutMarginsConfiged;
@end

@interface ZIKViewRouteSegueConfiguration ()
@property (nonatomic, weak, nullable) UIViewController *segueSource;
@property (nonatomic, weak, nullable) UIViewController *segueDestination;
@property (nonatomic, strong, nullable) ZIKPresentationState *destinationStateBeforeRoute;
@end

NS_ASSUME_NONNULL_END
