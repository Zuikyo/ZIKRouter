//
//  UnroutableViewController.m
//  ZIKRouterDemo
//
//  Created by zuik on 2017/10/10.
//  Copyright © 2017 zuik. All rights reserved.
//

#import "UnroutableViewController.h"
@import ZIKRouter;
#import "ZIKInfoViewProtocol.h"
#import "ZIKSimpleLabelProtocol.h"

@interface UnroutableViewController () <ZIKViewRouteSource, ZIKInfoViewDelegate>

@end

@implementation UnroutableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)handleRemoveInfoViewController:(UIViewController *)infoViewController {
    [infoViewController.navigationController popViewControllerAnimated:YES];
}

- (void)prepareDestinationFromExternal:(id)destination configuration:(__kindof ZIKViewRouteConfiguration *)configuration {
    if ([destination conformsToProtocol:@protocol(ZIKInfoViewProtocol)]) {
        id<ZIKInfoViewProtocol> infoView = destination;
        infoView.delegate = self;
        infoView.name = @"Zuik";
        infoView.age = 18;
    } else if ([destination conformsToProtocol:@protocol(ZIKSimpleLabelProtocol)]) {
        id<ZIKSimpleLabelProtocol> simpleLabel = destination;
        simpleLabel.text = @"this is unroutable view, but can be routed by segue";
    }
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
