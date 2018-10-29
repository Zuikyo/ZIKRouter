//
//  AppDelegate.m
//  ZIKRouterDemo
//
//  Created by zuik on 2017/7/5.
//  Copyright © 2017 zuik. All rights reserved.
//

#import "AppDelegate.h"
#import "DetailViewController.h"
#import "AppRouteRegistry.h"
@import ZIKRouter;

@interface AppDelegate () <UISplitViewControllerDelegate>

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
#if !AUTO_REGISTER_ROUTERS
    // Two ways to manually register:
    
    /*
     1. Register each router by calling +registerRoutableDestination
     
     Problems you may meet:
     You have to register routers before their modules are required.
     
     If there're modules running before registration is finished, there will be assert failure. You should register those required routers earlier.
     Such as routable initial view controller from storyboard, or any routers used in this initial view controller.
    */
    [AppRouteRegistry manuallyRegisterEachRouter];
    
    // 2. Search all routers and register
//    [ZIKRouteRegistry registerAll];

#endif
    ZIKViewRouter.globalErrorHandler = ^(__kindof ZIKViewRouter * _Nullable router,
                                         ZIKRouteAction  _Nonnull action,
                                         NSError * _Nonnull error) {
        NSLog(@"❌ZIKViewRouter Error: router's action (%@) catch error! code:%@, description: %@,\nrouter:(%@)", action, @(error.code), error.localizedDescription,router);
    };
    ZIKServiceRouter.globalErrorHandler = ^(__kindof ZIKServiceRouter * _Nullable router,
                                            ZIKRouteAction  _Nonnull action,
                                            NSError * _Nonnull error) {
        NSLog(@"❌ZIKServiceRouter Error: router's action (%@) catch error! code:%@, description: %@,\nrouter:(%@)", action, @(error.code), error.localizedDescription,router);
    };
    
    // UISplitViewController's detail view controller will be hold by UIKit after it's removed, it's not memory leak
    ZIKViewRouter.detectMemoryLeakDelay = 1;
    
    UISplitViewController *splitViewController = (UISplitViewController *)self.window.rootViewController;
    UINavigationController *navigationController = [splitViewController.viewControllers lastObject];
    navigationController.topViewController.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem;
    splitViewController.delegate = self;
    
    return YES;
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
    
    //You can use other url router framework, here is only for demonstrating.
    NSString *identifier = url.host;
    if (identifier == nil) {
        return NO;
    }
    ZIKViewRouterType *routerType = ZIKViewRouter.toIdentifier(identifier);
    if (routerType == nil) {
        return NO;
    }
    UISplitViewController *splitViewController = (UISplitViewController *)self.window.rootViewController;
    UINavigationController *navigationController = [splitViewController.viewControllers lastObject];
    
    NSDictionary *params = @{ @"url": url,
                              @"options" : options
                              };
    [routerType performPath:ZIKViewRoutePath.showFrom(navigationController)
                configuring:^(ZIKViewRouteConfiguration * _Nonnull config) {
                    [config addUserInfo:params];
                }];
    return YES;
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Notify custom event to router
    [ZIKAnyViewRouter enumerateAllViewRouters:^(Class  _Nonnull __unsafe_unretained routerClass) {
        if ([routerClass respondsToSelector:@selector(applicationDidEnterBackground:)]) {
            [routerClass applicationDidEnterBackground:application];
        }
    }];
    [ZIKAnyServiceRouter enumerateAllServiceRouters:^(Class  _Nonnull __unsafe_unretained routerClass) {
        if ([routerClass respondsToSelector:@selector(applicationDidEnterBackground:)]) {
            [routerClass applicationDidEnterBackground:application];
        }
    }];
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Notify custom event to router
    [ZIKAnyViewRouter enumerateAllViewRouters:^(Class  _Nonnull __unsafe_unretained routerClass) {
        if ([routerClass respondsToSelector:@selector(applicationWillEnterForeground:)]) {
            [routerClass applicationWillEnterForeground:application];
        }
    }];
    [ZIKAnyServiceRouter enumerateAllServiceRouters:^(Class  _Nonnull __unsafe_unretained routerClass) {
        if ([routerClass respondsToSelector:@selector(applicationWillEnterForeground:)]) {
            [routerClass applicationWillEnterForeground:application];
        }
    }];
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


#pragma mark - Split view

- (BOOL)splitViewController:(UISplitViewController *)splitViewController collapseSecondaryViewController:(UIViewController *)secondaryViewController ontoPrimaryViewController:(UIViewController *)primaryViewController {
    if ([secondaryViewController isKindOfClass:[UINavigationController class]] && [[(UINavigationController *)secondaryViewController topViewController] isKindOfClass:[DetailViewController class]] && ([(DetailViewController *)[(UINavigationController *)secondaryViewController topViewController] detailItem] == nil)) {
        // Return YES to indicate that we have handled the collapse by doing nothing; the secondary controller will be discarded.
        return YES;
    } else {
        return NO;
    }
}

@end
