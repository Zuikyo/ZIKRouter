//
//  BSubviewModuleRouter.h
//  ZIKRouterTests
//
//  Created by zuik on 2018/4/20.
//  Copyright © 2018 zuik. All rights reserved.
//

@import ZIKRouter;
#import "BSubviewModuleInput.h"

@interface BSubviewModuleRouter : ZIKModuleViewRouter(BSubviewModuleInput)

@end

@interface BSubviewModuleConfiguration: ZIKViewRouteConfiguration <BSubviewModuleInput>

@property (nonatomic, copy, nullable) NSString *title;

- (void)makeDestinationCompletion:(void(^)(id<BSubviewInput> destination))block;

@end
