//
//  ZIKParentViewProtocol.h
//  ZIKRouterDemo
//
//  Created by zuik on 2017/10/14.
//  Copyright © 2017 zuik. All rights reserved.
//

#import <UIKit/UIKit.h>
@import ZIKRouter;

@protocol ZIKParentViewProtocol <ZIKViewRoutable>
@property (nonatomic, strong) UIViewController *child;
@end
