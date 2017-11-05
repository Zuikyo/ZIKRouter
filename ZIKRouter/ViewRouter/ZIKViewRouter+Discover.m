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
#import "ZIKViewRouterPrivate.h"

@implementation ZIKViewRouter (Discover)

+ (Class(^)(Protocol *))forView {
    return ^(Protocol *viewProtocol) {
        return _ZIKViewRouterForView(viewProtocol);
    };
}

+ (Class(^)(Protocol *))forModule {
    return ^(Protocol *configProtocol) {
        return _ZIKViewRouterForModule(configProtocol);
    };
}

@end
