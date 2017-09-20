//
//  ZIKTimeServiceInput.h
//  ZIKRouterDemo
//
//  Created by zuik on 2017/8/9.
//  Copyright © 2017年 zuik. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ZIKRouter/ZIKServiceRoutable.h>

//If ZIKTimeServiceInput is not registered as routable protocol, remember to remove this macro
#define ZIKTimeServiceInput_routable @protocol(ZIKTimeServiceInput)

@protocol ZIKTimeServiceInput <ZIKServiceRoutable>
- (NSString *)currentTimeString;
@end
