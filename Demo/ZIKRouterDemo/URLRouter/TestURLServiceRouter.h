//
//  TestURLServiceRouter.h
//  ZIKRouterDemo
//
//  Created by zuik on 2019/4/19.
//  Copyright © 2019 zuik. All rights reserved.
//

#import "ZIKServiceURLRouter.h"

NS_ASSUME_NONNULL_BEGIN

@interface AlertService : NSObject
- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message;
@end

@interface TestURLAlertServiceConfiguration : ZIKPerformRouteConfiguration
@property(nonatomic,copy) NSString *title;
@property(nullable,nonatomic,copy) NSString *message;
@end

@interface TestURLServiceRouter : ZIKServiceURLRouter<AlertService *, TestURLAlertServiceConfiguration *>

@end

NS_ASSUME_NONNULL_END
