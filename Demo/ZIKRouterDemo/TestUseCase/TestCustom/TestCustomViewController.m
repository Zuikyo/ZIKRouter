//
//  TestCustomViewController.m
//  ZIKRouterDemo
//
//  Created by zuik on 2017/7/5.
//  Copyright © 2017 zuik. All rights reserved.
//

#import "TestCustomViewController.h"
@import ZIKRouter;
#import "RequiredCompatibleAlertModuleInput.h"
#import <ZIKAlertModule/ZIKViewRoutePath+CompatibleAlert.h>

@interface TestCustomViewController ()
@property (nonatomic, strong) ZIKViewRouter<id, ZIKViewRouteConfiguration<RequiredCompatibleAlertModuleInput> *> *alertViewRouter;
@end

@implementation TestCustomViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}
- (IBAction)performCustomRoute:(id)sender {
    [self showAlert];
}

- (void)showAlert {
    ///If the protocol passed to `ZIKViewRouterToModule` is changed, parameter type in `prepareModule` will also change. So it's much safer when you change the routable protocol.
    self.alertViewRouter = [ZIKRouterToViewModule(RequiredCompatibleAlertModuleInput)
     performPath:ZIKViewRoutePath.presentCompatibleAlertFrom(self)
     strictConfiguring:^(ZIKPerformRouteStrictConfiguration *config, ZIKViewRouteConfiguration<RequiredCompatibleAlertModuleInput> *module) {
         config.successHandler = ^(id _Nonnull destination) {
             NSLog(@"show custom alert complete");
         };
         config.errorHandler = ^(ZIKRouteAction routeAction, NSError * _Nonnull error) {
             NSLog(@"show custom alert failed: %@",error);
         };
         
         module.title = @"Compatible Alert";
         module.message = @"Test custom route for alert with UIAlertView and UIAlertController";
         [module addCancelButtonTitle:@"Cancel" handler:^{
             NSLog(@"Tap cancel alert");
         }];
         [module addOtherButtonTitle:@"Hello" handler:^{
             NSLog(@"Tap hello button");
         }];
     }];
}

- (void)showAlert2 {
    self.alertViewRouter = [ZIKRouterToViewModule(RequiredCompatibleAlertModuleInput)
                            performPath:ZIKViewRoutePath.customFrom(self)
                            configuring:^(ZIKViewRouteConfiguration<RequiredCompatibleAlertModuleInput> * _Nonnull config) {
                                config.title = @"Compatible Alert";
                                config.message = @"Test custom route for alert with UIAlertView and UIAlertController";
                                [config addCancelButtonTitle:@"Cancel" handler:^{
                                    NSLog(@"Tap cancel alert");
                                }];
                                [config addOtherButtonTitle:@"Hello" handler:^{
                                    NSLog(@"Tap hello button");
                                }];
                                
                                config.successHandler = ^(id _Nonnull destination) {
                                    NSLog(@"show custom alert complete");
                                };
                                config.errorHandler = ^(ZIKRouteAction routeAction, NSError * _Nonnull error) {
                                    NSLog(@"show custom alert failed: %@",error);
                                };
                            }];
}

- (void)removeAlertViewController {
    if (![self.alertViewRouter canRemove]) {
        NSLog(@"Can't remove router now:%@",self.alertViewRouter);
        return;
    }
    [self.alertViewRouter removeRouteWithSuccessHandler:^{
        NSLog(@"remove success");
    } errorHandler:^(ZIKRouteAction routeAction, NSError * _Nonnull error) {
        NSLog(@"remove failed,error:%@",error);
    }];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
