//
//  ZIKRouterTestCase.h
//  ZIKRouter
//
//  Created by zuik on 2018/4/19.
//  Copyright © 2018 zuik. All rights reserved.
//
#import <XCTest/XCTest.h>
#import "TestConfig.h"
@import ZIKRouter;

@interface ZIKRouterTestCase : XCTestCase
@property (nonatomic, weak, nullable) ZIKRouter *router;
@property (nonatomic, weak, nullable) id destination;

- (void)enterTest;
- (void)leaveTest;

/// If the router complete synchronously, self.router is not set when completion handler is called, then access self.router in handler block will fail. Use this to access self.router in block.
- (void)handle:(void(^)(void))block;

@end
