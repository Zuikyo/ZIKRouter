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
#import "ZIKViewRouterPrivate.h"

@implementation ZIKViewRouter (Discover)

+ (ZIKDestinationViewRouterType<id<ZIKViewRoutable>, ZIKViewRouteConfiguration *> *(^)(Protocol *))toView {
    return ^(Protocol *viewProtocol) {
        return _ZIKViewRouterToView(viewProtocol);
    };
}

+ (ZIKModuleViewRouterType<id<ZIKRoutableView>, id<ZIKViewModuleRoutable>, ZIKViewRouteConfiguration *> *(^)(Protocol *))toModule {
    return ^(Protocol *configProtocol) {
        return _ZIKViewRouterToModule(configProtocol);
    };
}

+ (Class(^)(Protocol<ZIKViewRoutable> *))classToView {
    return ^(Protocol *viewProtocol) {
        return _ZIKViewRouterToView(viewProtocol);
    };
}

+ (Class(^)(Protocol<ZIKViewModuleRoutable> *))classToModule {
    return ^(Protocol *configProtocol) {
        return _ZIKViewRouterToModule(configProtocol);
    };
}

@end


#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wincomplete-implementation"

@implementation ZIKViewRouterType
@end

@implementation ZIKDestinationViewRouterType
@end

@implementation ZIKModuleViewRouterType
@end

#pragma clang diagnostic pop
