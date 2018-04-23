//
//  TestAddAsSubviewViewController.m
//  ZIKRouterDemo
//
//  Created by zuik on 2017/7/5.
//  Copyright © 2017 zuik. All rights reserved.
//

#import "TestAddAsSubviewViewController.h"
@import ZIKRouter;
#import "ZIKSimpleLabelProtocol.h"

@interface TestAddAsSubviewViewController ()
@property (nonatomic, strong) ZIKViewRouter *labelRouter;
@end

@implementation TestAddAsSubviewViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (IBAction)addAsSubview:(id)sender {
    self.labelRouter = [ZIKRouterToView(ZIKSimpleLabelProtocol)
                        performPath:ZIKViewRoutePath.addAsSubviewFrom(self.view)
                        configuring:^(ZIKViewRouteConfiguration * _Nonnull config) {
                            config.prepareDestination = ^(id<ZIKSimpleLabelProtocol>  _Nonnull destination) {
                                destination.text = @"this is a label from router";
                                destination.frame = CGRectMake(50, 50, 200, 50);
                            };
                            config.successHandler = ^(UIView * _Nonnull destination) {
                                NSLog(@"add as subview complete");
                            };
                            config.errorHandler = ^(ZIKRouteAction routeAction, NSError * _Nonnull error) {
                                NSLog(@"add as subview failed: %@",error);
                            };
                        }];
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
