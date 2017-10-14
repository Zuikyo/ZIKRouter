//
//  ZIKTestCircularDependenciesViewController.h
//  ZIKRouterDemo
//
//  Created by zuik on 2017/10/14.
//  Copyright © 2017 zuik. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ZIKParentViewProtocol.h"

@interface ZIKTestCircularDependenciesViewController : UIViewController <ZIKParentViewProtocol>

@property (nonatomic, strong) UIViewController *child;

@end
