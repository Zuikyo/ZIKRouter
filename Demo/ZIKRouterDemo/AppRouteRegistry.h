//
//  AppRouteRegistry.h
//  ZIKRouterDemo
//
//  Created by zuik on 2018/4/6.
//  Copyright © 2018 zuik. All rights reserved.
//

#import <Foundation/Foundation.h>

/// Auto register or manually register
#define AUTO_REGISTER_ROUTERS 1
#define TEST_BLOCK_ROUTES 0

/// Manually register routers.
@interface AppRouteRegistry : NSObject

/// You have to register routers before any module reqiures them. Those modules are running before registration is finished, such as routable initial view controller from storyboard, and any routers used in this initial view controller.
+ (void)registerForModulesBeforeRegistrationFinished;

+ (void)manuallyRegisterEachRouter;

@end
