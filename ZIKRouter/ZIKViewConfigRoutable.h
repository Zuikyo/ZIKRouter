//
//  ZIKViewConfigRoutable.h
//  ZIKRouter
//
//  Created by zuik on 2017/8/21.
//  Copyright © 2017年 zuik. All rights reserved.
//

#import <Foundation/Foundation.h>

///Protocol inheriting from ZIKViewConfigRoutable can be used to fetch view router with ZIKViewRouterForConfig()

/**
 Protocol inheriting from ZIKViewConfigRoutable can be used to fetch view router with ZIKViewRouterForConfig()
 @discussion
 ZIKViewConfigRoutable is for:
 1. Let module declaring routable protocol in header
 1. Checking declared protocol is correctly supported in it's view router
 
 It's safe to use protocols inheriting from ZIKViewConfigRoutable with ZIKViewRouterForConfig() and won't get nil. ZIKViewRouter will validate all ZIKViewConfigRoutable protocols and registered protocols when app launch and ZIKVIEWROUTER_CHECK is enbled. When ZIKVIEWROUTER_CHECK is disabled, the protocol doesn't need to inheriting from ZIKViewConfigRoutable.
 */
@protocol ZIKViewConfigRoutable <NSObject>

@end
