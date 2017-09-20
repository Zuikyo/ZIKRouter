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
 Protocol inheriting from ZIKViewRoutable can be used to fetch view router with ZIKViewRouterForView()
 @discussion
 ZIKViewRoutable is for:
 1. Let module declaring routable protocol in header
 1. Checking declared protocol is correctly supported in it's view router
 
 It's safe to use protocols inheriting from ZIKViewRoutable with ZIKViewRouterForView() and won't get nil. ZIKViewRouter will validate all ZIKViewRoutable protocols and registered protocols when app launch and ZIKVIEWROUTER_CHECK is enbled. When ZIKVIEWROUTER_CHECK is disabled, the protocol doesn't need to inheriting from ZIKViewRoutable.
 
 In Swift, you have to use @objc protocol for ZIKViewRouterForView() and other similar functions. If you don't want to use @objc protocol in Swift, you can get the router class by dependency injection.
 */
@protocol ZIKViewRoutable <NSObject>

@end
