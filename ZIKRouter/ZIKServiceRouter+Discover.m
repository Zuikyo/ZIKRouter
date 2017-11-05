//
//  ZIKServiceRouter+Discover.m
//  ZIKRouter
//
//  Created by zuik on 2017/10/27.
//  Copyright © 2017 zuik. All rights reserved.
//

#import "ZIKServiceRouter+Discover.h"

@implementation ZIKServiceRouter (Discover)

+ (Class(^)(Protocol *))forService {
    return ^(Protocol *serviceProtocol) {
        return ZIKServiceRouterForService(serviceProtocol);
    };
}

+ (Class(^)(Protocol *))forModule {
    return ^(Protocol *configProtocol) {
        return ZIKServiceRouterForConfig(configProtocol);
    };
}

@end
