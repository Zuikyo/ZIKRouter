//
//  ZIKRouteConfigurationPrivate.h
//  ZIKRouter
//
//  Created by zuik on 2017/10/26.
//  Copyright © 2017 zuik. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "ZIKRouteConfiguration.h"

NS_ASSUME_NONNULL_BEGIN

@class ZIKRoute;
@interface ZIKPerformRouteConfiguration()
@property (nonatomic, strong, nullable) ZIKRoute *route;
/// Let ZIKRoute inject the defaultRouteConfiguration to the router.
@property (nonatomic, strong, nullable) ZIKPerformRouteConfiguration *injected;
- (void)removeUserInfo;
@end

@interface ZIKRemoveRouteConfiguration()
/// Let ZIKRoute inject the defaultRemoveConfiguration to the router.
@property (nonatomic, strong, nullable) ZIKRemoveRouteConfiguration *injected;
@end

@interface ZIKRouteStrictConfiguration()
@property (nonatomic, strong) ZIKRouteConfiguration *configuration;
@end

@interface ZIKPerformRouteStrictConfiguration()
@property (nonatomic, strong) ZIKPerformRouteConfiguration *configuration;
@end

@interface ZIKRemoveRouteStrictConfiguration()
@property (nonatomic, strong) ZIKRemoveRouteConfiguration *configuration;
@end

NS_ASSUME_NONNULL_END
