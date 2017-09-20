//
//  ZIKServiceRoutable.h
//  ZIKRouter
//
//  Created by zuik on 2017/8/21.
//  Copyright © 2017 zuik. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import <Foundation/Foundation.h>

///Protocol inheriting from ZIKServiceRoutable can be used to fetch service router with ZIKServiceRouterForService()

/**
 Protocol inheriting from ZIKServiceRoutable can be used to fetch service router with ZIKServiceRouterForService()
 @discussion
 ZIKServiceRoutable is for:
 1. Let module declaring routable protocol in header
 1. Checking declared protocol is correctly supported in it's service router
 
 It's safe to use protocols inheriting from ZIKServiceRoutable with ZIKServiceRouterForService() and won't get nil. ZIKServiceRouter will validate all ZIKServiceRoutable protocols and registered protocols when app launch and ZIKSERVICEROUTER_CHECK is enbled. When ZIKSERVICEROUTER_CHECK is disabled, the protocol doesn't need to inheriting from ZIKServiceRoutable.
 */
@protocol ZIKServiceRoutable <NSObject>

@end
