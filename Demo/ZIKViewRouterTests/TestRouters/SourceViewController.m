//
//  SourceViewController.m
//  ZIKRouterDemoTests
//
//  Created by zuik on 2018/4/11.
//  Copyright © 2018 zuik. All rights reserved.
//

#import "SourceViewController.h"
#import "BSubviewInput.h"

@interface SourceViewController ()

@end

@implementation SourceViewController

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

- (void)prepareDestinationFromExternal:(id)destination configuration:(__kindof ZIKViewRouteConfiguration *)configuration {
    if (self.prepareDestinationFromExternalMonitor) {
        self.self.prepareDestinationFromExternalMonitor(destination, configuration);
    }
    if ([destination conformsToProtocol:@protocol(BSubviewInput)]) {
        id<BSubviewInput> dest = destination;
        dest.title = PREPARE_DESTINATION_TITLE;
        return;
    }
    NSAssert(NO, @"Can't prepare for unknown destination.");
}

@end
