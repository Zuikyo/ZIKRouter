//
//  ZIKViewRouter+Discover.m
//  ZIKRouter
//
//  Created by zuik on 2017/10/27.
//  Copyright © 2017年 zuik. All rights reserved.
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
