//
//  ZIKTestCustomViewController.m
//  ZIKRouterDemo
//
//  Created by zuik on 2017/7/5.
//  Copyright © 2017年 zuik. All rights reserved.
//

#import "ZIKTestCustomViewController.h"
#import <ZIKRouterKit/ZIKRouterKit.h>
#import "ZIKCompatibleAlertConfigProtocol.h"

@interface ZIKTestCustomViewController ()
@property (nonatomic, strong) ZIKViewRouter *alertViewRouter;
@end

@implementation ZIKTestCustomViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}
- (IBAction)performCustomRoute:(id)sender {
    self.alertViewRouter = [ZIKViewRouterForConfig(_ZIKCompatibleAlertConfigProtocol_)
                            performWithConfigure:^(ZIKViewRouteConfiguration<ZIKCompatibleAlertConfigProtocol> * _Nonnull config) {
                                config.source = self;
                                config.routeType = ZIKViewRouteTypeCustom;
                                config.title = @"Compatible Alert";
                                config.message = @"Test custom route for alert with UIAlertView and UIAlertController";
                                [config addCancelButtonTitle:@"Cancel" handler:^{
                                    NSLog(@"Tap cancel alert");
                                }];
                                [config addOtherButtonTitle:@"Hello" handler:^{
                                    NSLog(@"Tap hello button");
                                }];
                                
                                config.routeCompletion = ^(id _Nonnull destination) {
                                    NSLog(@"show custom alert complete");
                                };
                                config.providerErrorHandler = ^(SEL  _Nonnull routeAction, NSError * _Nonnull error) {
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
    } performerErrorHandler:^(SEL  _Nonnull routeAction, NSError * _Nonnull error) {
        NSLog(@"remove failed,error:%@",error);
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
