//
//  ZIKRouteRegistry.h
//  ZIKRouter
//
//  Created by zuik on 2017/11/15.
//  Copyright © 2017 zuik. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

///Enble this to check whether all routers and routable protocols are properly implemented.
#ifdef DEBUG
#define ZIKROUTER_CHECK 1
#else
#define ZIKROUTER_CHECK 0
#endif

@interface ZIKRouteRegistry : NSObject
@property (nonatomic, class, readonly) BOOL autoRegistrationFinished;
@end

NS_ASSUME_NONNULL_END
