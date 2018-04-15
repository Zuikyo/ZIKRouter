//
//  ZIKServiceRouterPrivate.h
//  ZIKRouter
//
//  Created by zuik on 2017/10/21.
//  Copyright © 2017 zuik. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "ZIKServiceRouter.h"

NS_ASSUME_NONNULL_BEGIN

@class ZIKServiceRouterType;

///Private methods.
@interface ZIKServiceRouter<__covariant Destination: id, __covariant RouteConfig: ZIKPerformRouteConfiguration *> (Private)

///Is registration all finished.
+ (BOOL)_isRegistrationFinished;

@end

extern ZIKServiceRouterType *_Nullable _ZIKServiceRouterToService(Protocol *serviceProtocol);

extern ZIKServiceRouterType *_Nullable _ZIKServiceRouterToModule(Protocol *configProtocol);

NS_ASSUME_NONNULL_END
