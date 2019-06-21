//
//  TestPresentModallyViewController.m
//  ZIKRouterDemo
//
//  Created by zuik on 2017/7/5.
//  Copyright © 2017 zuik. All rights reserved.
//

#import "TestPresentModallyViewController.h"
@import ZIKRouter;
#import "ZIKInfoViewProtocol.h"

@interface TestPresentModallyViewController () <ZIKInfoViewDelegate>
@property (nonatomic, strong) ZIKViewRouter *infoViewRouter;
@end

@implementation TestPresentModallyViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (IBAction)presentModally:(id)sender {
    [self performRouteWithSuccessHandler:nil];
}

- (IBAction)presentModallyAndDismiss:(id)sender {
    if (self.infoViewRouter == nil) {
        [self performRouteWithSuccessHandler:^{
            [self removeInfoViewController];
        }];
        return;
    }
    if (![self.infoViewRouter canPerform]) {
        NSLog(@"Can't perform route now:%@",self.infoViewRouter);
        return;
    }
    [self.infoViewRouter performRouteWithSuccessHandler:^(id<ZIKInfoViewProtocol> destination) {
        [self removeInfoViewController];
    } errorHandler:^(ZIKRouteAction  _Nonnull routeAction, NSError * _Nonnull error) {
        NSLog(@"performer: push failed: %@",error);
    }];
}

- (void)performRouteWithSuccessHandler:(void(^)(void))successHandler {
    __weak typeof(self) weakSelf = self;
    self.infoViewRouter = [ZIKRouterToView(ZIKInfoViewProtocol)
                           performPath:ZIKViewRoutePath.presentModallyFrom(self)
                           configuring:^(ZIKViewRouteConfiguration * _Nonnull config) {
                               config.containerWrapper = ^UIViewController<ZIKViewRouteContainer> * _Nonnull(UIViewController * _Nonnull destination) {
                                   UINavigationController *container = [[UINavigationController alloc] initWithRootViewController:destination];
                                   return container;
                               };
                               
                               config.prepareDestination = ^(UIViewController<ZIKInfoViewProtocol> *destination) {
                                   destination.name = @"Zuik";
                                   destination.age = 18;
                                   destination.delegate = weakSelf;
                               };
                               config.performerSuccessHandler = ^(id  _Nonnull destination) {
                                   if (successHandler) {
                                       successHandler();
                                   }
                               };
                               config.successHandler = ^(id  _Nonnull destination) {
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
