//
//  SourceViewController.h
//  ZIKRouterDemoTests
//
//  Created by zuik on 2018/4/11.
//  Copyright © 2018 zuik. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ZIKViewRouteConfiguration;

#define PREPARE_DESTINATION_TITLE @"prepareDestinationFromExternal title"

/// Source view controller providing a test environment.
@interface SourceViewController : UIViewController

@property (nonatomic) void(^prepareDestinationFromExternalMonitor)(id destination, ZIKViewRouteConfiguration *config);

@end
