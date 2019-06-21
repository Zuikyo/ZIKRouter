//
//  TestPresentModallyViewRouter.m
//  ZIKRouterDemo
//
//  Created by zuik on 2017/7/5.
//  Copyright © 2017 zuik. All rights reserved.
//

#import "TestPresentModallyViewRouter.h"
#import "TestPresentModallyViewController.h"
#import "AppRouteRegistry.h"

@interface TestPresentModallyViewController (TestPresentModallyViewRouter) <ZIKRoutableView>
@end
@implementation TestPresentModallyViewController (TestPresentModallyViewRouter)
@end

@implementation TestPresentModallyViewRouter

+ (void)registerRoutableDestination {
#if !TEST_BLOCK_ROUTES
    [self registerURLPattern:@"router://testPresentModally"];
#else
    [ZIKDestinationViewRoute(TestPresentModallyViewController *)
     makeRouteWithDestination:[TestPresentModallyViewController class]
     makeDestination:^TestPresentModallyViewController * _Nullable(ZIKViewRouteConfig * _Nonnull config, __kindof ZIKRouter<TestPresentModallyViewController *,ZIKViewRouteConfig *,ZIKViewRemoveConfiguration *> * _Nonnull router) {
        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        TestPresentModallyViewController *destination = [sb instantiateViewControllerWithIdentifier:@"testPresentModally"];
        destination.title = @"Test PresentModally";
        return destination;
    }]
    .registerURLPattern(@"router://testPresentModally")
    .processUserInfoFromURL(^(NSDictionary *userInfo, NSURL *url, ZIKViewRouteConfig *config, ZIKViewRouter *router) {
        
    })
    .performActionFromURL(^(NSString *action, NSDictionary *userInfo, NSURL *url, ZIKViewRouteConfig *config, ZIKViewRouter *router) {
        
    })
    .beforePerformWithConfigurationFromURL(^(ZIKViewRouteConfig *config, ZIKViewRouter *router) {
        
    })
    .afterSuccessActionFromURL(^(ZIKRouteAction routeAction, ZIKViewRouteConfig *config, ZIKViewRouter *router) {
        
    });
#endif
    [self registerView:[TestPresentModallyViewController class]];
}

- (id<ZIKRoutableView>)destinationWithConfiguration:(ZIKViewRouteConfiguration *)configuration {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    TestPresentModallyViewController *destination = [sb instantiateViewControllerWithIdentifier:@"testPresentModally"];
    destination.title = @"Test PresentModally";
    return destination;
}

@end
