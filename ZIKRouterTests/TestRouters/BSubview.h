//
//  BSubview.h
//  ZIKViewRouterTests
//
//  Created by zuik on 2018/4/18.
//  Copyright © 2018 zuik. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BSubviewInput.h"

@interface BSubview : UIView <BSubviewInput>

@property (nonatomic, copy, nullable) NSString *title;

@end
