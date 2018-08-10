//
//  AppRouteRegistry.m
//  ZIKRouterDemo
//
//  Created by zuik on 2018/4/6.
//  Copyright © 2018 zuik. All rights reserved.
//

#import "AppRouteRegistry.h"
@import ZIKRouter.Internal;

#pragma mark Objc Router

#import "TestShowViewRouter.h"
#import "TestServiceRouterViewRouter.h"
#import "ZIKSimpleLabelRouter.h"
#import "TestPerformSegueViewRouter.h"
#import "TestAddAsChildViewRouter.h"
#import "TestCircularDependenciesViewRouter.h"
#import "EmptyContainerViewRouter.h"
#import "MasterViewRouter.h"
#import "TestGetDestinationViewRouter.h"
#import "TestAddAsSubviewViewRouter.h"
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
#import "ZIKTimeServiceRouter.h"

#pragma mark Objc Adapter

#import "DemoRouteAdapter.h"

#import "ZIKRouterDemo-Swift.h"


@implementation AppRouteRegistry

#pragma mark Manually Register

#if !AUTO_REGISTER_ROUTERS

+ (void)load {
    ZIKRouteRegistry.autoRegister = NO;
    [self registerForModulesBeforeRegistrationFinished];
}

#endif

+ (void)registerForModulesBeforeRegistrationFinished {
    [URLRouteHandler registerRoutableDestination];
    [MasterViewRouter registerRoutableDestination];
    
    //MasterViewController uses router for SwiftSampleViewRouter
    [AppSwiftRouteRegistry manuallyRegisterEachRouter];
}

+ (void)manuallyRegisterEachRouter {
    
#if DEBUG
    [self printCodeForImportHeaders];
    [self printCodeForManuallyRegistering];
#endif
    
    // Objc routers
    [ZIKLoginViewRouter registerRoutableDestination];
    [TestShowViewRouter registerRoutableDestination];
    [TestServiceRouterViewRouter registerRoutableDestination];
    [ZIKSimpleLabelRouter registerRoutableDestination];
    [TestPerformSegueViewRouter registerRoutableDestination];
    [TestAddAsChildViewRouter registerRoutableDestination];
    [TestCircularDependenciesViewRouter registerRoutableDestination];
    [EmptyContainerViewRouter registerRoutableDestination];
//    [MasterViewRouter registerRoutableDestination];
    [TestGetDestinationViewRouter registerRoutableDestination];
    [TestAddAsSubviewViewRouter registerRoutableDestination];
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
    [ZIKTimeServiceRouter registerRoutableDestination];
    
    ///Can't access swift routers, because it use generic. You have to register swift router in swift code.
//    [SwiftSampleViewRouter registerRoutableDestination];
//    [SwiftServiceRouter registerRoutableDestination];
    
    // Objc adapters
    [DemoRouteAdapter registerRoutableDestination];
    
    // Finish
    [ZIKRouteRegistry notifyRegistrationFinished];
}

+ (NSString *)printCodeForManuallyRegistering {
    NSArray<Class> *objcRouters = [ZIKRouteRegistry allExternalObjcRouters];
    NSArray<Class> *swiftRouters = [ZIKRouteRegistry allExternalSwiftRouters];
    NSArray<Class> *objcAdapters = [ZIKRouteRegistry allObjcAdapters];
    NSArray<Class> *swiftAdapters = [ZIKRouteRegistry allSwiftAdapters];
    
    NSMutableString *code = [NSMutableString string];
    void(^generateCodeForRouters)(NSArray<Class> *) = ^(NSArray<Class> *routers) {
        for (Class class in routers) {
            [code appendFormat:@"[%@ registerRoutableDestination];\n",NSStringFromClass(class)];
        }
    };
    [code appendString:@"\n// Objc routers\n"];
    generateCodeForRouters(objcRouters);
    
    [code appendString:@"\n// Swift routers\n"];
    [code appendString:@"///Can't access swift routers, because they use generic. You have to register swift router in swift code.\n"];
    generateCodeForRouters(swiftRouters);
    
    [code appendString:@"\n// Objc adapters\n"];
    generateCodeForRouters(objcAdapters);
    
    [code appendString:@"\n// Swift adapters\n"];
    [code appendString:@"///Can't access swift adapters, because they use generic. You have to register swift router in swift code.\n"];
    generateCodeForRouters(swiftAdapters);
    
    NSLog(@"%@",code);
    return code;
}

+ (NSString *)printCodeForImportHeaders {
    NSArray<Class> *objcRouters = [ZIKRouteRegistry allExternalObjcRouters];
    NSArray<Class> *objcAdapters = [ZIKRouteRegistry allObjcAdapters];
    
    NSBundle *mainBundle = [NSBundle mainBundle];
    
    NSMutableString *code = [NSMutableString string];
    
    void(^generateCodeForRouters)(NSArray<Class> *) = ^(NSArray<Class> *routers) {
        for (Class class in routers) {
            NSBundle *bundle = [NSBundle bundleForClass:class];
            NSAssert1(bundle, @"Failed to get bundle for class %@",NSStringFromClass(class));
            if ([bundle isEqual:mainBundle]) {
                [code appendFormat:@"\n#import \"%@.h\"",NSStringFromClass(class)];
            } else {
                NSString *bundleName = [bundle.infoDictionary objectForKey:(__bridge NSString *)kCFBundleNameKey];
                NSAssert2(bundle, @"Failed to get bundle name for class %@, bundle:%@",NSStringFromClass(class), bundle);
                NSString *headerPath = [bundle.bundlePath stringByAppendingPathComponent:[NSString stringWithFormat:@"Headers/%@.h",NSStringFromClass(class)]];
                if ([[NSFileManager defaultManager] fileExistsAtPath:headerPath]) {
                    [code appendFormat:@"\n#import <%@/%@.h>",bundleName,NSStringFromClass(class)];
                } else {
                    [code appendFormat:@"\n#import <%@/%@.h>",bundleName,bundleName];
                }
            }
        }
    };
    
    [code appendString:@"\n#pragma mark Objc Router\n"];
    generateCodeForRouters(objcRouters);
    
    [code appendString:@"\n\n#pragma mark Objc Adapter\n"];
    generateCodeForRouters(objcAdapters);
    
    NSLog(@"%@",code);
    return code;
}

@end
