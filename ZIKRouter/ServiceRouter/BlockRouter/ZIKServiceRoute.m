//
//  ZIKServiceRoute.m
//  ZIKRouter
//
//  Created by zuik on 2018/4/8.
//  Copyright © 2018 zuik. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "ZIKServiceRoute.h"
#import "ZIKBlockServiceRouter.h"
#import "ZIKServiceRouteRegistry.h"

@implementation ZIKServiceRoute
@dynamic nameAs;
@dynamic registerDestination;
@dynamic registerExclusiveDestination;
@dynamic registerDestinationProtocol;
@dynamic registerModuleProtocol;
@dynamic registerIdentifier;
@dynamic makeDefaultConfiguration;
@dynamic makeDefaultRemoveConfiguration;
@dynamic prepareDestination;
@dynamic didFinishPrepareDestination;

- (Class)routerClass {
    return [ZIKBlockServiceRouter class];
}

+ (Class)registryClass {
    return [ZIKServiceRouteRegistry class];
}

@end
