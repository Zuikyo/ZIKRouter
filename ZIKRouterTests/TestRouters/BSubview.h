//
//  BSubview.h
//  ZIKViewRouterTests
//
//  Created by zuik on 2018/4/18.
//  Copyright © 2018 zuik. All rights reserved.
//

#import "ZIKPlatformCapabilities.h"
#if ZIK_HAS_UIKIT
#import <UIKit/UIKit.h>
#else
#import <AppKit/AppKit.h>
#endif
#import "BSubviewInput.h"

@interface BSubview : UIView <BSubviewInput>

@property (nonatomic, copy, nullable) NSString *title;
@property (nonatomic, strong) id router;
@end
