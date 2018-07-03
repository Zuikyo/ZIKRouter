//
//  ZIKClassCapabilities.h
//  ZIKRouter
//
//  Created by zuik on 2018/6/14.
//  Copyright © 2018 zuik. All rights reserved.
//

#import "ZIKPlatformCapabilities.h"

#ifndef ZIKClassCapabilities_h
#define ZIKClassCapabilities_h

#if ZIK_HAS_UIKIT

#import <UIKit/UIKit.h>

typedef UIApplication XXApplication;
typedef UIViewController XXViewController;
typedef UIView XXView;
typedef UIWindow XXWindow;
typedef UIResponder XXResponder;
typedef UIStoryboard XXStoryboard;
typedef UIStoryboardSegue XXStoryboardSegue;
typedef UITabBarController XXTabBarController;
typedef UISplitViewController XXSplitViewController;
typedef UIPageViewController XXPageViewController;

#else

#import <AppKit/AppKit.h>

typedef NSApplication XXApplication;
typedef NSViewController XXViewController;
typedef NSView XXView;
typedef NSWindow XXWindow;
typedef NSResponder XXResponder;
typedef NSStoryboard XXStoryboard;
typedef NSStoryboardSegue XXStoryboardSegue;
typedef NSTabViewController XXTabBarController;
typedef NSSplitViewController XXSplitViewController;
typedef NSPageController XXPageViewController;

#endif

#endif /* ZIKClassCapabilities_h */
