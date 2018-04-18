//
//  TestConfig.m
//  ZIKRouterTests
//
//  Created by zuik on 2018/4/18.
//  Copyright © 2018 zuik. All rights reserved.
//

#import "TestConfig.h"

static BOOL _routeShouldFail;

@implementation TestConfig

+ (BOOL)routeShouldFail {
    return _routeShouldFail;
}

+ (void)setRouteShouldFail:(BOOL)routeShouldFail {
    _routeShouldFail = routeShouldFail;
}

@end
