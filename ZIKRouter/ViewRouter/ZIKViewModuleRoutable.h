//
//  ZIKViewModuleRoutable.h
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
 Protocols inheriting from ZIKViewModuleRoutable can be used to fetch view router with ZIKRouterToViewModule(), and the router's configuration certainly conforms to the protocol. See +[ZIKViewRouter toModule].
 @discussion
 Why do you need a module config protocol? When a view module is not only a single UIViewController, but also with other services and models, then you can't prepare the module's services or passing any models through a simple view protocol. Because the UIViewController should not access to other services or models in the module. Now with ZIKViewModuleRoutable, you can configure the router's default configuration, then configure the module's services and models with the configuration in the router.
 
 It's safe to use objc protocols inheriting from ZIKViewModuleRoutable with ZIKRouterToViewModule() and won't get nil. When ZIKROUTER_CHECK is enabled, ZIKViewRouter will validate all ZIKViewModuleRoutable protocols when registration is finished, then we can make sure all routable module protocols have been registered with a router.
 */
@protocol ZIKViewModuleRoutable

@end
