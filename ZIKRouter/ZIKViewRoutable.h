//
//  ZIKViewRoutable.h
//  ZIKRouter
//
//  Created by zuik on 2017/8/21.
//  Copyright © 2017年 zuik. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 Protocol inheriting from ZIKViewRoutable can be used to fetch view router with ZIKViewRouterForView()
 @discussion
 ZIKViewRoutable is for:
 1. Let module declaring routable protocol in header
 1. Checking declared protocol is correctly supported in it's view router
 
 It's safe to use protocols inheriting from ZIKViewRoutable with ZIKViewRouterForView() and won't get nil. ZIKViewRouter will validate all ZIKViewRoutable protocols and registered protocols when app launch and ZIKVIEWROUTER_CHECK is enbled. When ZIKVIEWROUTER_CHECK is disabled, the protocol doesn't need to inheriting from ZIKViewRoutable.
 */
@protocol ZIKViewRoutable <NSObject>

@end
