//
//  ZIKTestPushViewController.m
//  ZIKRouterDemo
//
//  Created by zuik on 2017/7/5.
//  Copyright © 2017 zuik. All rights reserved.
//

#import "ZIKTestPushViewController.h"
@import ZIKRouter;
#import "ZIKInfoViewProtocol.h"

@interface ZIKTestPushViewController () <ZIKInfoViewDelegate>
@property (nonatomic, strong) ZIKViewRouter *infoViewRouter;
@end

@implementation ZIKTestPushViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    __weak typeof(self) weakSelf = self;
    self.infoViewRouter = [[ZIKViewRouterForView(ZIKInfoViewProtocol_routable) alloc]
                           initWithConfigure:^(__kindof ZIKViewRouteConfiguration * _Nonnull config) {
                               config.source = self;
                               config.routeType = ZIKViewRouteTypePush;
                               
                               //prepareForRoute is hold in configuration, should be careful about retain cycle if this view controller will hold the router. Same with routeCompletion, providerSuccessHandler, providerErrorHandler, stateNotifier.
                               config.prepareForRoute = ^(UIViewController<ZIKInfoViewProtocol> *destination) {
                                   NSLog(@"provider: prepare destination");
                                   destination.name = @"Zuik";
                                   destination.age = 18;
                                   destination.delegate = weakSelf;
                               };
                               config.routeCompletion = ^(UIViewController<ZIKInfoViewProtocol> *destination) {
                                   NSLog(@"provider: push complete");
                               };
                               config.providerSuccessHandler = ^{
                                   NSLog(@"provider: push success");
                               };
                               config.providerErrorHandler = ^(SEL  _Nonnull routeAction, NSError * _Nonnull error) {
                                   NSLog(@"provider: push failed: %@",error);
                               };
                               config.stateNotifier = ^(ZIKRouterState oldState, ZIKRouterState newState) {
                                   NSLog(@"router change state from %@ to %@",[ZIKRouter descriptionOfState:oldState],[ZIKRouter descriptionOfState:newState]);
                               };
                               config.handleExternalRoute = YES;
                           }
                           removeConfigure:^(__kindof ZIKViewRemoveConfiguration * _Nonnull config) {
                               config.providerSuccessHandler = ^{
                                   NSLog(@"provider: pop success");
                               };
                               config.providerErrorHandler = ^(SEL  _Nonnull routeAction, NSError * _Nonnull error) {
                                   NSLog(@"provider: pop failed: %@",error);
                               };
                               config.handleExternalRoute = YES;
                               }];
}
- (IBAction)push:(id)sender {
    if (![self.infoViewRouter canPerform]) {
        NSLog(@"Can't perform route now:%@",self.infoViewRouter);
        return;
    }
    [self.infoViewRouter performRouteWithSuccessHandler:^{
        NSLog(@"performer: push success");
    } performerErrorHandler:^(SEL  _Nonnull routeAction, NSError * _Nonnull error) {
        NSLog(@"performer: push failed: %@",error);
    }];
}
- (IBAction)pushAndPop:(id)sender {
    if (![self.infoViewRouter canPerform]) {
        NSLog(@"Can't perform route now:%@",self.infoViewRouter);
        return;
    }
    [self.infoViewRouter performRouteWithSuccessHandler:^{
        NSLog(@"performer: push success");
    } performerErrorHandler:^(SEL  _Nonnull routeAction, NSError * _Nonnull error) {
        NSLog(@"performer: push failed: %@",error);
    }];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self removeInfoViewController];
    });
}

- (void)removeInfoViewController {
    if (![self.infoViewRouter canRemove]) {
        NSLog(@"Can't remove router now:%@",self.infoViewRouter);
        return;
    }
    [self.infoViewRouter removeRouteWithSuccessHandler:^{
        NSLog(@"performer: pop success");
    } performerErrorHandler:^(SEL  _Nonnull routeAction, NSError * _Nonnull error) {
        NSLog(@"performer: pop failed,error:%@",error);
    }];
}

- (void)routeFromExternalForInfoViewController:(UIViewController *)infoViewController {
    [infoViewController.navigationController popViewControllerAnimated:YES];
}

- (void)handleRemoveInfoViewController:(UIViewController *)infoViewController {
//    [self removeInfoViewController];
    [self routeFromExternalForInfoViewController:infoViewController];
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
