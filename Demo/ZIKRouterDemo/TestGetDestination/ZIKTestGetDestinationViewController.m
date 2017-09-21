//
//  ZIKTestGetDestinationViewController.m
//  ZIKRouterDemo
//
//  Created by zuik on 2017/7/5.
//  Copyright © 2017 zuik. All rights reserved.
//

#import "ZIKTestGetDestinationViewController.h"
@import ZIKRouter;
#import "ZIKInfoViewProtocol.h"

@interface ZIKTestGetDestinationViewController () <ZIKInfoViewDelegate>
@property (nonatomic, strong) ZIKViewRouter *router;
@end

@implementation ZIKTestGetDestinationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (IBAction)getDestinationAndPresent:(id)sender {
    __weak typeof(self) weakSelf = self;
    self.router = [ZIKViewRouterForView(ZIKInfoViewProtocol_routable)
     performWithConfigure:^(ZIKViewRouteConfiguration * _Nonnull config) {
         config.source = self;
         config.routeType = ZIKViewRouteTypeGetDestination;
         config.prepareForRoute = ^(id<ZIKInfoViewProtocol>  _Nonnull destination) {
             destination.delegate = weakSelf;
             destination.name = @"Zuik";
             destination.age = 18;
         };
         config.routeCompletion = ^(UIViewController * _Nonnull destination) {
             NSLog(@"get destination by router complete");
             if ([destination isKindOfClass:[UIViewController class]]) {
                 [weakSelf presentViewController:destination animated:YES completion:^{
                     NSLog(@"present manually complete");
                 }];
             }
         };
         config.providerSuccessHandler = ^{
             NSLog(@"get destination success");
         };
         config.providerErrorHandler = ^(SEL  _Nonnull routeAction, NSError * _Nonnull error) {
             NSLog(@"get destination by router failed: %@",error);
         };
         //Set handleExternalRoute to YES will let router call routeCompletion when destination is dispalyed, be cautious.
//         config.handleExternalRoute = YES;
     }];
}

- (void)handleRemoveInfoViewController:(UIViewController *)infoViewController {
    [infoViewController dismissViewControllerAnimated:YES completion:^{
        NSLog(@"dismiss manually complete");
//        [self presentViewController:infoViewController animated:YES completion:^{
//            
//        }];
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
