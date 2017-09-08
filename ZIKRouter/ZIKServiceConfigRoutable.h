//
//  ZIKServiceConfigRoutable.h
//  ZIKRouter
//
//  Created by zuik on 2017/8/21.
//  Copyright © 2017年 zuik. All rights reserved.
//

#import <Foundation/Foundation.h>

///Protocol inheriting from ZIKServiceConfigRoutable can be used to fetch service router with ZIKServiceRouterForConfig()

/**
 Protocol inheriting from ZIKServiceConfigRoutable can be used to fetch service router with ZIKServiceRouterForConfig()
 @discussion
 ZIKServiceConfigRoutable is for:
 1. Let module declaring routable protocol in header
 1. Checking declared protocol is correctly supported in it's service router
 
 It's safe to use protocols inheriting from ZIKServiceConfigRoutable with ZIKServiceRouterForConfig() and won't get nil. ZIKServiceRouter will validate all ZIKServiceConfigRoutable protocols and registered protocols when app launch and ZIKSERVICEROUTER_CHECK is enbled. When ZIKSERVICEROUTER_CHECK is disabled, the protocol doesn't need to inheriting from ZIKServiceConfigRoutable.
 */
@protocol ZIKServiceConfigRoutable <NSObject>

@end
