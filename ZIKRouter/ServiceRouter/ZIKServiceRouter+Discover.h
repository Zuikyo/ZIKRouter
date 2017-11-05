//
//  ZIKServiceRouter+Discover.h
//  ZIKRouter
//
//  Created by zuik on 2017/10/27.
//  Copyright © 2017年 zuik. All rights reserved.
//

#import "ZIKServiceRouter.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZIKServiceRouter (Discover)

@property (nonatomic,class,readonly) Class (^forService)(Protocol *serviceProtocol);
@property (nonatomic,class,readonly) Class (^forModule)(Protocol *configProtocol);

@end

/**
 Get the router class registered with a service class (a ZIKRoutableService) conforming to a unique protocol. Similar to ZIKViewRouterForView().
 
 @param serviceProtocol The protocol conformed by the service. Should be a ZIKServiceRoutable protocol when ZIKSERVICEROUTER_CHECK is enabled. When ZIKSERVICEROUTER_CHECK is disabled, the protocol doesn't need to inheriting from ZIKServiceRoutable.
 @return A router class matched with the service. Return nil if protocol is nil or not declared. There will be an assert failure when result is nil.
 */
extern _Nullable Class ZIKServiceRouterForService(Protocol *serviceProtocol);

/**
 Get the router class combined with a custom ZIKRouteConfiguration conforming to a unique protocol. Similar to ZIKViewRouterForConfig().
 
 @param configProtocol The protocol conformed by defaultConfiguration of router. Should be a ZIKServiceModuleRoutable protocol when ZIKSERVICEROUTER_CHECK is enabled. When ZIKSERVICEROUTER_CHECK is disabled, the protocol doesn't need to inheriting from ZIKServiceModuleRoutable.
 @return A router class matched with the service. Return nil if protocol is nil or not declared. There will be an assert failure when result is nil.
 */
extern _Nullable Class ZIKServiceRouterForConfig(Protocol *configProtocol);

NS_ASSUME_NONNULL_END
