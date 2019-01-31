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

/// Abstract registry for router classes and protocols. In consideration of performance, methods in registry are not thread safe.
@interface ZIKRouteRegistry : NSObject
/// Whether auto register all routers when app launches. Default is YES. You can set this to NO before UIApplicationMain, and manually register your routers with +registerAll or call +registerRoutableDestination for each router.
@property (nonatomic, class) BOOL autoRegister;
/// Whether registration is finished.
@property (nonatomic, class, readonly) BOOL registrationFinished;

#pragma mark Manually Register

/// Search all router classes and register.
+ (void)registerAll;

/// Notify that registration is finished, when you register routers by calling each router's +registerRoutableDestination. It's for rejecting any registration later and let routers call +_didFinishRegistration.
+ (void)notifyRegistrationFinished;

@end

NS_ASSUME_NONNULL_END
