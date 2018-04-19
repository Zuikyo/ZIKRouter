//
//  AViewModuleRouter.h
//  ZIKRouterTests
//
//  Created by zuik on 2018/4/20.
//  Copyright © 2018 zuik. All rights reserved.
//

@import ZIKRouter;
#import "AViewModuleInput.h"

@interface AViewModuleRouter : ZIKModuleViewRouter(AViewModuleInput)

@end

@interface AViewModuleConfiguration: ZIKViewRouteConfiguration <AViewModuleInput>

@property (nonatomic, copy, nullable) NSString *title;

- (void)makeDestinationCompletion:(void(^)(id<AViewInput> destination))block;

@end
