//
//  ZIKPlatformCapabilities.h
//  ZIKRouter
//
//  Created by zuik on 2018/6/14.
//  Copyright © 2018 zuik. All rights reserved.
//

#ifndef ZIKPlatformCapabilities_h
#define ZIKPlatformCapabilities_h

#ifdef __APPLE__
#include <TargetConditionals.h>
#endif

#if TARGET_OS_IOS || TARGET_OS_TV || TARGET_OS_WATCH
#define ZIK_HAS_UIKIT 1
#elif TARGET_OS_MAC
#define ZIK_HAS_UIKIT 0
#else
#error "Unsupported Platform"
#endif

#endif /* ZIKPlatformCapabilities_h */
