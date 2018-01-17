//
//  ZIKTestPresentModallyViewController.m
//  ZIKRouterDemo
//
//  Created by zuik on 2017/7/5.
//  Copyright © 2017 zuik. All rights reserved.
//

#import "ZIKTestPresentModallyViewController.h"
@import ZIKRouter;
#import "ZIKInfoViewProtocol.h"

@interface ZIKTestPresentModallyViewController () <ZIKInfoViewDelegate>
@property (nonatomic, strong) ZIKViewRouter *infoViewRouter;
@end

@implementation ZIKTestPresentModallyViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    __weak typeof(self) weakSelf = self;
    //provide the router
    self.infoViewRouter = [[ZIKViewRouter.toView(ZIKInfoViewProtocol_routable) alloc]
                           initWithConfiguring:^(ZIKViewRouteConfiguration * _Nonnull config) {
                               config.source = self;
                               config.routeType = ZIKViewRouteTypePresentModally;
                               config.containerWrapper = ^UIViewController<ZIKViewRouteContainer> * _Nonnull(UIViewController * _Nonnull destination) {
                                   UINavigationController *container = [[UINavigationController alloc] initWithRootViewController:destination];
                                   return container;
                               };
                               
                               config.prepareDestination = ^(UIViewController<ZIKInfoViewProtocol> *destination) {
                                   destination.name = @"Zuik";
                                   destination.age = 18;
                                   destination.delegate = weakSelf;
                               };
                               config.successHandler = ^{
                                   NSLog(@"provider: present modally success");
                               };
                               config.errorHandler = ^(ZIKRouteAction routeAction, NSError * _Nonnull error) {
                                   NSLog(@"provider: present modally failed: %@",error);
                               };
                           }
                           removing:^(ZIKViewRemoveConfiguration * _Nonnull config) {
                               config.successHandler = ^{
                                   NSLog(@"provider: dismiss success");
                               };
                               config.errorHandler = ^(ZIKRouteAction routeAction, NSError * _Nonnull error) {
                                   NSLog(@"provider: dismiss failed: %@",error);
                               };
                           }];
}

- (IBAction)presentModally:(id)sender {
    if (![self.infoViewRouter canPerform]) {
        NSLog(@"Can't perform route now:%@",self.infoViewRouter);
        return;
    }
    //perform the router
    [self.infoViewRouter performRouteWithSuccessHandler:^{
        NSLog(@"performer: present modally success");
    } errorHandler:^(ZIKRouteAction routeAction, NSError * _Nonnull error) {
        NSLog(@"performer: present modally failed: %@",error);
    }];
}

- (IBAction)presentModallyAndDismiss:(id)sender {
    if (![self.infoViewRouter canPerform]) {
        NSLog(@"Can't perform route now:%@",self.infoViewRouter);
        return;
    }
    [self.infoViewRouter performRouteWithSuccessHandler:^{
        [self removeInfoViewController];
    } errorHandler:^(ZIKRouteAction  _Nonnull routeAction, NSError * _Nonnull error) {
        NSLog(@"performer: push failed: %@",error);
    }];
}

- (void)removeInfoViewController {
    if (![self.infoViewRouter canRemove]) {
        NSLog(@"Can't remove router now:%@",self.infoViewRouter);
        return;
    }
    [self.infoViewRouter removeRouteWithSuccessHandler:^{
        NSLog(@"performer: dismiss success");
    } errorHandler:^(ZIKRouteAction routeAction, NSError * _Nonnull error) {
        NSLog(@"performer: dismiss failed,error:%@",error);
    }];
}

- (void)handleRemoveInfoViewController:(UIViewController *)infoViewController {
    [self removeInfoViewController];
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
