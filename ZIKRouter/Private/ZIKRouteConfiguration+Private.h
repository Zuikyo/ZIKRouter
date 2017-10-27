//
//  ZIKRouteConfiguration+Private.h
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

@interface ZIKRouteConfiguration ()
///Error handler for router's performer, will reset to nil after perform.
@property (nonatomic, copy, nullable) ZIKRouteErrorHandler performerErrorHandler;
///Success handler for router's performer, will reset to nil after perform.
@property (nonatomic, copy, nullable) void(^performerSuccessHandler)(void);
@end

NS_ASSUME_NONNULL_END
