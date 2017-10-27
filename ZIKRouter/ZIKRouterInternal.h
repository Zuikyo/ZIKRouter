//
//  ZIKRouterInternal.h
//  ZIKRouter
//
//  Created by zuik on 2017/5/24.
//  Copyright © 2017 zuik. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "ZIKRouter.h"

NS_ASSUME_NONNULL_BEGIN

///Internal methods for subclass.
@interface ZIKRouter ()
///Previous state.
@property (nonatomic, readonly, assign) ZIKRouterState preState;
///Subclass can get the real configuration to avoid unnecessary copy.
@property (nonatomic, readonly, copy) __kindof ZIKRouteConfiguration *original_configuration;
@property (nonatomic, readonly, copy) __kindof ZIKRouteConfiguration *original_removeConfiguration;
@property (nonatomic, readonly, weak) id destination;

//Attach a destination not created from router.
- (void)attachDestination:(id)destination;

///If a router need to perform on a specific thread, override -performWithConfiguration: and call [super performWithConfiguration:configuration] in that thread.
- (void)performWithConfiguration:(__kindof ZIKRouteConfiguration *)configuration;

///Change state.
- (void)notifyRouteState:(ZIKRouterState)state;

///Call sucessHandler and performerSuccessHandler.
- (void)notifySuccessWithAction:(SEL)routeAction;

///Call errorHandler and performerErrorHandler.
- (void)notifyError:(NSError *)error routeAction:(SEL)routeAction;

+ (NSError *)errorWithCode:(NSInteger)code userInfo:(nullable NSDictionary *)userInfo;
+ (NSError *)errorWithCode:(NSInteger)code localizedDescription:(NSString *)description;
+ (NSError *)errorWithCode:(NSInteger)code localizedDescriptionFormat:(NSString *)format ,...;
@end

NS_ASSUME_NONNULL_END
