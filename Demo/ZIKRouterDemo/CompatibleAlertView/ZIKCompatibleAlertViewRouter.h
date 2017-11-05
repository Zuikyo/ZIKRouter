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

/**
 In Swift, you can't cast router type like this:
 @code
 let alertRouterClass: ZIKViewRouter<ZIKViewRouteConfiguration, ZIKViewRemoveConfiguration>.Type
 
 //Compiler error, bacause Swift doesn't support covariance for custom generic yet.
 //ZIKCompatibleAlertViewRouter.Type is ZIKViewRouter<ZIKViewRouteConfiguration & ZIKCompatibleAlertConfigProtocol, ZIKViewRemoveConfiguration>.Type
 alertRouterClass = ZIKCompatibleAlertViewRouter.self
 @endcode
 
 Solution 1:
 If you wan't to use ZIKCompatibleAlertViewRouter more freely, you can remove `<ZIKCompatibleAlertConfigProtocol>` in ViewRouteConfiguration, and let user to specify the ViewRouteConfiguration when they use. But it's not that safe:
 @code
 let alertRouterClass: ZIKViewRouter<ZIKViewRouteConfiguration & ZIKCompatibleAlertConfigProtocol, ZIKViewRemoveConfiguration>.Type
 
 //This is allowed in Swift
 alertRouterClass = ZIKCompatibleAlertViewRouter.self
 
 var routerClass: ZIKViewRouter<ZIKViewRouteConfiguration, ZIKViewRemoveConfiguration>.Type?
 routerClass = ZIKCompatibleAlertViewRouter.self
 @endcode
 
 Solution 2:
 If you want to keep `<ZIKCompatibleAlertConfigProtocol>`, you can cast ZIKCompatibleAlertViewRouter to ZIKViewRouter<ZIKViewRouteConfiguration, ZIKViewRemoveConfiguration>.Type with ZIKViewRouter.forModule():
 @code
 let routerClass: ZIKViewRouter<ZIKViewRouteConfiguration, ZIKViewRemoveConfiguration>.Type
 routerClass = ZIKViewRouter.forModule(ZIKCompatibleAlertConfigProtocol.self) as! ZIKViewRouter<ZIKViewRouteConfiguration, ZIKViewRemoveConfiguration>.Type
 @endcode
 */
@interface ZIKCompatibleAlertViewRouter<__covariant RouteConfig: ZIKViewRouteConfiguration<ZIKCompatibleAlertConfigProtocol> *, __covariant RemoveConfig: ZIKViewRemoveConfiguration *> : ZIKViewRouter<RouteConfig, RemoveConfig> <ZIKViewRouterProtocol>
+ (nullable ZIKViewRouter *)performWithSource:(nullable id)source routeType:(ZIKViewRouteType)routeType NS_UNAVAILABLE;
@end

NS_ASSUME_NONNULL_END
