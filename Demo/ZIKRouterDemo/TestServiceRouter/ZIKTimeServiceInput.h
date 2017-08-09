//
//  ZIKTimeServiceInput.h
//  ZIKRouterDemo
//
//  Created by zuik on 2017/8/9.
//  Copyright © 2017年 zuik. All rights reserved.
//

#import <Foundation/Foundation.h>

//If ZIKTimeServiceInput is not registered as routable protocol, remember to remove this macro
#define _ZIKTimeServiceInput_ (Protocol<ZIKRoutableServiceDynamicGetter> *)@protocol(ZIKTimeServiceInput)

@protocol ZIKTimeServiceInput <NSObject>
- (NSString *)currentTimeString;
@end
