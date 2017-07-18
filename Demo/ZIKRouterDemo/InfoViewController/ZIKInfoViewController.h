//
//  ZIKInfoViewController.h
//  ZIKRouterDemo
//
//  Created by zuik on 2017/7/5.
//  Copyright © 2017年 zuik. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ZIKInfoViewProtocol.h"

@interface ZIKInfoViewController : UIViewController
@property (nonatomic, readonly, copy) NSString *name;
@property (nonatomic, readonly, assign) NSInteger age;
@property (nonatomic, weak) id<ZIKInfoViewDelegate> delegate;
@end
