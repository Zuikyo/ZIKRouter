//
//  AViewController.h
//  ZIKRouterTests
//
//  Created by zuik on 2018/4/11.
//  Copyright © 2018 zuik. All rights reserved.
//

#import "ZIKPlatformCapabilities.h"
#if ZIK_HAS_UIKIT
#import <UIKit/UIKit.h>
#else
#import <AppKit/AppKit.h>
#endif
#import "AViewInput.h"

@interface AViewController : UIViewController <AViewInput>
@property (nonatomic, strong) id router;
@end
