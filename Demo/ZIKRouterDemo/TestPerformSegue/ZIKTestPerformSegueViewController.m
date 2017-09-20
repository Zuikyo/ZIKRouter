//
//  ZIKTestPerformSegueViewController.m
//  ZIKRouterDemo
//
//  Created by zuik on 2017/7/5.
//  Copyright © 2017年 zuik. All rights reserved.
//

#import "ZIKTestPerformSegueViewController.h"
@import ZIKRouter;
#import "ZIKInfoViewProtocol.h"
#import "ZIKSimpleLabelProtocol.h"
#import "ZIKTestPerformSegueViewRouter.h"

@interface ZIKTestPerformSegueViewController () <ZIKInfoViewDelegate>
@property (nonatomic, strong) ZIKViewRouter *segueRouter;
@end

@implementation ZIKTestPerformSegueViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNote:) name:nil object:nil];
}

- (void)handleNote:(NSNotification *)note {
    
}

- (IBAction)performSegue:(id)sender {
    __weak typeof(self) weakSelf = self;
    self.segueRouter = [ZIKViewRouterForView(ZIKInfoViewProtocol_routable)
                           performWithConfigure:^(__kindof ZIKViewRouteConfiguration * _Nonnull config) {
                               config.source = self;
                               config.routeType = ZIKViewRouteTypePerformSegue;
                               config.configureSegue(^(ZIKViewRouteSegueConfiguration * _Nonnull segueConfig) {
                                   segueConfig.identifier = @"presentInfo";
                               });
                               config.prepareForRoute = ^(id<ZIKInfoViewProtocol>  _Nonnull destination) {
                                   destination.delegate = weakSelf;
                                   destination.name = @"Zuik";
                                   destination.age = 18;
                               };
                               config.routeCompletion = ^(id  _Nonnull destination) {
                                   NSLog(@"perform segue complete");
                               };
                               config.providerErrorHandler = ^(SEL  _Nonnull routeAction, NSError * _Nonnull error) {
                                   NSLog(@"perform segue failed: %@",error);
                               };
                           }];
}

- (IBAction)performCustomSegue:(id)sender {
    __weak typeof(self) weakSelf = self;
    self.segueRouter = [ZIKViewRouterForView(ZIKInfoViewProtocol_routable)
                           performWithConfigure:^(__kindof ZIKViewRouteConfiguration * _Nonnull config) {
                               config.source = self;
                               config.routeType = ZIKViewRouteTypePerformSegue;
                               config.configureSegue(^(ZIKViewRouteSegueConfiguration * _Nonnull segueConfig) {
                                   segueConfig.identifier = @"customSegue";
                               });
                               config.prepareForRoute = ^(id<ZIKInfoViewProtocol>  _Nonnull destination) {
                                   destination.delegate = weakSelf;
                                   destination.name = @"Zuik";
                                   destination.age = 18;
                               };
                               config.routeCompletion = ^(id  _Nonnull destination) {
                                   NSLog(@"perform segue complete");
                               };
                               config.providerErrorHandler = ^(SEL  _Nonnull routeAction, NSError * _Nonnull error) {
                                   NSLog(@"perform segue failed: %@",error);
                               };
                           }];
}

- (IBAction)performSegueForMultiRoutableDestinations:(id)sender {
    __weak typeof(self) weakSelf = self;
    //If destination doesn't comform to ZIKRoutableView, just use ZIKViewRouter to perform the segue. If destination contains child view controllers, and childs conform to ZIKRoutableView, prepareForRoute and routeCompletion will callback for multi times.
    self.segueRouter = [ZIKViewRouter
                        performWithConfigure:^(__kindof ZIKViewRouteConfiguration * _Nonnull config) {
                            config.source = self;
                            config.routeType = ZIKViewRouteTypePerformSegue;
                            config.configureSegue(^(ZIKViewRouteSegueConfiguration * _Nonnull segueConfig) {
                                segueConfig.identifier = @"showMultiRoutableDestinations";
                            });
                            config.prepareForRoute = ^(id _Nonnull destination) {
                                if ([destination conformsToProtocol:@protocol(ZIKInfoViewProtocol)]) {
                                    id<ZIKInfoViewProtocol> infoView = destination;
                                    infoView.delegate = weakSelf;
                                    infoView.name = @"Zuik";
                                    infoView.age = 18;
                                } else if ([destination conformsToProtocol:@protocol(ZIKSimpleLabelProtocol)]) {
                                    id<ZIKSimpleLabelProtocol> simpleLabel = destination;
                                    simpleLabel.text = @"multi routable destinations";
                                } else {
                                    NSLog(@"prepare for unroutable destination:%@",destination);
                                }
                            };
                            config.routeCompletion = ^(id  _Nonnull destination) {
                                NSLog(@"perform segue complete for destination:%@",destination);
                            };
                            config.providerErrorHandler = ^(SEL  _Nonnull routeAction, NSError * _Nonnull error) {
                                NSLog(@"perform segue failed: %@",error);
                            };
                        }];
}

- (void)removeInfoViewController {
    if (![self.segueRouter canRemove]) {
        NSLog(@"Can't remove router now:%@",self.segueRouter);
        return;
    }
    NSLog(@"the routed router is %@",self.segueRouter);
    [self.segueRouter removeRouteWithSuccessHandler:^{
        NSLog(@"dismiss success");
    } performerErrorHandler:^(SEL  _Nonnull routeAction, NSError * _Nonnull error) {
        NSLog(@"dismiss failed,error:%@",error);
    }];
}

- (void)perfromUnwindSegueToTestPerformSegueVCFromInfoVC:(UIViewController *)infoViewController {
    //unwind segue from ZIKInfoViewController to ZIKTestPerformSegueViewController is define in ZIKInfoViewController, and should be used inside ZIKInfoViewController, this code is just for test
    [ZIKTestPerformSegueViewRouter
     performWithConfigure:^(__kindof ZIKViewRouteConfiguration * _Nonnull config) {
        config.source = infoViewController;
        config.routeType = ZIKViewRouteTypePerformSegue;
        config.configureSegue(^(ZIKViewRouteSegueConfiguration * _Nonnull segueConfig) {
            segueConfig.identifier = @"unwindToTestPerformSegue";
        });
        config.prepareForRoute = ^(UIViewController * _Nonnull destination) {
            NSLog(@"change destination's background color when unwind to destination:(%@)",destination);
            destination.view.backgroundColor = [UIColor yellowColor];
        };
        config.routeCompletion = ^(id  _Nonnull destination) {
            NSLog(@"perform unwind segue to ZIKTestPerformSegueViewController complete");
        };
        config.providerErrorHandler = ^(SEL  _Nonnull routeAction, NSError * _Nonnull error) {
            NSLog(@"perform unwind segue to ZIKTestPerformSegueViewController failed: %@",error);
        };
    }];
}

- (void)handleRemoveInfoViewController:(UIViewController *)infoViewController {
    [self removeInfoViewController];
//    [self perfromUnwindSegueToTestPerformSegueVCFromInfoVC:infoViewController];
}

- (void)prepareForDestinationRoutingFromExternal:(id)destination configuration:(__kindof ZIKViewRouteConfiguration *)configuration {
    if ([destination conformsToProtocol:@protocol(ZIKInfoViewProtocol)]) {
        id<ZIKInfoViewProtocol> infoView = destination;
        infoView.name = @"Zuik";
        infoView.age = 18;
        infoView.delegate = self;
        return;
    }
    NSAssert(NO, @"Can't prepare for unknown destination.");
}

#pragma mark - Navigation

//If segue is performed by code, this method is not called
- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(nullable id)sender {
    return YES;
}

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

- (BOOL)canPerformUnwindSegueAction:(SEL)action fromViewController:(UIViewController *)fromViewController withSender:(id)sender {
    //If return NO, route in -perfromUnwindSegueToTestPerformSegueVCFromInfoVC will fail and callback with error code ZIKViewRouteErrorSegueNotPerformed
    return YES;
}

- (IBAction)unwindToTestPerformSegueViewController:(UIStoryboardSegue *)sender {
    NSLog(@"%@: did unwind to TestPerformSegueViewController",self);
}

@end
