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

/**
 Protocols inheriting from ZIKServiceRoutable can be used to fetch service router with ZIKRouterToService(), and the router's destination certainly conforms to the protocol. See +[ZIKServiceRouter toService].
 
 It's safe to use objc protocols inheriting from ZIKServiceRoutable with ZIKRouterToService() and won't get nil. When ZIKROUTER_CHECK is enabled, ZIKServiceRouter will validate all ZIKServiceRoutable protocols when registration is finished, then we can make sure all routable service protocols have been registered with a router.
 */
@protocol ZIKServiceRoutable

@end
