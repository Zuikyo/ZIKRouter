//
//  ZIKServiceModuleRoutable.h
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
 Protocols inheriting from ZIKServiceModuleRoutable can be used to fetch service router with ZIKRouterToServiceModule(), and the router's configuration certainly conforms to the protocol. See +[ZIKServiceRouter toModule].
 @discussion
 Why do you need a module config protocol? When a service module is not only a single service object, but also with other services and models, then you can't prepare the module's services or passing models through a simple service protocol. Because the destination service object may can't access to other services or models in the module. Now with ZIKServiceModuleRoutable, you can configure the router's default configuration, then configure the module's services and models with the configuration in the router.
 
 It's safe to use objc protocols inheriting from ZIKServiceModuleRoutable with ZIKRouterToServiceModule() and won't get nil. When ZIKROUTER_CHECK is enabled, ZIKServiceRouter will validate all ZIKServiceModuleRoutable protocols when registration is finished, then we can make sure all routable module protocols have been registered with a router.
 */
@protocol ZIKServiceModuleRoutable

@end
