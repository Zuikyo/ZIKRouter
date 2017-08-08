//
//  ZIKCompatibleAlertViewRouter.h
//  ZIKRouterDemo
//
//  Created by zuik on 2017/7/6.
//  Copyright © 2017年 zuik. All rights reserved.
//

@import ZIKRouter;
#import "ZIKCompatibleAlertConfigProtocol.h"

NS_ASSUME_NONNULL_BEGIN

DeclareRoutableConfigProtocol(ZIKCompatibleAlertConfigProtocol, ZIKCompatibleAlertViewRouter)

@interface ZIKCompatibleAlertViewConfiguration : ZIKViewRouteConfiguration <NSCopying, ZIKCompatibleAlertConfigProtocol>
@property(nonatomic,copy) NSString *title;
@property(nullable,nonatomic,copy) NSString *message;
- (void)addCancelButtonTitle:(NSString *)cancelButtonTitle handler:(void (^__nullable)(void))handler;
- (void)addOtherButtonTitle:(NSString *)otherButtonTitle handler:(void (^__nullable)(void))handler;
- (void)addDestructiveButtonTitle:(NSString *)destructiveButtonTitle handler:(void (^)(void))handler;
@end

@interface ZIKCompatibleAlertViewRouter : ZIKViewRouter <ZIKViewRouterProtocol>

- (ZIKCompatibleAlertViewConfiguration *)configuration;

- (nullable instancetype)initWithConfiguration:(ZIKCompatibleAlertViewConfiguration *)configuration
                           removeConfiguration:(nullable ZIKCompatibleAlertViewConfiguration *)removeConfiguration;

- (nullable instancetype)initWithConfigure:(void(^)(ZIKCompatibleAlertViewConfiguration *config))configBuilder
                           removeConfigure:(void(^ _Nullable)(__kindof ZIKViewRemoveConfiguration *config))removeConfigBuilder;

+ (nullable __kindof ZIKViewRouter *)performWithSource:(id)source NS_UNAVAILABLE;

+ (nullable __kindof ZIKViewRouter *)performWithConfigure:(void(^)(ZIKCompatibleAlertViewConfiguration *config))configBuilder;
+ (nullable __kindof ZIKViewRouter *)performWithConfigure:(void(^)(ZIKCompatibleAlertViewConfiguration *config))configBuilder
                                          removeConfigure:(void(^)( __kindof ZIKViewRemoveConfiguration * config))removeConfigBuilder;
@end

NS_ASSUME_NONNULL_END
