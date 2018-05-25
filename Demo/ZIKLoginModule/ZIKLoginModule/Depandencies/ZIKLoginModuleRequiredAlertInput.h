//
//  ZIKLoginModuleRequiredAlertInput.h
//  ZIKLoginModule
//
//  Created by zuik on 2018/5/25.
//  Copyright © 2018 duoyi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ZIKRouter/ZIKViewModuleRoutable.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ZIKLoginModuleRequiredAlertInput <ZIKViewModuleRoutable>
@property(nonatomic,copy) NSString *title;
@property(nullable,nonatomic,copy) NSString *message;
- (void)addCancelButtonTitle:(NSString *)cancelButtonTitle handler:(void (^__nullable)(void))handler;
- (void)addOtherButtonTitle:(NSString *)otherButtonTitle handler:(void (^__nullable)(void))handler;
- (void)addDestructiveButtonTitle:(NSString *)destructiveButtonTitle handler:(void (^)(void))handler;
@end

NS_ASSUME_NONNULL_END
