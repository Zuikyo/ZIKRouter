//
//  ZIKViewRouteRegistry.h
//  ZIKRouter
//
//  Created by zuik on 2017/11/15.
//  Copyright © 2017 zuik. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "ZIKRouteRegistry.h"

@interface ZIKViewRouteRegistry : ZIKRouteRegistry

+ (BOOL)isDestinationClass:(Class)destinationClass registeredWithRouter:(Class)routerClass;

@end
