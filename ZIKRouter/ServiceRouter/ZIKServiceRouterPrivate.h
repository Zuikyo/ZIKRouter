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

typedef  BOOL(^ZIKServiceClassValidater)(Class serviceClass);

///Private methods.
@interface ZIKServiceRouter (Private)

+ (BOOL)shouldCheckImplementation;

///Is registration all finished.
+ (BOOL)_isAutoRegistrationFinished;

///Validate all registered service classes of this router class, return the class when the validater return false. Only available when ZIKROUTER_CHECK is true.
+ (_Nullable Class)validateRegisteredServiceClasses:(ZIKServiceClassValidater)handler;

+ (void)_callbackGlobalErrorHandlerWithRouter:(nullable __kindof ZIKServiceRouter *)router action:(ZIKRouteAction)action error:(NSError *)error;

+ (void)_swift_registerServiceProtocol:(id)serviceProtocol;

+ (void)_swift_registerConfigProtocol:(id)configProtocol;

@end

extern _Nullable Class _ZIKServiceRouterToService(Protocol *serviceProtocol);

extern _Nullable Class _ZIKServiceRouterToModule(Protocol *configProtocol);

///Private method for ZRouter.
extern _Nullable Class _swift_ZIKServiceRouterToService(id serviceProtocol);
///Private method for ZRouter.
extern _Nullable Class _swift_ZIKServiceRouterToModule(id configProtocol);

NS_ASSUME_NONNULL_END
