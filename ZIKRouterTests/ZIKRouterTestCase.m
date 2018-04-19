//
//  ZIKRouterTestCase.m
//  ZIKRouterTests
//
//  Created by zuik on 2018/4/19.
//  Copyright © 2018 zuik. All rights reserved.
//
#import "ZIKRouterTestCase.h"

@interface ZIKRouterTestCase()
@property (nonatomic, strong, nullable) ZIKRouter *strongRouter;
@property (nonatomic, strong) XCTestExpectation *leaveTestExpectation;
@end

@implementation ZIKRouterTestCase

- (void)setRouter:(ZIKRouter *)router {
    _router = router;
    self.strongRouter = router;
}

- (void)enterTest {
    self.leaveTestExpectation = [self expectationWithDescription:@"Leave test"];
}

- (void)leaveTest {
    self.strongRouter = nil;
    [self.leaveTestExpectation fulfill];
}

+ (BOOL)completeSynchronously {
    return YES;
}

- (void)handle:(void(^)(void))block {
    if (block == nil) {
        return;
    }
    if ([[self class] completeSynchronously]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            block();
        });
    } else {
        block();
    }
}

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
    NSAssert(self.router == nil, @"Test router is not released");
    TestConfig.routeShouldFail = NO;
}

@end
