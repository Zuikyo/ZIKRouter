//
//  ZIKCompatibleAlertViewRouter.h
//  ZIKRouterDemo
//
//  Created by zuik on 2017/7/6.
//  Copyright © 2017 zuik. All rights reserved.
//

@import ZIKRouter;
#import "ZIKCompatibleAlertConfigProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZIKCompatibleAlertViewConfiguration : ZIKViewRouteConfiguration <NSCopying, ZIKCompatibleAlertConfigProtocol>
@property(nonatomic,copy) NSString *title;
@property(nullable,nonatomic,copy) NSString *message;
- (void)addCancelButtonTitle:(NSString *)cancelButtonTitle handler:(void (^__nullable)(void))handler;
- (void)addOtherButtonTitle:(NSString *)otherButtonTitle handler:(void (^__nullable)(void))handler;
- (void)addDestructiveButtonTitle:(NSString *)destructiveButtonTitle handler:(void (^)(void))handler;
@end

@interface ZIKCompatibleAlertViewRouter: ZIKModuleViewRouter(ZIKCompatibleAlertConfigProtocol)
+ (nullable ZIKViewRouter *)performFromSource:(nullable id)source routeType:(ZIKViewRouteType)routeType NS_UNAVAILABLE;
@end

NS_ASSUME_NONNULL_END
