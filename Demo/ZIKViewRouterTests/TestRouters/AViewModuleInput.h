//
//  AViewModuleInput.h
//  ZIKRouterTests
//
//  Created by zuik on 2018/4/20.
//  Copyright © 2018 zuik. All rights reserved.
//

@import ZIKRouter;
#import "AViewInput.h"

@protocol AViewModuleInput <ZIKViewModuleRoutable>

@property (nonatomic, copy, nullable) NSString *title;

- (void)makeDestinationCompletion:(void(^)(id<AViewInput> destination))block;

@end
