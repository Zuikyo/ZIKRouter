//
//  ZIKInfoViewController.h
//  ZIKRouterDemo
//
//  Created by zuik on 2017/7/5.
//  Copyright © 2017 zuik. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ZIKInfoViewProtocol.h"

@interface ZIKInfoViewController : UIViewController <ZIKInfoViewProtocol>
@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) NSInteger age;
@property (nonatomic, weak) id<ZIKInfoViewDelegate> delegate;
@end
