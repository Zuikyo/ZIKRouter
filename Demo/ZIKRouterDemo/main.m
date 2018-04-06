//
//  main.m
//  ZIKRouterDemo
//
//  Created by zuik on 2017/7/5.
//  Copyright © 2017 zuik. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"
#import "AppContext.h"
#import "AppRouteRegistry.h"
@import ZIKRouter.Internal;

int main(int argc, char * argv[]) {
    @autoreleasepool {
        
#if !AUTO_REGISTER_ROUTERS
        ZIKRouteRegistry.autoRegister = NO;
        [AppRouteRegistry registerForModulesBeforeRegistrationFinished];
#endif
        
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}
