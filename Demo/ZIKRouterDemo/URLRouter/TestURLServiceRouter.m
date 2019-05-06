//
//  TestURLServiceRouter.m
//  ZIKRouterDemo
//
//  Created by zuik on 2019/4/19.
//  Copyright © 2019 zuik. All rights reserved.
//

#import "TestURLServiceRouter.h"
#import "RequiredCompatibleAlertModuleInput.h"
@import ZIKRouter.Internal;
#import "AppRouteRegistry.h"

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
#if !TEST_BLOCK_ROUTES
    [self registerURLPattern:@"router://service/alert"];
#else
    [ZIKServiceRoute<AlertService *, TestURLAlertServiceConfiguration *> makeRouteWithDestination:[AlertService class] makeDestination:^AlertService * _Nullable(TestURLAlertServiceConfiguration * _Nonnull config, __kindof ZIKRouter<AlertService *,TestURLAlertServiceConfiguration *,ZIKRemoveRouteConfiguration *> * _Nonnull router) {
        return [AlertService new];
    }]
    .makeDefaultConfiguration(^TestURLAlertServiceConfiguration * _Nonnull{
        return [TestURLAlertServiceConfiguration new];
    })
    .registerURLPattern(@"router://service/alert")
    .processUserInfoFromURL(^(NSDictionary * _Nonnull userInfo, NSURL * _Nonnull url, TestURLAlertServiceConfiguration * _Nonnull config, ZIKServiceRouter * _Nonnull router) {
        NSString *title = userInfo[@"title"];
        NSString *message = userInfo[@"message"];
        config.title = title;
        config.message = message;
    })
    .performActionFromURL(^(NSString * _Nonnull action, NSDictionary * _Nonnull userInfo, NSURL * _Nonnull url, TestURLAlertServiceConfiguration * _Nonnull config, ZIKServiceRouter * _Nonnull router) {
        if ([action isEqualToString:@"showAlert"]) {
            [router.destination showAlertWithTitle:config.title
                                         message:config.message];
        }
    })
    .beforePerformWithConfigurationFromURL(^(TestURLAlertServiceConfiguration * _Nonnull config, ZIKServiceRouter * _Nonnull router) {
        
    })
    .afterSuccessActionFromURL(^(ZIKRouteAction  _Nonnull routeAction, TestURLAlertServiceConfiguration * _Nonnull config, ZIKServiceRouter * _Nonnull router) {
        
    });
    
#endif
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
