//
//  MasterViewController.m
//  ZIKRouterDemo
//
//  Created by zuik on 2017/7/5.
//  Copyright © 2017 zuik. All rights reserved.
//

#import "MasterViewController.h"

#import "TestPushViewRouter.h"
#import "TestPresentModallyViewRouter.h"
#import "TestPresentAsPopoverViewRouter.h"
#import "TestPerformSegueViewRouter.h"
#import "TestShowViewRouter.h"
#import "TestShowDetailViewRouter.h"
#import "TestAddAsChildViewRouter.h"
#import "TestAddAsSubviewViewRouter.h"
#import "TestCustomViewRouter.h"
#import "TestGetDestinationViewRouter.h"
#import "TestAutoCreateViewRouter.h"
#import "TestCircularDependenciesViewRouter.h"
#import "TestClassHierarchyViewRouter.h"
#import "TestServiceRouterViewRouter.h"
#import "TestURLRouterViewRouter.h"
#import <ZIKLoginModule/ZIKLoginModule.h>
#import "ZIKRouterDemo-Swift.h"

typedef NS_ENUM(NSInteger,ZIKRouterTestType) {
    ZIKRouterTestTypePush,
    ZIKRouterTestTypePresentModally,
    ZIKRouterTestTypePresentAsPopover,
    ZIKRouterTestTypePerformSegue,
    ZIKRouterTestTypeShow NS_ENUM_AVAILABLE_IOS(8_0),
    ZIKRouterTestTypeShowDetail NS_ENUM_AVAILABLE_IOS(8_0),
    ZIKRouterTestTypeAddAsChildViewController,
    ZIKRouterTestTypeAddAsSubview,
    ZIKRouterTestTypeCustom,
    ZIKRouterTestTypeGetDestination,
    ZIKRouterTestTypeAutoCreate,
    ZIKRouterTestTypeCircularDependencies,
    ZIKRouterTestTypeSubclassHierarchy,
    ZIKRouterTestTypeServiceRouter,
    ZIKRouterTestTypeSwiftSample,
    ZIKRouterTestTypeURLRouter,
    ZIKRouterTestTypeModularization
};

@interface MasterViewController () <UIViewControllerPreviewingDelegate>
@property (nonatomic, strong) NSArray<NSString *> *cellNames;
@property (nonatomic, strong) NSArray<Class> *routerClasses;
@end

@implementation MasterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    if ([self respondsToSelector:@selector(registerForPreviewingWithDelegate:sourceView:)]) {
        [self registerForPreviewingWithDelegate:self sourceView:self.view];
    }
    self.cellNames = @[
                       @"Test Push",
                       @"Test PresentModally",
                       @"Test PresentAsPopover",
                       @"Test PerformSegue",
                       @"Test Show",
                       @"Test ShowDetail",
                       @"Test AddAsChildViewController",
                       @"Test AddAsSubview",
                       @"Test Custom",
                       @"Test GetDestination",
                       @"Test AutoCreate",
                       @"Test Circular Dependencies",
                       @"Test Subclass Hierarchy",
                       @"Test ServiceRouter",
                       @"Swift Sample",
                       @"URL Router",
                       @"Test Modularization"
                       ];
    self.routerClasses = @[
                           [TestPushViewRouter class],
                           [TestPresentModallyViewRouter class],
                           [TestPresentAsPopoverViewRouter class],
                           [TestPerformSegueViewRouter class],
                           [TestShowViewRouter class],
                           [TestShowDetailViewRouter class],
                           [TestAddAsChildViewRouter class],
                           [TestAddAsSubviewViewRouter class],
                           [TestCustomViewRouter class],
                           [TestGetDestinationViewRouter class],
                           [TestAutoCreateViewRouter class],
                           [TestCircularDependenciesViewRouter class],
                           [TestClassHierarchyViewRouter class],
                           [TestServiceRouterViewRouter class],
                           ZIKViewRouter.toView(ZIKRoutable(SwiftSampleViewInput)),
                           [TestURLRouterViewRouter class],
                           [ZIKLoginViewRouter class]
                           ];
    
    NSAssert(self.cellNames.count == self.routerClasses.count, nil);
}

- (void)viewWillAppear:(BOOL)animated {
    self.clearsSelectionOnViewWillAppear = self.splitViewController.isCollapsed;
    [super viewWillAppear:animated];
}

#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
}


#pragma mark - Table View


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.cellNames.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    
    NSString *name = @"undefined";
    if (self.cellNames.count > indexPath.row) {
        name = self.cellNames[indexPath.row];
    }
    cell.textLabel.text = name;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    id routerType = [self routerClassForIndexPath:indexPath];
    ZIKViewRoutePath *routePath;
    ZIKRouterTestType testType = indexPath.row;
    switch (testType) {
        case ZIKRouterTestTypePush:
        case ZIKRouterTestTypeShow:
        case ZIKRouterTestTypeShowDetail:
        case ZIKRouterTestTypeAutoCreate:
            routePath = ZIKViewRoutePath.pushFrom(self);
            break;
        
        default:
            routePath = ZIKViewRoutePath.showDetailFrom(self);
            break;
    }
    
    [routerType performPath:routePath];
}

- (Class)routerClassForIndexPath:(NSIndexPath *)indexPath {
    Class routerClass;
    if (self.routerClasses.count > indexPath.row) {
        routerClass = self.routerClasses[indexPath.row];
    }
    return routerClass;
}

#pragma mark UIViewControllerPreviewingDelegate

- (nullable UIViewController *)previewingContext:(id <UIViewControllerPreviewing>)previewingContext viewControllerForLocation:(CGPoint)location {
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:location];
    Class routerClass = [self routerClassForIndexPath:indexPath];
    UIViewController *destinationViewController = [routerClass makeDestination];
    
    NSAssert(destinationViewController != nil, nil);
    return destinationViewController;
}

- (void)previewingContext:(id <UIViewControllerPreviewing>)previewingContext commitViewController:(UIViewController *)viewControllerToCommit {
    ZIKAnyViewRouterType *routerType = [ZIKViewRouter.routersToClass([viewControllerToCommit class]) firstObject];
    if (routerType != nil) {
        [routerType performOnDestination:viewControllerToCommit path:ZIKViewRoutePath.pushFrom(self)];
    } else {
        [self.navigationController pushViewController:viewControllerToCommit animated:YES];
    }
}
@end
