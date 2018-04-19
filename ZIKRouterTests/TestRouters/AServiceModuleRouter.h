//
//  AServiceModuleRouter.h
//  ZIKRouterTests
//
//  Created by zuik on 2018/4/19.
//  Copyright © 2018 zuik. All rights reserved.
//

@import ZIKRouter;
#import "AServiceModuleInput.h"

@interface AServiceModuleRouter : ZIKModuleServiceRouter(AServiceModuleInput)

@end

@interface AServiceModuleConfiguration: ZIKPerformRouteConfiguration <AServiceModuleInput>

@property (nonatomic, copy, nullable) NSString *title;

- (void)makeDestinationCompletion:(void(^)(id<AServiceInput> destination))block;

@end
