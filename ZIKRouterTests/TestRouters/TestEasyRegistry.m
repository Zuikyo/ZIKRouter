//
//  TestEasyRegistry.m
//  ZIKRouterTests
//
//  Created by zuik on 2019/1/24.
//  Copyright © 2019 zuik. All rights reserved.
//

#import "TestEasyRegistry.h"
@import ZIKRouter.Internal;
#import "EasyServiceInput.h"
#import "AService.h"
#import "EasyAViewInput.h"
#import "AViewController.h"

@implementation TestEasyRegistry

+ (void)registerRoutableDestination {
    [ZIKServiceRouter registerServiceProtocol:ZIKRoutable(EasyServiceInput) forMakingService:[AService class]];
    [ZIKViewRouter registerViewProtocol:ZIKRoutable(EasyAViewInput) forMakingView:[AViewController class]];
}

@end
