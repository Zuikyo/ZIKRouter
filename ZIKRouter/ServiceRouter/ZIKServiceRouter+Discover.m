//
//  ZIKServiceRouter+Discover.m
//  ZIKRouter
//
//  Created by zuik on 2018/4/8.
//  Copyright © 2018 zuik. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "ZIKServiceRouter+Discover.h"
#import "ZIKRouterInternal.h"
#import "ZIKRouterPrivate.h"
#import "ZIKServiceRouteRegistry.h"
#import "ZIKRouteRegistryInternal.h"


ZIKServiceRouterType *_Nullable _ZIKServiceRouterToService(Protocol *serviceProtocol) {
    NSCParameterAssert(serviceProtocol);
    if (!serviceProtocol) {
        [ZIKServiceRouter notifyError_invalidProtocolWithAction:ZIKRouteActionToService errorDescription:@"ZIKServiceRouter.toService() serviceProtocol is nil"];
        NSCAssert1(NO, @"ZIKServiceRouter.toService() serviceProtocol is nil. callStackSymbols: %@",[NSThread callStackSymbols]);
        return nil;
    }
    ZIKRouterType *route = [ZIKServiceRouteRegistry routerToDestination:serviceProtocol];
    if ([route isKindOfClass:[ZIKServiceRouterType class]]) {
        return (ZIKServiceRouterType *)route;
    }
    [ZIKServiceRouter notifyError_invalidProtocolWithAction:ZIKRouteActionToService
                                           errorDescription:@"Didn't find service router for service protocol: %@, this protocol was not registered.",serviceProtocol];
    if (ZIKRouteRegistry.registrationFinished) {
        NSCAssert1(NO, @"Didn't find service router for service protocol: %@, this protocol was not registered.",NSStringFromProtocol(serviceProtocol));
    } else {
        NSCAssert1(NO, @"❌❌❌❌warning: failed to get router for service protocol (%@), because manually registration is not finished yet! If there're modules running before registration is finished, and modules require some routers before you register them, then you should register those required routers earlier.",NSStringFromProtocol(serviceProtocol));
    }
    return nil;
}

ZIKServiceRouterType *_Nullable _ZIKServiceRouterToModule(Protocol *configProtocol) {
    NSCParameterAssert(configProtocol);
    if (!configProtocol) {
        [ZIKServiceRouter notifyError_invalidProtocolWithAction:ZIKRouteActionToServiceModule errorDescription:@"ZIKServiceRouter.toModule() configProtocol is nil"];
        NSCAssert1(NO, @"ZIKServiceRouter.toModule() configProtocol is nil. callStackSymbols: %@",[NSThread callStackSymbols]);
        return nil;
    }
    ZIKRouterType *route = [ZIKServiceRouteRegistry routerToModule:configProtocol];
    if ([route isKindOfClass:[ZIKServiceRouterType class]]) {
        return (ZIKServiceRouterType *)route;
    }
    [ZIKServiceRouter notifyError_invalidProtocolWithAction:ZIKRouteActionToServiceModule
                                           errorDescription:@"Didn't find service router for config protocol: %@, this protocol was not registered.",configProtocol];
    if (ZIKRouteRegistry.registrationFinished) {
        NSCAssert1(NO, @"Didn't find service router for service config protocol: %@, this protocol was not registered.",NSStringFromProtocol(configProtocol));
    } else {
        NSCAssert1(NO, @"❌❌❌❌warning: failed to get router for service config protocol (%@), because manually registration is not finished yet! If there're modules running before registration is finished, and modules require some routers before you register them, then you should register those required routers earlier.",NSStringFromProtocol(configProtocol));
    }
    return nil;
}

ZIKAnyServiceRouterType *_Nullable _ZIKServiceRouterToIdentifier(NSString *identifier) {
    if (!identifier) {
        [ZIKServiceRouter notifyError_invalidProtocolWithAction:ZIKRouteActionToService errorDescription:@"ZIKServiceRouter.toIdentifier() identifier is nil"];
        return nil;
    }
    
    ZIKRouterType *route = [ZIKServiceRouteRegistry routerToIdentifier:identifier];
    if ([route isKindOfClass:[ZIKServiceRouterType class]]) {
        return (ZIKServiceRouterType *)route;
    }
    return nil;
}

@implementation ZIKServiceRouter (Discover)

+ (ZIKServiceRouterType<id, ZIKPerformRouteConfiguration *> *(^)(Protocol<ZIKServiceRoutable> *))toService {
    return ^(Protocol *serviceProtocol) {
        return _ZIKServiceRouterToService(serviceProtocol);
    };
}

+ (ZIKServiceRouterType<id, ZIKPerformRouteConfiguration *> *(^)(Protocol<ZIKServiceModuleRoutable> *))toModule {
    return ^(Protocol *configProtocol) {
        return _ZIKServiceRouterToModule(configProtocol);
    };
}

+ (NSArray<ZIKAnyServiceRouterType *> *(^)(Class))routersToClass {
    return ^(Class destinationClass) {
        NSMutableArray<ZIKAnyServiceRouterType *> *routers = [NSMutableArray array];
        NSParameterAssert([destinationClass conformsToProtocol:@protocol(ZIKRoutableService)]);
        [ZIKServiceRouteRegistry enumerateRoutersForDestinationClass:[destinationClass class] handler:^(ZIKRouterType * _Nonnull route) {
            ZIKServiceRouterType *r = (ZIKServiceRouterType *)route;
            if (r) {
                [routers addObject:r];
            }
        }];
        return routers;
    };
}

+ (ZIKAnyServiceRouterType *(^)(NSString *))toIdentifier {
    return ^(NSString *identifier) {
        ZIKAnyServiceRouterType *routerType = _ZIKServiceRouterToIdentifier(identifier);
        if (routerType) {
            return routerType;
        }
        [ZIKServiceRouter notifyError_invalidProtocolWithAction:ZIKRouteActionToService
                                               errorDescription:@"Didn't find service router for identifier: %@, this identifier was not registered.",identifier];
        if (ZIKRouteRegistry.registrationFinished) {
            NSCAssert1(NO, @"Didn't find service router for identifier: %@, this identifier was not registered.",identifier);
        } else {
            NSCAssert1(NO, @"❌❌❌❌warning: failed to get router for service identifier (%@), because manually registration is not finished yet! If there're modules running before registration is finished, and modules require some routers before you register them, then you should register those required routers earlier.",identifier);
        }
        return routerType;
    };
}

@end
