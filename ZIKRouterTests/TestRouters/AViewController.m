//
//  AViewController.m
//  ZIKRouterTests
//
//  Created by zuik on 2018/4/11.
//  Copyright © 2018 zuik. All rights reserved.
//

#import "AViewController.h"

@interface AViewController ()

@end

@implementation AViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    NSLog(@"%@: %@", self, NSStringFromSelector(_cmd));
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSLog(@"%@: %@", self, NSStringFromSelector(_cmd));
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    NSLog(@"%@: %@", self, NSStringFromSelector(_cmd));
}

- (void)willMoveToParentViewController:(UIViewController *)parent {
    [super willMoveToParentViewController:parent];
    NSLog(@"%@: %@: %@", self, NSStringFromSelector(_cmd), parent);
}

- (void)didMoveToParentViewController:(UIViewController *)parent {
    [super didMoveToParentViewController:parent];
    NSLog(@"%@: %@: %@", self, NSStringFromSelector(_cmd), parent);
}

@end
