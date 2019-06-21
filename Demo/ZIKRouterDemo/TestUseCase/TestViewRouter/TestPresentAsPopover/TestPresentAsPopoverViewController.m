//
//  TestPresentAsPopoverViewController.m
//  ZIKRouterDemo
//
//  Created by zuik on 2017/7/5.
//  Copyright © 2017 zuik. All rights reserved.
//

#import "TestPresentAsPopoverViewController.h"
@import ZIKRouter;
#import "ZIKInfoViewProtocol.h"

@interface TestPresentAsPopoverViewController () <ZIKInfoViewDelegate, UIPopoverPresentationControllerDelegate>
@property (nonatomic, strong) ZIKDestinationViewRouter(id<ZIKInfoViewProtocol>) *infoViewRouter;
@end

@implementation TestPresentAsPopoverViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
}

- (IBAction)presentAsPopover:(id)sender {
    __weak typeof(self) weakSelf = self;
    self.infoViewRouter = [ZIKRouterToView(ZIKInfoViewProtocol)
                           performPath:ZIKViewRoutePath
                                        .presentAsPopoverFrom(self, ^(ZIKViewRoutePopoverConfiguration *popoverConfig) {
                                            popoverConfig.delegate = self;
                                            popoverConfig.sourceView = sender;
                                            popoverConfig.sourceRect = CGRectMake(0, 0, 50, 10);
                                        })
                           configuring:^(ZIKViewRouteConfiguration *config) {
                               config.prepareDestination = ^(UIViewController<ZIKInfoViewProtocol> *destination) {
                                   destination.name = @"Zuik";
                                   destination.age = 18;
                                   destination.delegate = weakSelf;
                               };
                               config.successHandler = ^(id  _Nonnull destination) {
                                   NSLog(@"present as popover complete");
                               };
                               config.errorHandler = ^(ZIKRouteAction routeAction, NSError * _Nonnull error) {
                                   NSLog(@"present as popover failed: %@",error);
                               };
                           }];
}
- (IBAction)presentAsPopoverAndDismiss:(id)sender {
    __weak typeof(self) weakSelf = self;
    self.infoViewRouter = [ZIKRouterToView(ZIKInfoViewProtocol)
                           performPath:ZIKViewRoutePath.presentAsPopoverFrom(self, ^(ZIKViewRoutePopoverConfiguration *popoverConfig) {
                                    popoverConfig.delegate = self;
                                    popoverConfig.sourceView = sender;
                                    popoverConfig.sourceRect = CGRectMake(0, 0, 50, 10);
                                })
                           configuring:^(ZIKViewRouteConfiguration *config) {
                               config.prepareDestination = ^(UIViewController<ZIKInfoViewProtocol> *destination) {
                                   destination.name = @"Zuik";
                                   destination.age = 18;
                                   destination.delegate = weakSelf;
                               };
                               config.successHandler = ^(id  _Nonnull destination) {
                                   NSLog(@"present as popover complete");
                                   [weakSelf removeInfoViewController];
                               };
                               config.errorHandler = ^(ZIKRouteAction routeAction, NSError * _Nonnull error) {
                                   NSLog(@"present as popover failed: %@",error);
                               };
                           }];
}

- (void)removeInfoViewController {
    if (![self.infoViewRouter canRemove]) {
        NSLog(@"Can't remove router now:%@",self.infoViewRouter);
        return;
    }
    [self.infoViewRouter removeRouteWithConfiguring:^(ZIKViewRemoveConfig * _Nonnull config) {
        config.prepareDestination = ^(id  _Nonnull destination) {
            NSLog(@"Prepare destination before removing.");
        };
        config.successHandler = ^{
            NSLog(@"dismiss success");
        };
        config.errorHandler = ^(ZIKRouteAction  _Nonnull routeAction, NSError * _Nonnull error) {
            NSLog(@"dismiss failed,error:%@",error);
        };
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
