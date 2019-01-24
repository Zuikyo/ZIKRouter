//
//  EasyServiceInput.h
//  ZIKRouterTests
//
//  Created by zuik on 2019/1/24.
//  Copyright © 2019 zuik. All rights reserved.
//

#import <Foundation/Foundation.h>
@import ZIKRouter;

NS_ASSUME_NONNULL_BEGIN

@protocol EasyServiceInput <ZIKServiceRoutable>

@property (nonatomic, copy, nullable) NSString *title;

@end

NS_ASSUME_NONNULL_END
