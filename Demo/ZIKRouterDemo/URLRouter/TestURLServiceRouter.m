//
//  TestURLServiceRouter.m
//  ZIKRouterDemo
//
//  Created by zuik on 2019/4/19.
//  Copyright © 2019 zuik. All rights reserved.
//

#import "TestURLServiceRouter.h"
#import "RequiredCompatibleAlertModuleInput.h"
@import ZIKRouter;
@import ZIKRouter.Internal;

@implementation AlertService

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message {
    [ZIKRouterToViewModule(RequiredCompatibleAlertModuleInput)
     performPath:ZIKViewRoutePath.defaultPathFrom([UIApplication sharedApplication].keyWindow.rootViewController)
     configuring:^(ZIKViewRouteConfiguration<RequiredCompatibleAlertModuleInput> * _Nonnull config) {
         config.title = title;
         config.message = message;
         [config addOtherButtonTitle:@"OK" handler:^{
             
         }];
    }];
}

@end

@implementation TestURLAlertServiceConfiguration

@end

DeclareRoutableService(AlertService, TestURLServiceRouter)

@implementation TestURLServiceRouter

+ (void)registerRoutableDestination {
    [self registerService:[AlertService class]];
    [self registerIdentifier:@"alert"];
}

+ (TestURLAlertServiceConfiguration *)defaultRouteConfiguration {
    return [TestURLAlertServiceConfiguration new];
}

- (void)processUserInfo:(NSDictionary *)userInfo fromURL:(NSURL *)url {
    NSString *title = userInfo[@"title"];
    NSString *message = userInfo[@"message"];
    self.configuration.title = title;
    self.configuration.message = message;
}

- (AlertService *)destinationWithConfiguration:(ZIKPerformRouteConfiguration *)configuration {
    return [AlertService new];
}

- (void)performAction:(NSString *)action userInfo:(nonnull NSDictionary *)userInfo fromURL:(nonnull NSURL *)url {
    if ([action isEqualToString:@"showAlert"]) {
        [self.destination showAlertWithTitle:self.configuration.title
                                     message:self.configuration.message];
    }
}

@end
