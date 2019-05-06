//
//  TestPushViewRouter.m
//  ZIKRouterDemo
//
//  Created by zuik on 2017/7/5.
//  Copyright © 2017 zuik. All rights reserved.
//

#import "TestPushViewRouter.h"
#import "TestPushViewController.h"
#import "RequiredCompatibleAlertModuleInput.h"
@import ZIKRouter.Internal;

DeclareRoutableView(TestPushViewController, TestPushViewRouter)

@implementation TestPushViewRouter

+ (void)registerRoutableDestination {
    [self registerView:[TestPushViewController class]];
    [self registerIdentifier:@"testPush"];
    [self registerURLPattern:@"router://testPush"];
}

- (id<ZIKRoutableView>)destinationWithConfiguration:(ZIKViewRouteConfiguration *)configuration {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    TestPushViewController *destination = [sb instantiateViewControllerWithIdentifier:@"testPush"];
    destination.title = @"Test Push";
    return destination;
}

- (void)processUserInfo:(NSDictionary *)userInfo fromURL:(NSURL *)url {
    
}

- (void)performAction:(NSString *)action userInfo:(nonnull NSDictionary *)userInfo fromURL:(NSURL *)url {
    [ZIKRouterToViewModule(RequiredCompatibleAlertModuleInput) performPath:ZIKViewRoutePath.defaultPathFrom(self.destination) configuring:^(ZIKViewRouteConfiguration<RequiredCompatibleAlertModuleInput> * _Nonnull config) {
        config.title = @"URL route";
        config.message = @"This view is from URL Scheme";
        [config addOtherButtonTitle:@"OK" handler:^{
            
        }];
    }];
}

@end
