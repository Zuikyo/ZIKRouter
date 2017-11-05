//
//  ZIKServiceRouter+Discover.h
//  ZIKRouter
//
//  Created by zuik on 2017/10/27.
//  Copyright © 2017 zuik. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "ZIKServiceRouter.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZIKServiceRouter (Discover)

/**
 Get the router class registered with a service protocol.
 
 The parameter serviceProtocol of the block is: the protocol conformed by the service. Should be a ZIKServiceRoutable protocol when ZIKSERVICEROUTER_CHECK is enabled. When ZIKSERVICEROUTER_CHECK is disabled, the protocol doesn't need to inheriting from ZIKServiceRoutable.
 
 The return Class of the block is: a router class matched with the service. Return nil if protocol is nil or not declared. There will be an assert failure when result is nil.
 */
@property (nonatomic,class,readonly) Class _Nullable (^forService)(Protocol *serviceProtocol);

/**
 Get the router class combined with a custom ZIKRouteConfiguration conforming to a unique protocol.
 
 The parameter configProtocol of the block is: the protocol conformed by defaultConfiguration of router. Should be a ZIKServiceModuleRoutable protocol when ZIKSERVICEROUTER_CHECK is enabled. When ZIKSERVICEROUTER_CHECK is disabled, the protocol doesn't need to inheriting from ZIKServiceModuleRoutable.
 The return Class of the block is: a router class matched with the service. Return nil if protocol is nil or not declared. There will be an assert failure when result is nil.
 */
@property (nonatomic,class,readonly) Class _Nullable (^forModule)(Protocol *configProtocol);

@end

NS_ASSUME_NONNULL_END
