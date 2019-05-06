//
//  ZIKRouter-umbrella.h
//  ZIKRouter
//
//  Created by zuik on 2017/7/21.
//  Copyright © 2017 zuik. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import <Foundation/Foundation.h>
#import "ZIKPlatformCapabilities.h"
#import "ZIKRouter.h"
#import "ZIKRouteConfiguration.h"
#import "ZIKRouterType.h"

#import "ZIKRouterRuntime.h"
#import "ZIKServiceRouter.h"
#import "ZIKServiceRouter+Discover.h"
#import "ZIKServiceRouterType.h"
#import "ZIKServiceRouteAdapter.h"
#import "ZIKServiceRoutable.h"
#import "ZIKServiceModuleRoutable.h"
#import "ZIKServiceRoute.h"

#if __has_include("ZIKViewRouter.h")
#import "ZIKViewRouter.h"
#import "ZIKViewRouter+Discover.h"
#import "ZIKViewRouteConfiguration.h"
#import "ZIKViewRouteError.h"
#import "ZIKViewRouterType.h"
#import "ZIKViewRouteAdapter.h"
#import "ZIKViewRoutable.h"
#import "ZIKViewModuleRoutable.h"
#import "ZIKPresentationState.h"
#import "UIView+ZIKViewRouter.h"
#import "UIViewController+ZIKViewRouter.h"
#import "ZIKViewRoute.h"
#endif

#if __has_include("ZIKRouter+URLRouter.h")
#import "ZIKURLRouteResult.h"
#import "ZIKRouter+URLRouter.h"
#endif
#if __has_include("ZIKViewRouter+URLRouter.h")
#import "ZIKViewRouter+URLRouter.h"
#endif

//! Project version number for ZIKRouter.
FOUNDATION_EXPORT double ZIKRouterVersionNumber;

//! Project version string for ZIKRouter.
FOUNDATION_EXPORT const unsigned char ZIKRouterVersionString[];
