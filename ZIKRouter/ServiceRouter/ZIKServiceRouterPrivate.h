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

+ (BOOL)shouldCheckImplementation;

///Is registration all finished.
+ (BOOL)_isRegistrationFinished;

+ (void)_callbackGlobalErrorHandlerWithRouter:(nullable __kindof ZIKServiceRouter *)router action:(ZIKRouteAction)action error:(NSError *)error;
+ (void)_callbackError_invalidProtocolWithAction:(ZIKRouteAction)action errorDescription:(NSString *)format ,...;

+ (void)_swift_registerServiceProtocol:(id)serviceProtocol;

+ (void)_swift_registerConfigProtocol:(id)configProtocol;

@end

extern ZIKServiceRouterType *_Nullable _ZIKServiceRouterToService(Protocol *serviceProtocol);

extern ZIKServiceRouterType *_Nullable _ZIKServiceRouterToModule(Protocol *configProtocol);

///Private method for ZRouter.
extern ZIKServiceRouterType *_Nullable _swift_ZIKServiceRouterToService(id serviceProtocol);
///Private method for ZRouter.
extern ZIKServiceRouterType *_Nullable _swift_ZIKServiceRouterToModule(id configProtocol);

NS_ASSUME_NONNULL_END
