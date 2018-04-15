//
//  AViewInput.h
//  ZIKRouterTests
//
//  Created by zuik on 2018/4/11.
//  Copyright © 2018年 zuik. All rights reserved.
//

@import ZIKRouter;

NS_ASSUME_NONNULL_BEGIN

@protocol AViewInput <ZIKViewRoutable>

@property (nonatomic, copy, nullable) NSString *title;

@end

NS_ASSUME_NONNULL_END
