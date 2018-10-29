//
//  ZIKPresentationState.h
//  ZIKRouter
//
//  Created by zuik on 2017/6/19.
//  Copyright © 2017 zuik. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "ZIKPlatformCapabilities.h"
#if ZIK_HAS_UIKIT
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// Detail route type for view controller actually performed. Not for all situations but it's enough to know whether a view controller can do a unwind action(pop/dismiss/removeFromParent). Only the first 4 type can do unwind. You can use other types for debugging purpose.
typedef NS_ENUM(NSInteger,ZIKViewRouteDetailType) {
    ZIKViewRouteDetailTypePush,
    ZIKViewRouteDetailTypePresentModally,
    ZIKViewRouteDetailTypePresentAsPopover,
    ZIKViewRouteDetailTypeAddAsChildViewController,
    ZIKViewRouteDetailTypeChangeParentViewController,
    ZIKViewRouteDetailTypeRemoveFromParentViewController,
    ZIKViewRouteDetailTypeChangeNavigationController,
    ZIKViewRouteDetailTypeParentPushed,
    ZIKViewRouteDetailTypeParentChangeNavigationController,
    ZIKViewRouteDetailTypeChangeOrderInNavigationStack,
    ZIKViewRouteDetailTypeNavigationPopOthers,
    ZIKViewRouteDetailTypeNavigationPushOthers,
    ZIKViewRouteDetailTypeRemoveFromNavigationStack,
    ZIKViewRouteDetailTypeDismissed,
    ZIKViewRouteDetailTypeRemoveAsSplitMaster,
    ZIKViewRouteDetailTypeRemoveAsSplitDetail,
    ZIKViewRouteDetailTypeBecomeSplitMaster,
    ZIKViewRouteDetailTypeBecomeSplitDetail,
    ZIKViewRouteDetailTypeParentChangeSplitController,
    ZIKViewRouteDetailTypeCustom
};

/// State that describes the presentation of a view controller. It's for analyzing the view controller's real route style. Store address pointer by number.
@interface ZIKPresentationState : NSObject
/// the view controller's address.
@property (nonatomic, readonly, strong, nullable) NSNumber *viewController;
@property (nonatomic, readonly, strong, nullable) NSNumber *presentingViewController;
@property (nonatomic, readonly, assign) BOOL isModalPresentationPopover;
@property (nonatomic, readonly, strong, nullable) NSNumber *navigationController;
@property (nonatomic, readonly, strong, nullable) NSArray<NSNumber *> *navigationViewControllers;
@property (nonatomic, readonly, strong, nullable) ZIKPresentationState *navigationControllerState;
@property (nonatomic, readonly, strong, nullable) NSNumber *splitController;
@property (nonatomic, readonly, strong, nullable) NSArray<NSNumber *> *splitViewControllers;
@property (nonatomic, readonly, strong, nullable) NSNumber *parentViewController;
@property (nonatomic, readonly, assign) BOOL isViewLoaded;

- (instancetype)initFromViewController:(UIViewController *)viewController NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

+ (ZIKViewRouteDetailType)detailRouteTypeFromStateBeforeRoute:(ZIKPresentationState *)before stateAfterRoute:(ZIKPresentationState *)after;

+ (NSString *)descriptionOfType:(ZIKViewRouteDetailType)routeType;
@end

NS_ASSUME_NONNULL_END
#endif
