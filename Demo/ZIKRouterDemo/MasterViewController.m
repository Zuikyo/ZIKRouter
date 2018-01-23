//
//  MasterViewController.m
//  ZIKRouterDemo
//
//  Created by zuik on 2017/7/5.
//  Copyright © 2017 zuik. All rights reserved.
//

#import "MasterViewController.h"

#import "ZIKTestPushViewRouter.h"
#import "ZIKTestPresentModallyViewRouter.h"
#import "ZIKTestPresentAsPopoverViewRouter.h"
#import "ZIKTestPerformSegueViewRouter.h"
#import "ZIKTestShowViewRouter.h"
#import "ZIKTestShowDetailViewRouter.h"
#import "ZIKTestAddAsChildViewRouter.h"
#import "ZIKTestAddAsSubviewViewRouter.h"
#import "ZIKTestCustomViewRouter.h"
#import "ZIKTestGetDestinationViewRouter.h"
#import "ZIKTestAutoCreateViewRouter.h"
#import "ZIKTestCircularDependenciesViewRouter.h"
#import "TestClassHierarchyViewRouter.h"
#import "ZIKTestServiceRouterViewRouter.h"
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
    ZIKRouterTestTypeSwiftSample
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
                       @"Swift Sample"
                       ];
    self.routerClasses = @[
                           [ZIKTestPushViewRouter class],
                           [ZIKTestPresentModallyViewRouter class],
                           [ZIKTestPresentAsPopoverViewRouter class],
                           [ZIKTestPerformSegueViewRouter class],
                           [ZIKTestShowViewRouter class],
                           [ZIKTestShowDetailViewRouter class],
                           [ZIKTestAddAsChildViewRouter class],
                           [ZIKTestAddAsSubviewViewRouter class],
                           [ZIKTestCustomViewRouter class],
                           [ZIKTestGetDestinationViewRouter class],
                           [ZIKTestAutoCreateViewRouter class],
                           [ZIKTestCircularDependenciesViewRouter class],
                           [TestClassHierarchyViewRouter class],
                           [ZIKTestServiceRouterViewRouter class],
                           ZIKViewRouter.classToView(ZIKRoutableProtocol(SwiftSampleViewInput))
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
    
    Class routerClass = [self routerClassForIndexPath:indexPath];
    ZIKRouterTestType testType = indexPath.row;
    ZIKViewRouteType routeType = ZIKViewRouteTypeShowDetail;
    switch (testType) {
        case ZIKRouterTestTypePush:
        case ZIKRouterTestTypeShow:
        case ZIKRouterTestTypeShowDetail:
        case ZIKRouterTestTypeAutoCreate:
            routeType = ZIKViewRouteTypePush;
            break;
        
        default:
            routeType = ZIKViewRouteTypeShowDetail;
            break;
    }
    
    [routerClass performFromSource:self routeType:routeType];
}

- (Class)routerClassForIndexPath:(NSIndexPath *)indexPath {
    Class routerClass;
    if (self.routerClasses.count > indexPath.row) {
        routerClass = self.routerClasses[indexPath.row];
    }
    return routerClass;
}

- (nullable UIViewController *)previewingContext:(id <UIViewControllerPreviewing>)previewingContext viewControllerForLocation:(CGPoint)location {
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:location];
    Class routerClass = [self routerClassForIndexPath:indexPath];
    UIViewController *destinationViewController = [routerClass makeDestination];
    
    NSAssert(destinationViewController != nil, nil);
    return destinationViewController;
}

- (void)previewingContext:(id <UIViewControllerPreviewing>)previewingContext commitViewController:(UIViewController *)viewControllerToCommit {
    [self.navigationController pushViewController:viewControllerToCommit animated:YES];
}
@end
