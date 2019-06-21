//
//  AppRouteRegistry.m
//  ZIKRouterDemo
//
//  Created by zuik on 2018/4/6.
//  Copyright © 2018 zuik. All rights reserved.
//

#import "AppRouteRegistry.h"
@import ZIKRouter.Internal;
#if DEBUG
@import ZIKRouter.Private;
#endif

#pragma mark Objc Router

#import "TestShowViewRouter.h"
#import "TestViewRouterViewRouter.h"
#import "ZIKSimpleLabelRouter.h"
#import "TestPerformSegueViewRouter.h"
#import "TestAddAsChildViewRouter.h"
#import "TestCircularDependenciesViewRouter.h"
#import "EmptyContainerViewRouter.h"
#import "MasterViewRouter.h"
#import "TestMakeDestinationViewRouter.h"
#import "TestAddAsSubviewViewRouter.h"
#import "TestAddAsSubviewViewController.h"
#import "TestPresentModallyViewRouter.h"
#import "TestShowDetailViewRouter.h"
#import "TestPresentAsPopoverViewRouter.h"
#import "ZIKChildViewRouter.h"
#import "TestClassHierarchyViewRouter.h"
#import "SubclassViewRouter.h"
#import "TestAutoCreateViewRouter.h"
#import "TestPushViewRouter.h"
#import "TestCustomViewRouter.h"
#import "TestURLRouterViewRouter.h"
#import "URLRouteHandler.h"
#import "ZIKInfoViewRouter.h"
#import <ZIKAlertModule/ZIKCompatibleAlertViewRouter.h>
#import <ZIKLoginModule/ZIKLoginModule.h>
#import "TestServiceRouterViewRouter.h"
#import "TestURLServiceRouter.h"
#import "ZIKTimeServiceRouter.h"

#pragma mark Objc Adapter

#import "DemoRouteAdapter.h"
#import "ZIKRouterDemo-Swift.h"


@implementation AppRouteRegistry

#pragma mark Manually Register

#if !AUTO_REGISTER_ROUTERS

+ (void)load {
    ZIKRouteRegistry.autoRegister = NO;
    [self registerEarlyRequiredModules];
}

#endif

+ (void)registerEarlyRequiredModules {
    [URLRouteHandler registerRoutableDestination];
    [MasterViewRouter registerRoutableDestination];
    [AppSwiftRouteRegistry registerEarlyRequiredModules];
}

+ (void)manuallyRegisterEachRouter {
    
#if DEBUG
    NSString *importingCode = codeForImportingRouters();
    NSString *registeringCode = codeForRegisteringRouters();
    NSLog(@"\n\n---Code for importing routers when manually register routers:---\n%@\n\n---Code for manually registering routers:---\n%@\n", importingCode, registeringCode);
#endif
    
    // Objc routers
    [TestViewRouterViewRouter registerRoutableDestination];
    [ZIKLoginViewRouter registerRoutableDestination];
    [TestShowViewRouter registerRoutableDestination];
    [ZIKSimpleLabelRouter registerRoutableDestination];
    [TestPerformSegueViewRouter registerRoutableDestination];
    [TestAddAsChildViewRouter registerRoutableDestination];
    [TestCircularDependenciesViewRouter registerRoutableDestination];
    [EmptyContainerViewRouter registerRoutableDestination];
//    [MasterViewRouter registerRoutableDestination];
    [TestMakeDestinationViewRouter registerRoutableDestination];
    [TestAddAsSubviewViewRouter registerRoutableDestination];
    [TestContentViewRouter registerRoutableDestination];
    [TestPresentModallyViewRouter registerRoutableDestination];
    [TestShowDetailViewRouter registerRoutableDestination];
    [TestPresentAsPopoverViewRouter registerRoutableDestination];
    [ZIKChildViewRouter registerRoutableDestination];
    [TestClassHierarchyViewRouter registerRoutableDestination];
    [SubclassViewRouter registerRoutableDestination];
    [TestAutoCreateViewRouter registerRoutableDestination];
    [TestPushViewRouter registerRoutableDestination];
    [TestCustomViewRouter registerRoutableDestination];
    [TestURLRouterViewRouter registerRoutableDestination];
    [ZIKInfoViewRouter registerRoutableDestination];
    [ZIKCompatibleAlertViewRouter registerRoutableDestination];
    [TestServiceRouterViewRouter registerRoutableDestination];
    [ZIKTimeServiceRouter registerRoutableDestination];
    [TestURLServiceRouter registerRoutableDestination];
    
    ///Can't access swift routers, because it uses generic. You have to register swift router in swift code.
//    [SwiftSampleViewRouter registerRoutableDestination];
//    [SwiftServiceRouter registerRoutableDestination];
    
    [AppSwiftRouteRegistry manuallyRegisterEachRouter];
    
    // Objc adapters
    [DemoRouteAdapter registerRoutableDestination];
    
    // Finish
    [ZIKRouteRegistry notifyRegistrationFinished];
}

@end
