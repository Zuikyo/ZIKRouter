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

extern NSNotificationName kZIKServiceRouterRegisterCompleteNotification;
typedef  BOOL(^ZIKServiceClassValidater)(Class serviceClass);

///Private methods.
@interface ZIKServiceRouter ()

///Is registration all finished.
+ (BOOL)_isLoadFinished;

///Validate all registered service classes of this router class, return the class when the validater return false. Only available when ZIKSERVICEROUTER_CHECK is true.
+ (_Nullable Class)validateRegisteredServiceClasses:(ZIKServiceClassValidater)handler;

+ (void)_swift_registerServiceProtocol:(id)serviceProtocol;

+ (void)_swift_registerConfigProtocol:(id)configProtocol;

@end

extern _Nullable Class _ZIKServiceRouterForService(Protocol *serviceProtocol);

extern _Nullable Class _ZIKServiceRouterForModule(Protocol *configProtocol);

///Private method for ZRouter.
extern _Nullable Class _swift_ZIKServiceRouterForService(id serviceProtocol);
///Private method for ZRouter.
extern _Nullable Class _swift_ZIKServiceRouterForModule(id configProtocol);

NS_ASSUME_NONNULL_END
