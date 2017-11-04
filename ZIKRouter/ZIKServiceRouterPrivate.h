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

@end

///Private method for ZIKRouterSwift.
extern _Nullable Class _Swift_ZIKServiceRouterForService(id serviceProtocol);
///Private method for ZIKRouterSwift.
extern _Nullable Class _Swift_ZIKServiceRouterForConfig(id configProtocol);

NS_ASSUME_NONNULL_END
