//
//  RequiredCompatibleAlertModuleInput.h
//  ZIKRouterDemo
//
//  Created by zuik on 2017/7/6.
//  Copyright © 2017 zuik. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ZIKRouter/ZIKViewModuleRoutable.h>

NS_ASSUME_NONNULL_BEGIN

/// Alert module required in this app. The host app is responsible for adapting the real alert module with this protocol. See DemoRouteAdapter.
@protocol RequiredCompatibleAlertModuleInput <ZIKViewModuleRoutable>
@property(nonatomic,copy) NSString *title;
@property(nullable,nonatomic,copy) NSString *message;
- (void)addCancelButtonTitle:(NSString *)cancelButtonTitle handler:(void (^__nullable)(void))handler;
- (void)addOtherButtonTitle:(NSString *)otherButtonTitle handler:(void (^__nullable)(void))handler;
- (void)addDestructiveButtonTitle:(NSString *)destructiveButtonTitle handler:(void (^)(void))handler;
@end

NS_ASSUME_NONNULL_END
