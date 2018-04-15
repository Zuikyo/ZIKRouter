//
//  SourceViewRouter.m
//  ZIKRouterDemoTests
//
//  Created by zuik on 2018/4/11.
//  Copyright © 2018年 zuik. All rights reserved.
//

#import "SourceViewRouter.h"
@import ZIKRouter.Internal;

DeclareRoutableView(SourceViewController, SourceViewRouter)
@implementation SourceViewRouter

+ (void)registerRoutableDestination {
    [self registerView:[SourceViewController class]];
}

- (id)destinationWithConfiguration:(ZIKPerformRouteConfiguration *)configuration {
    return [[SourceViewController alloc] init];
}

@end
