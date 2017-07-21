//
//  ZIKTestPresentAsPopoverViewController.m
//  ZIKRouterDemo
//
//  Created by zuik on 2017/7/5.
//  Copyright © 2017年 zuik. All rights reserved.
//

#import "ZIKTestPresentAsPopoverViewController.h"
#import <ZIKRouterKit/ZIKRouterKit.h>
#import "ZIKInfoViewProtocol.h"

@interface ZIKTestPresentAsPopoverViewController () <ZIKInfoViewDelegate, UIPopoverPresentationControllerDelegate>
@property (nonatomic, strong) ZIKViewRouter *infoViewRouter;
@end

@implementation ZIKTestPresentAsPopoverViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
}

- (IBAction)presentAsPopover:(id)sender {
    __weak typeof(self) weakSelf = self;
    self.infoViewRouter = [ZIKViewRouterForView(_ZIKInfoViewProtocol_)
                           performWithConfigure:^(ZIKViewRouteConfiguration *config) {
                               config.source = self;
                               config.routeType = ZIKViewRouteTypePresentAsPopover;
                               config.configurePopover(^(ZIKViewRoutePopoverConfiguration * _Nonnull popoverConfig) {
                                   popoverConfig.delegate = self;
                                   popoverConfig.sourceView = sender;
                                   popoverConfig.sourceRect = CGRectMake(0, 0, 50, 10);
                               });
                               config.prepareForRoute = ^(UIViewController<ZIKInfoViewProtocol> *destination) {
                                   destination.name = @"Zuik";
                                   destination.age = 18;
                                   destination.delegate = weakSelf;
                               };
                               config.routeCompletion = ^(id  _Nonnull destination) {
                                   NSLog(@"present as popover complete");
                               };
                               config.providerErrorHandler = ^(SEL  _Nonnull routeAction, NSError * _Nonnull error) {
                                   NSLog(@"present as popover failed: %@",error);
                               };
                           }];
}
- (IBAction)presentAsPopoverAndDismiss:(id)sender {
    __weak typeof(self) weakSelf = self;
    self.infoViewRouter = [ZIKViewRouterForView(_ZIKInfoViewProtocol_)
                           performWithConfigure:^(ZIKViewRouteConfiguration *config) {
                               config.source = self;
                               config.routeType = ZIKViewRouteTypePresentAsPopover;
                               config.configurePopover(^(ZIKViewRoutePopoverConfiguration * _Nonnull popoverConfig) {
                                   popoverConfig.delegate = self;
                                   popoverConfig.sourceView = sender;
                                   popoverConfig.sourceRect = CGRectMake(0, 0, 50, 10);
                               });
                               config.prepareForRoute = ^(UIViewController<ZIKInfoViewProtocol> *destination) {
                                   destination.name = @"Zuik";
                                   destination.age = 18;
                                   destination.delegate = weakSelf;
                               };
                               config.routeCompletion = ^(id  _Nonnull destination) {
                                   NSLog(@"present as popover complete");
                               };
                               config.providerErrorHandler = ^(SEL  _Nonnull routeAction, NSError * _Nonnull error) {
                                   NSLog(@"present as popover failed: %@",error);
                               };
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
        NSLog(@"performer: dismiss success");
    } performerErrorHandler:^(SEL  _Nonnull routeAction, NSError * _Nonnull error) {
        NSLog(@"performer: dismiss failed,error:%@",error);
    }];
}

- (void)handleRemoveInfoViewController:(UIViewController *)infoViewController {
    [self removeInfoViewController];
}

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller {
    return UIModalPresentationNone; //You have to specify this particular value in order to make it work on iPhone.
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
