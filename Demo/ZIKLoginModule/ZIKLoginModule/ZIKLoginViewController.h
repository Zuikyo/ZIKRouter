//
//  ZIKLoginViewController.h
//  ZIKLoginModule
//
//  Created by zuik on 2018/5/25.
//  Copyright © 2018 duoyi. All rights reserved.
//

#import <ZIKRouter/ZIKPlatformCapabilities.h>
#import <ZIKRouter/ZIKClassCapabilities.h>
#if ZIK_HAS_UIKIT
#import <UIKit/UIKit.h>
#else
#import <AppKit/AppKit.h>
#endif
#import "ZIKLoginViewInput.h"

@interface ZIKLoginViewController : XXViewController<ZIKLoginViewInput>

@end
