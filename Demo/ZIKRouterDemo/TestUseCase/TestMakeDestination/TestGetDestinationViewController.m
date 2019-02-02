//
//  TestGetDestinationViewController.m
//  ZIKRouterDemo
//
//  Created by zuik on 2017/7/5.
//  Copyright © 2017 zuik. All rights reserved.
//

#import "TestGetDestinationViewController.h"
@import ZIKRouter;
#import "ZIKInfoViewProtocol.h"

@interface TestGetDestinationViewController () <ZIKInfoViewDelegate>
@property (nonatomic, strong) ZIKViewRouter *router;
@end

@implementation TestGetDestinationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (IBAction)getDestinationAndPresent:(id)sender {
    __weak typeof(self) weakSelf = self;
    self.router = [ZIKRouterToView(ZIKInfoViewProtocol)
                   performPath:ZIKViewRoutePath.makeDestination
                   configuring:^(ZIKViewRouteConfiguration * _Nonnull config) {
                       config.prepareDestination = ^(id<ZIKInfoViewProtocol>  _Nonnull destination) {
                           destination.delegate = weakSelf;
                           destination.name = @"Zuik";
                           destination.age = 18;
                       };
                       config.successHandler = ^(UIViewController * _Nonnull destination) {
                           NSLog(@"get destination by router success");
                           if ([destination isKindOfClass:[UIViewController class]]) {
                               [weakSelf presentViewController:destination animated:YES completion:^{
                                   NSLog(@"present manually complete");
                               }];
                           }
                       };
                       config.errorHandler = ^(ZIKRouteAction routeAction, NSError * _Nonnull error) {
                           NSLog(@"get destination by router failed: %@",error);
                       };
                       //Set handleExternalRoute to YES will let router call successHandler when destination is dispalyed, be cautious.
                       //         config.handleExternalRoute = YES;
                   }];
}

- (void)handleRemoveInfoViewController:(UIViewController *)infoViewController {
    [self.router removeRouteWithSuccessHandler:^{
        NSLog(@"remove success");
    } errorHandler:^(ZIKRouteAction routeAction, NSError * _Nonnull error) {
        NSLog(@"remove failed, error:%@",error);
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
