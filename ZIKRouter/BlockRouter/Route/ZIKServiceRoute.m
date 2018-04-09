//
//  ZIKServiceRoute.m
//  ZIKRouter
//
//  Created by zuik on 2018/4/8.
//  Copyright © 2018 zuik. All rights reserved.
//

#import "ZIKServiceRoute.h"
#import "ZIKBlockServiceRouter.h"
#import "ZIKServiceRouteRegistry.h"

@implementation ZIKServiceRoute
@dynamic registerDestination;
@dynamic registerDestinationProtocol;
@dynamic registerModuleProtocol;
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
