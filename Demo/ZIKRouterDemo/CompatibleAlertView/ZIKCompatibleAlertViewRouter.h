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
 In Swift 4, you can't cast router type like this:
 @code
 var alertRouterClass: ZIKViewRouter<ZIKViewRouteConfiguration, ZIKViewRemoveConfiguration>.Type?
 
 //Swift 4 compiles with error, but in Swift 3, this is allowed.
 //ZIKCompatibleAlertViewRouter.Type is ZIKViewRouter<ZIKViewRouteConfiguration & ZIKCompatibleAlertConfigProtocol, ZIKViewRemoveConfiguration>.Type
 alertRouterClass = ZIKCompatibleAlertViewRouter.self
 @endcode
 If you wan't to use ZIKCompatibleAlertViewRouter more freely, you can remove `<ZIKCompatibleAlertConfigProtocol>` in ViewRouteConfiguration, and let user to specify the ViewRouteConfiguration when they use. But it's not that safe:
 @code
 var alertRouterClass: ZIKViewRouter<ZIKViewRouteConfiguration & ZIKCompatibleAlertConfigProtocol, ZIKViewRemoveConfiguration>.Type?
 
 //This is allowed in Swift 4
 alertRouterClass = ZIKCompatibleAlertViewRouter.self
 
 var routerClass: ZIKViewRouter<ZIKViewRouteConfiguration, ZIKViewRemoveConfiguration>.Type?
 routerClass = ZIKCompatibleAlertViewRouter.self
 @endcode
 */
@interface ZIKCompatibleAlertViewRouter<__covariant ViewRouteConfiguration: ZIKViewRouteConfiguration<ZIKCompatibleAlertConfigProtocol> *, __covariant ViewRemoveConfiguration: ZIKViewRemoveConfiguration *> : ZIKViewRouter<ViewRouteConfiguration, ViewRemoveConfiguration> <ZIKViewRouterProtocol>
+ (nullable __kindof ZIKViewRouter *)performWithSource:(id)source NS_UNAVAILABLE;
@end

NS_ASSUME_NONNULL_END
