//
//  TestPerformSegueViewController.h
//  ZIKRouterDemo
//
//  Created by zuik on 2017/7/5.
//  Copyright © 2017 zuik. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ZIKViewRouteConfiguration;
@interface TestPerformSegueViewController : UIViewController

@property (nonatomic) void(^prepareDestinationFromExternalMonitor)(id destination, ZIKViewRouteConfiguration *config);
@property (nonatomic) void(^prepareForSegueMonitor)(UIStoryboardSegue *segue);



@end
