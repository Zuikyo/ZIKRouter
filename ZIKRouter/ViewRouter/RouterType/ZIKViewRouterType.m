//
//  ZIKViewRouterType.m
//  ZIKRouter
//
//  Created by zuik on 2018/4/8.
//  Copyright © 2018 zuik. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "ZIKViewRouterType.h"
#import "ZIKViewRoute.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wincomplete-implementation"

@implementation ZIKViewRouterType

- (instancetype)initWithRouterClass:(Class)routerClass {
    if ([routerClass class] != routerClass) {
        return nil;
    }
    if ([routerClass isSubclassOfClass:[ZIKViewRouter class]] == NO) {
        return nil;
    }
    
    if (self = [super initWithRouterClass:routerClass]) {
        
    }
    return self;
}

- (nullable instancetype)initWithRoute:(ZIKViewRoute *)route {
    if ([route isKindOfClass:[ZIKViewRoute class]] == NO) {
        return nil;
    }
    if (self = [super initWithRoute:route]) {
        
    }
    return self;
}

@end

#pragma clang diagnostic pop
