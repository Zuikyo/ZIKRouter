//
//  ObjcService.h
//  ZRouterTests
//
//  Created by zuik on 2018/5/23.
//  Copyright © 2018年 zuik. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ObjcServiceInput
@end

@protocol ObjcServiceSubInput <ObjcServiceInput>
@end

@interface ObjcService : NSObject<ObjcServiceSubInput>

@end

@interface ObjcSubService : ObjcService

@end
