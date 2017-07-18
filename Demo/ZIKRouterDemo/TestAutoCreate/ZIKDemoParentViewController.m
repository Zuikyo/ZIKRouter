//
//  ZIKDemoParentViewController.m
//  ZIKRouterDemo
//
//  Created by zuik on 2017/7/7.
//  Copyright © 2017年 zuik. All rights reserved.
//

#import "ZIKDemoParentViewController.h"
#import "ZIKViewRouter.h"
#import "ZIKInfoViewProtocol.h"
#import "ZIKSimpleLabel.h"

@interface ZIKDemoParentViewController () <ZIKInfoViewDelegate>

@end

@implementation ZIKDemoParentViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (UIViewController<ZIKInfoViewProtocol> *)childInfoViewController {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    return [sb instantiateViewControllerWithIdentifier:@"childInfo"];
}

///Route UIViewController by code manually won't auto create a corresponding router, but router classes registered with the view controller will get AOP callback
- (IBAction)addChildManually:(id)sender {
    CGRect frame = [sender frame];
    frame.origin.y += 40;
    UIViewController<ZIKInfoViewProtocol> *childInfoViewController = [self childInfoViewController];
    
    childInfoViewController.delegate = self;
    [self addChildViewController:childInfoViewController];
    [self.view addSubview:childInfoViewController.view];
    [childInfoViewController didMoveToParentViewController:self];
}

///Add subview by code will auto create a corresponding router. We assume it's superview's view controller as the performer
- (IBAction)addSubviewManually:(id)sender {
    ZIKSimpleLabel *destination = [[ZIKSimpleLabel alloc] init];
//    destination.text = @"Label added manually";
    destination.frame = CGRectMake(100, 100, 200, 50);
    [self.view addSubview:destination];
}

- (void)handleRemoveInfoViewController:(UIViewController *)infoViewController {
    [infoViewController willMoveToParentViewController:nil];
    [infoViewController.view removeFromSuperview];
    [infoViewController removeFromParentViewController];
}

- (void)prepareForDestinationRoutingFromExternal:(id)destination configuration:(__kindof ZIKViewRouteConfiguration *)configuration {
    if ([destination conformsToProtocol:@protocol(ZIKInfoViewProtocol)]) {
        id<ZIKInfoViewProtocol> infoView = destination;
        infoView.name = @"Zuik";
        infoView.age = 18;
        infoView.delegate = self;
        return;
    } else if ([destination conformsToProtocol:@protocol(ZIKSimpleLabelProtocol)]) {
        id<ZIKSimpleLabelProtocol> simpleLabel = destination;
        simpleLabel.text = @"Label added manually";
        return;
    }
    NSAssert(NO, @"Can't prepare for unknown destination.");
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
