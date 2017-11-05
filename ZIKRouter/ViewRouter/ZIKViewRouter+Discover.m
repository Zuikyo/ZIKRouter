//
//  ZIKViewRouter+Discover.m
//  ZIKRouter
//
//  Created by zuik on 2017/10/27.
//  Copyright © 2017 zuik. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "ZIKViewRouter+Discover.h"

@implementation ZIKViewRouter (Discover)

+ (Class(^)(Protocol *))forView {
    return ^(Protocol *viewProtocol) {
        return ZIKViewRouterForView(viewProtocol);
    };
}

+ (Class(^)(Protocol *))forModule {
    return ^(Protocol *configProtocol) {
        return ZIKViewRouterForConfig(configProtocol);
    };
}

@end
