//
//  ZIKServiceRouterType.m
//  ZIKRouter
//
//  Created by zuik on 2018/4/8.
//  Copyright © 2018 zuik. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "ZIKServiceRouterType.h"
#import "ZIKServiceRouter.h"
#import "ZIKServiceRoute.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wincomplete-implementation"

@implementation ZIKServiceRouterType

- (nullable instancetype)initWithRouterClass:(Class)routerClass {
    if ([routerClass class] != routerClass) {
        return nil;
    }
    if ([routerClass isSubclassOfClass:[ZIKServiceRouter class]] == NO) {
        return nil;
    }
    if (self = [super initWithRouterClass:routerClass]) {
        
    }
    return self;
}

- (nullable instancetype)initWithRoute:(ZIKServiceRoute *)route {
    if ([route isKindOfClass:[ZIKServiceRoute class]] == NO) {
        return nil;
    }
    if (self = [super initWithRoute:route]) {
        
    }
    return self;
}

@end

#pragma clang diagnostic pop
