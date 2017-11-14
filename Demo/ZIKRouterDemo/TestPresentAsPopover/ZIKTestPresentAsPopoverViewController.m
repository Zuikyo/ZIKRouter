//
//  ZIKTestPresentAsPopoverViewController.m
//  ZIKRouterDemo
//
//  Created by zuik on 2017/7/5.
//  Copyright © 2017 zuik. All rights reserved.
//

#import "ZIKTestPresentAsPopoverViewController.h"
@import ZIKRouter;
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
    self.infoViewRouter = [ZIKViewRouter.toView(ZIKInfoViewProtocol_routable)
                           performFromSource:self
                           configuring:^(ZIKViewRouteConfiguration *config) {
                               config.routeType = ZIKViewRouteTypePresentAsPopover;
                               config.configurePopover(^(ZIKViewRoutePopoverConfiguration * _Nonnull popoverConfig) {
                                   popoverConfig.delegate = self;
                                   popoverConfig.sourceView = sender;
                                   popoverConfig.sourceRect = CGRectMake(0, 0, 50, 10);
                               });
                               config.prepareDestination = ^(UIViewController<ZIKInfoViewProtocol> *destination) {
                                   destination.name = @"Zuik";
                                   destination.age = 18;
                                   destination.delegate = weakSelf;
                               };
                               config.routeCompletion = ^(id  _Nonnull destination) {
                                   NSLog(@"present as popover complete");
                               };
                               config.errorHandler = ^(SEL  _Nonnull routeAction, NSError * _Nonnull error) {
                                   NSLog(@"present as popover failed: %@",error);
                               };
                           }];
}
- (IBAction)presentAsPopoverAndDismiss:(id)sender {
    __weak typeof(self) weakSelf = self;
    self.infoViewRouter = [ZIKViewRouter.toView(ZIKInfoViewProtocol_routable)
                           performFromSource:self
                           configuring:^(ZIKViewRouteConfiguration *config) {
                               config.routeType = ZIKViewRouteTypePresentAsPopover;
                               config.configurePopover(^(ZIKViewRoutePopoverConfiguration * _Nonnull popoverConfig) {
                                   popoverConfig.delegate = self;
                                   popoverConfig.sourceView = sender;
                                   popoverConfig.sourceRect = CGRectMake(0, 0, 50, 10);
                               });
                               config.prepareDestination = ^(UIViewController<ZIKInfoViewProtocol> *destination) {
                                   destination.name = @"Zuik";
                                   destination.age = 18;
                                   destination.delegate = weakSelf;
                               };
                               config.routeCompletion = ^(id  _Nonnull destination) {
                                   NSLog(@"present as popover complete");
                               };
                               config.errorHandler = ^(SEL  _Nonnull routeAction, NSError * _Nonnull error) {
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
    } errorHandler:^(SEL  _Nonnull routeAction, NSError * _Nonnull error) {
        NSLog(@"performer: dismiss failed,error:%@",error);
    }];
}

- (void)handleRemoveInfoViewController:(UIViewController *)infoViewController {
    [self removeInfoViewController];
}

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller {
    return UIModalPresentationNone; //You have to specify this particular value in order to make it work on iPhone.
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
