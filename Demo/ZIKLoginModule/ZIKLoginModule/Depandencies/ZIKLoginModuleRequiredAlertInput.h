//
//  ZIKLoginModuleRequiredAlertInput.h
//  ZIKLoginModule
//
//  Created by zuik on 2018/5/25.
//  Copyright © 2018 zuik. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ZIKRouter/ZIKViewModuleRoutable.h>

NS_ASSUME_NONNULL_BEGIN

/// Alert module required by login module. The host app is responsible for adapting the real alert module with this protocol. See DemoRouteAdapter.
@protocol ZIKLoginModuleRequiredAlertInput <ZIKViewModuleRoutable>
@property(nonatomic,copy) NSString *title;
@property(nullable,nonatomic,copy) NSString *message;
- (void)addCancelButtonTitle:(NSString *)cancelButtonTitle handler:(void (^__nullable)(void))handler;
- (void)addOtherButtonTitle:(NSString *)otherButtonTitle handler:(void (^__nullable)(void))handler;
- (void)addDestructiveButtonTitle:(NSString *)destructiveButtonTitle handler:(void (^)(void))handler;
@end

/**
 ZIKLoginModule provides default dependency registration. It's wrapped by macro.
 
 The host app can directly call this registration function, just by adding USE_DEFAULT_DEPENDENCY_ZIKLoginModule=1 in Build Settings -> Preprocessor Macros of the host app.
 
 If the host app want to use other dependency instead of ZIKCompatibleAlertModuleInput in ZIKAlertModule, it can ignore this code and registering other adaptee.
*/
#if USE_DEFAULT_DEPENDENCY_ZIKLoginModule
@import ZIKRouter;
@import ZIKAlertModule;

static inline void registerDependencyOfZIKLoginModule() {
    [ZIKViewRouteAdapter registerModuleAdapter:ZIKRoutable(ZIKLoginModuleRequiredAlertInput) forAdaptee:ZIKRoutable(ZIKCompatibleAlertModuleInput)];
}

// Adapting code for default dependency registration
#define ADAPT_DEFAULT_DEPENDENCY_ZIKLoginModule    \
@interface ZIKCompatibleAlertViewConfiguration (ZIKLoginModuleRequiredAlertInput) <ZIKLoginModuleRequiredAlertInput>    \
@end    \
@implementation ZIKCompatibleAlertViewConfiguration (ZIKLoginModuleRequiredAlertInput) \
@end    \

#endif

NS_ASSUME_NONNULL_END
