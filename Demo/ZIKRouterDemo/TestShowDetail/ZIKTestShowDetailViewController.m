//
//  ZIKTestShowDetailViewController.m
//  ZIKRouterDemo
//
//  Created by zuik on 2017/7/5.
//  Copyright © 2017 zuik. All rights reserved.
//

#import "ZIKTestShowDetailViewController.h"
@import ZIKRouter;
#import "ZIKInfoViewProtocol.h"

@interface ZIKTestShowDetailViewController () <ZIKInfoViewDelegate>
@property (nonatomic, strong) ZIKViewRouter *infoViewRouter;
@end

@implementation ZIKTestShowDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (IBAction)showDetail:(id)sender {
    __weak typeof(self) weakSelf = self;
    self.infoViewRouter = [ZIKViewRouter.toView(ZIKInfoViewProtocol_routable)
                           performWithConfiguring:^(ZIKViewRouteConfiguration * _Nonnull config) {
                               config.source = self;
                               config.routeType = ZIKViewRouteTypeShowDetail;
                               config.containerWrapper = ^UIViewController<ZIKViewRouteContainer> * _Nonnull(UIViewController * _Nonnull destination) {
//                                     UINavigationController *container = [[UINavigationController alloc] initWithRootViewController:destination];
//                                     return container;
                                     UITabBarController *container = [[UITabBarController alloc] init];
                                     [container setViewControllers:@[destination]];
                                     return container;
//                                   UISplitViewController *container = [[UISplitViewController alloc] init];
//                                   [container setViewControllers:@[destination]];
//                                   return container;
                               };
                               config.sender = sender;
                               config.prepareDestination = ^(id<ZIKInfoViewProtocol>  _Nonnull destination) {
                                   destination.delegate = weakSelf;
                                   destination.name = @"Zuik";
                                   destination.age = 18;
                               };
                               config.routeCompletion = ^(id  _Nonnull destination) {
                                   NSLog(@"show detail complete");
                               };
                               config.errorHandler = ^(SEL  _Nonnull routeAction, NSError * _Nonnull error) {
                                   NSLog(@"show detail failed: %@",error);
                               };
                           }];
}

- (void)removeInfoViewController {
    if (![self.infoViewRouter canRemove]) {
        NSLog(@"Can't remove router now:%@",self.infoViewRouter);
        return;
    }
    [self.infoViewRouter removeRouteWithSuccessHandler:^{
        NSLog(@"remove success");
    } errorHandler:^(SEL  _Nonnull routeAction, NSError * _Nonnull error) {
        NSLog(@"remove failed,error:%@",error);
    }];
}

- (void)handleRemoveInfoViewController:(UIViewController *)infoViewController {
    [self removeInfoViewController];
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
