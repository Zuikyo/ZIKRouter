//
//  ZIKViewRouter+Discover.m
//  ZIKRouter
//
//  Created by zuik on 2018/1/22.
//  Copyright © 2017 zuik. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "ZIKViewRouter+Discover.h"
#import "ZIKRouterInternal.h"
#import "ZIKViewRouterInternal.h"
#import "ZIKViewRouteRegistry.h"
#import "ZIKRouteRegistryInternal.h"

ZIKAnyViewRouterType *_Nullable _ZIKViewRouterToView(Protocol *viewProtocol) {
    NSCParameterAssert(viewProtocol);
    if (!viewProtocol) {
        [ZIKViewRouter notifyError_invalidProtocolWithAction:ZIKRouteActionToView errorDescription:@"ZIKViewRouter.toView() viewProtocol is nil"];
        return nil;
    }
    ZIKRouterType *route = [ZIKViewRouteRegistry routerToDestination:viewProtocol];
    if ([route isKindOfClass:[ZIKViewRouterType class]]) {
        return (ZIKViewRouterType *)route;
    }
    [ZIKViewRouter notifyError_invalidProtocolWithAction:ZIKRouteActionToView
                                        errorDescription:@"Didn't find view router for view protocol: %@, this protocol was not registered.",viewProtocol];
    if (ZIKRouteRegistry.registrationFinished) {
        NSCAssert1(NO, @"Didn't find view router for view protocol: %@, this protocol was not registered.",NSStringFromProtocol(viewProtocol));
    } else {
        NSCAssert1(NO, @"❌❌❌❌warning: failed to get router for view protocol (%@), because manually registration is not finished yet! If there're modules running before registration is finished, and modules require some routers before you register them, then you should register those required routers earlier.",NSStringFromProtocol(viewProtocol));
    }
    return nil;
}

ZIKAnyViewRouterType *_Nullable _ZIKViewRouterToModule(Protocol *configProtocol) {
    NSCParameterAssert(configProtocol);
    if (!configProtocol) {
        [ZIKViewRouter notifyError_invalidProtocolWithAction:ZIKRouteActionToViewModule errorDescription:@"ZIKViewRouter.toModule() configProtocol is nil"];
        return nil;
    }
    
    ZIKRouterType *route = [ZIKViewRouteRegistry routerToModule:configProtocol];
    if ([route isKindOfClass:[ZIKViewRouterType class]]) {
        return (ZIKViewRouterType *)route;
    }
    [ZIKViewRouter notifyError_invalidProtocolWithAction:ZIKRouteActionToViewModule
                                        errorDescription:@"Didn't find view router for config protocol: %@, this protocol was not registered.",configProtocol];
    if (ZIKRouteRegistry.registrationFinished) {
        NSCAssert1(NO, @"Didn't find view router for config protocol: %@, this protocol was not registered.",NSStringFromProtocol(configProtocol));
    } else {
        NSCAssert1(NO, @"❌❌❌❌warning: failed to get router for view config protocol (%@), because manually registration is not finished yet! If there're modules running before registration is finished, and modules require some routers before you register them, then you should register those required routers earlier.",NSStringFromProtocol(configProtocol));
    }
    return nil;
}

@implementation ZIKViewRouter (Discover)

+ (ZIKDestinationViewRouterType<id<ZIKViewRoutable>, ZIKViewRouteConfiguration *> *(^)(Protocol *))toView {
    return ^(Protocol *viewProtocol) {
        return (ZIKDestinationViewRouterType *)_ZIKViewRouterToView(viewProtocol);
    };
}

+ (ZIKModuleViewRouterType<id<ZIKRoutableView>, id<ZIKViewModuleRoutable>, ZIKViewRouteConfiguration *> *(^)(Protocol *))toModule {
    return ^(Protocol *configProtocol) {
        return (ZIKModuleViewRouterType *)_ZIKViewRouterToModule(configProtocol);
    };
}

@end


#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wincomplete-implementation"

@implementation ZIKDestinationViewRouterType
@end

@implementation ZIKModuleViewRouterType
@end

#pragma clang diagnostic pop
