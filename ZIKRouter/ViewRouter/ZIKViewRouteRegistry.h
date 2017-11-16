//
//  ZIKViewRouteRegistry.h
//  ZIKRouter
//
//  Created by zuik on 2017/11/15.
//  Copyright © 2017年 zuik. All rights reserved.
//

#import "ZIKRouteRegistry.h"

@interface ZIKViewRouteRegistry : ZIKRouteRegistry

+ (BOOL)isDestinationClass:(Class)destinationClass registeredWithRouter:(Class)routerClass;

@end
