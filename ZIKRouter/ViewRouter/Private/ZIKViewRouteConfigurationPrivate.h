//
//  ZIKViewRouteConfigurationPrivate.h
//  ZIKRouter
//
//  Created by zuik on 2017/9/18.
//  Copyright © 2017 zuik. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "ZIKViewRouteConfiguration.h"
#import "ZIKClassCapabilities.h"

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

@class ZIKPresentationState;
@interface ZIKViewRouteSegueConfiguration ()

@property (nonatomic, weak, nullable) XXViewController *segueSource;
@property (nonatomic, weak, nullable) XXViewController *segueDestination;
#if ZIK_HAS_UIKIT
@property (nonatomic, strong, nullable) ZIKPresentationState *destinationStateBeforeRoute;
#endif
@end

NS_ASSUME_NONNULL_END
