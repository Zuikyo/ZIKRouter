//
//  ZIKViewRouteRegistryPrivate.h
//  ZIKRouter
//
//  Created by zuik on 2018/4/16.
//  Copyright © 2018 zuik. All rights reserved.
//

#import "ZIKViewRouteRegistry.h"

@interface ZIKViewRouteRegistry ()

+ (BOOL)isDestinationClass:(Class)destinationClass registeredWithRouter:(Class)routerClass;

@end
