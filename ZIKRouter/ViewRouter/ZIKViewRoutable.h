//
//  ZIKViewRoutable.h
//  ZIKRouter
//
//  Created by zuik on 2017/8/21.
//  Copyright © 2017 zuik. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import <Foundation/Foundation.h>

/**
 Protocols inheriting from ZIKViewRoutable can be used to fetch view router with ZIKRouterToView(), and the router's destination certainly conforms to the protocol. See +[ZIKViewRouter toView].
 @discussion
 ZIKViewRoutable is for:
 
 1. Let module declare routable protocol in header as the module's provided interface
 
 2. Checking whether declared protocol is correctly supported in its view router
 
 It's safe to use objc protocols inheriting from ZIKViewRoutable with ZIKRouterToView() and won't get nil. When ZIKROUTER_CHECK is enabled, ZIKViewRouter will validate all ZIKViewRoutable protocols when registration is finished, then we can make sure all routable view protocols have been registered with a router.
 */
@protocol ZIKViewRoutable

@end

