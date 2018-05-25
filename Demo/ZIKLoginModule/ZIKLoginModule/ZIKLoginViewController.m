//
//  ZIKLoginViewController.m
//  ZIKLoginModule
//
//  Created by zuik on 2018/5/25.
//  Copyright © 2018 duoyi. All rights reserved.
//

#import "ZIKLoginViewController.h"
#import "ZIKLoginViewControllerInternal.h"
@import ZIKRouter;
#import "ZIKLoginModuleRequiredAlertInput.h"

@interface ZIKLoginViewController ()
@property (nonatomic, strong) UITextField *passwordView;
@end

@implementation ZIKLoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    UITextField *password = [[UITextField alloc] init];
    password.placeholder = @"enter password";
    password.layer.borderColor = [UIColor blackColor].CGColor;
    password.frame = CGRectMake(0, 0, 150, 20);
    password.center = CGPointMake([UIScreen mainScreen].bounds.size.width / 2, [UIScreen mainScreen].bounds.size.height / 2 - 100);
    [self.view addSubview:password];
    self.passwordView = password;
    
    UIButton *loginButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [loginButton setTitle:@"Login" forState:UIControlStateNormal];
    [loginButton addTarget:self action:@selector(login:) forControlEvents:UIControlEventTouchUpInside];
    loginButton.frame = CGRectMake(0, 0, 100, 20);
    loginButton.center = CGPointMake([UIScreen mainScreen].bounds.size.width / 2, [UIScreen mainScreen].bounds.size.height / 2);
    [self.view addSubview:loginButton];
    
    UIButton *cancelButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
    [cancelButton addTarget:self action:@selector(cancel:) forControlEvents:UIControlEventTouchUpInside];
    cancelButton.frame = CGRectMake(0, 0, 100, 20);
    cancelButton.center = CGPointMake([UIScreen mainScreen].bounds.size.width / 2, [UIScreen mainScreen].bounds.size.height / 2 + 100);
    [self.view addSubview:cancelButton];
}

- (void)login:(UIButton *)sender {
    NSString *password = self.passwordView.text;
    if ([password isEqualToString:@"123"] == NO) {
        [ZIKRouterToViewModule(ZIKLoginModuleRequiredAlertInput) performPath:ZIKViewRoutePath.customFrom(self) configuring:^(ZIKViewRouteConfiguration<ZIKLoginModuleRequiredAlertInput> * _Nonnull config) {
            config.title = @"Invalid Password";
            config.message = @"The password is 123";
            [config addOtherButtonTitle:@"OK" handler:^{
                
            }];
        }];
    } else {
        [ZIKRouterToViewModule(ZIKLoginModuleRequiredAlertInput) performPath:ZIKViewRoutePath.customFrom(self) configuring:^(ZIKViewRouteConfiguration<ZIKLoginModuleRequiredAlertInput> * _Nonnull config) {
            config.title = @"Login Success";
            [config addCancelButtonTitle:@"Cancel" handler:^{
                
            }];
            [config addOtherButtonTitle:@"Quit" handler:^{
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.router removeRouteWithSuccessHandler:^{
                        NSLog(@"remove login view success");
                    } errorHandler:^(ZIKRouteAction  _Nonnull routeAction, NSError * _Nonnull error) {
                        NSLog(@"remove login view failed with action: %@, error:%@", routeAction, error);
                    }];
                });
            }];
        }];
    }
}

- (void)cancel:(UIButton *)sender {
    [self.router removeRouteWithSuccessHandler:^{
        NSLog(@"remove login view success");
    } errorHandler:^(ZIKRouteAction  _Nonnull routeAction, NSError * _Nonnull error) {
        NSLog(@"remove login view failed with action: %@, error:%@", routeAction, error);
    }];
}

@end
