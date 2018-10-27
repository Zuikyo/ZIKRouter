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

#if ZIK_HAS_UIKIT
typedef UIColor OSColor;
typedef UIView OSView;
typedef UITextField OSTextField;
typedef UIButton OSButton;
#define OSScreen UIScreen
#else
typedef NSColor OSColor;
typedef NSView OSView;
typedef NSTextField OSTextField;
typedef NSButton OSButton;
#define OSScreen NSScreen

@implementation NSView (Center)

- (void)setCenter:(CGPoint)center {
    CGRect newFrame = {
        center.x - self.frame.size.width / 2.0,
        center.y - self.frame.size.height / 2.0,
        self.frame.size
    };
    self.frame = NSRectFromCGRect(newFrame);
}

- (CGPoint)center {
    return CGPointMake(self.frame.origin.x + self.frame.size.width / 2.0,
                       self.frame.origin.y + self.frame.size.height / 2.0);
}
@end

#endif

@implementation OSScreen (Center)

- (CGPoint)center {
#if ZIK_HAS_UIKIT
    CGRect frame = self.bounds;
#else
    CGRect frame = self.frame;
#endif
    return CGPointMake(frame.origin.x + frame.size.width / 2.0,
                       frame.origin.y + frame.size.height / 2.0);
}
@end

@interface ZIKLoginViewController ()
@property (nonatomic, strong) OSTextField *passwordView;
@end

@implementation ZIKLoginViewController

- (void)loadView {
    // Avoid using nib in macOS
#if ZIK_HAS_UIKIT
    CGRect frame = [OSScreen mainScreen].bounds;
#else
    NSRect frame = NSMakeRect(0, 0, 400, 400);
#endif
    OSView *view = [[OSView alloc] initWithFrame:frame];
    self.view = view;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.layer.backgroundColor = [OSColor whiteColor].CGColor;
    
    OSTextField *password = [[OSTextField alloc] init];
    password.layer.borderColor = [OSColor blackColor].CGColor;
    password.frame = CGRectMake(0, 0, 150, 20);
#if ZIK_HAS_UIKIT
    password.center = CGPointMake(self.view.center.x, self.view.center.y - 100);
    password.placeholder = @"enter password";
#else
    password.center = CGPointMake(self.view.center.x, self.view.center.y + 100);
    password.placeholderString = @"enter password";
#endif
    [self.view addSubview:password];
    self.passwordView = password;
    
    OSButton *loginButton;
#if ZIK_HAS_UIKIT
    loginButton = [OSButton buttonWithType:UIButtonTypeSystem];
    [loginButton setTitle:@"Login" forState:UIControlStateNormal];
    [loginButton addTarget:self action:@selector(login:) forControlEvents:UIControlEventTouchUpInside];
#else
    loginButton = [OSButton buttonWithTitle:@"Login" target:self action:@selector(login:)];
#endif
    loginButton.frame = CGRectMake(0, 0, 100, 20);
    loginButton.center = self.view.center;
    [self.view addSubview:loginButton];
    
    OSButton *cancelButton;
#if ZIK_HAS_UIKIT
    cancelButton = [OSButton buttonWithType:UIButtonTypeSystem];
    [cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
    [cancelButton addTarget:self action:@selector(cancel:) forControlEvents:UIControlEventTouchUpInside];
#else
    cancelButton = [OSButton buttonWithTitle:@"Cancel" target:self action:@selector(cancel:)];
#endif
    cancelButton.frame = CGRectMake(0, 0, 100, 20);
#if ZIK_HAS_UIKIT
    cancelButton.center = CGPointMake(self.view.center.x, self.view.center.y + 100);
#else
    cancelButton.center = CGPointMake(self.view.center.x, self.view.center.y - 100);
#endif
    
    [self.view addSubview:cancelButton];
}

- (void)login:(OSButton *)sender {
#if ZIK_HAS_UIKIT
    NSString *password = self.passwordView.text;
#else
    NSString *password = self.passwordView.stringValue;
#endif
    if ([password isEqualToString:@"123"] == NO) {
        [ZIKRouterToViewModule(ZIKLoginModuleRequiredAlertInput) performPath:ZIKViewRoutePath.defaultPathFrom(self) configuring:^(ZIKViewRouteConfiguration<ZIKLoginModuleRequiredAlertInput> * _Nonnull config) {
            config.title = @"Invalid Password";
            config.message = @"The password is 123";
            [config addOtherButtonTitle:@"OK" handler:^{
                
            }];
        }];
    } else {
        [ZIKRouterToViewModule(ZIKLoginModuleRequiredAlertInput) performPath:ZIKViewRoutePath.defaultPathFrom(self) configuring:^(ZIKViewRouteConfiguration<ZIKLoginModuleRequiredAlertInput> * _Nonnull config) {
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

- (void)cancel:(OSButton *)sender {
    [self.router removeRouteWithSuccessHandler:^{
        NSLog(@"remove login view success");
    } errorHandler:^(ZIKRouteAction  _Nonnull routeAction, NSError * _Nonnull error) {
        NSLog(@"remove login view failed with action: %@, error:%@", routeAction, error);
    }];
}

@end
