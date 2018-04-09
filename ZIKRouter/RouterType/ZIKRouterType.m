//
//  ZIKRouterType.m
//  ZIKRouter
//
//  Created by zuik on 2018/1/21.
//  Copyright © 2017 zuik. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "ZIKRouterType.h"
#import "ZIKRoute.h"
#import "ZIKRouter.h"

@interface ZIKRouterType()
@property (nonatomic, copy) NSString *routerClassName;
@property (nonatomic, strong) Class routerClass;
@property (nonatomic, strong) ZIKRoute *route;
@end

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wincomplete-implementation"

@implementation ZIKRouterType

- (nullable instancetype)initWithRouterClass:(Class)routerClass {
    if ([routerClass class] != routerClass) {
        return nil;
    }
    if ([routerClass isSubclassOfClass:[ZIKRouter class]] == NO) {
        return nil;
    }
    if (self = [super init]) {
        _routerClass = routerClass;
        _routerClassName = NSStringFromClass(routerClass);
    }
    return self;
}

- (nullable instancetype)initWithRoute:(ZIKRoute *)route {
    NSParameterAssert(route);
    if (self = [super init]) {
        _route = route;
    }
    return self;
}

+ (nullable instancetype)tryMakeRouterTypeForRoute:(id)route {
    ZIKRouterType *routerType = [[self alloc] initWithRouterClass:route];
    if (routerType) {
        return routerType;
    }
    routerType = [[self alloc] initWithRoute:route];
    if (routerType) {
        return routerType;
    }
    return nil;
}

- (Class)routerClass {
    if (_routerClass == nil) {
        if (_routerClassName) {
            return NSClassFromString(_routerClassName);
        }
    }
    return _routerClass;
}

- (BOOL)respondsToSelector:(SEL)aSelector {
    if ([super respondsToSelector:aSelector]) {
        return YES;
    }
    if (self.routerClass) {
        return [self.routerClass respondsToSelector:aSelector];
    }
    if (self.route) {
        return [self.route respondsToSelector:aSelector];
    }
    return NO;
}

- (id)forwardingTargetForSelector:(SEL)aSelector {
    if (self.routerClass) {
        return self.routerClass;
    }
    if (self.route) {
        return self.route;
    }
    return nil;
}

- (NSString *)description {
    if (self.routerClass) {
        return [NSString stringWithFormat:@"%@: routerClass: %@",[super description], NSStringFromClass(self.routerClass)];
    } else {
        return [NSString stringWithFormat:@"%@: route: %@",[super description], self.route];
    }
}

@end

#pragma clang diagnostic pop
