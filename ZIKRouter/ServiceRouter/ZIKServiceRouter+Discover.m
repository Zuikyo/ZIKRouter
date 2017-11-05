//
//  ZIKServiceRouter+Discover.m
//  ZIKRouter
//
//  Created by zuik on 2017/10/27.
//  Copyright © 2017 zuik. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
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
