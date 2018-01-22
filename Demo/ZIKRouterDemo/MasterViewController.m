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

@end

@implementation MasterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    if ([self respondsToSelector:@selector(registerForPreviewingWithDelegate:sourceView:)]) {
        [self registerForPreviewingWithDelegate:self sourceView:self.view];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    self.clearsSelectionOnViewWillAppear = self.splitViewController.isCollapsed;
    [super viewWillAppear:animated];
}

#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
}


#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 15;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    
    NSString *name;
    ZIKRouterTestType testType = indexPath.row;
    switch (testType) {
        case ZIKRouterTestTypePush:
            name = @"Test Push";
            break;
        case ZIKRouterTestTypePresentModally:
            name = @"Test PresentModally";
            break;
        case ZIKRouterTestTypePresentAsPopover:
            name = @"Test PresentAsPopover";
            break;
        case ZIKRouterTestTypePerformSegue:
            name = @"Test PerformSegue";
            break;
        case ZIKRouterTestTypeShow:
            name = @"Test Show";
            break;
        case ZIKRouterTestTypeShowDetail:
            name = @"Test ShowDetail";
            break;
        case ZIKRouterTestTypeAddAsChildViewController:
            name = @"Test AddAsChildViewController";
            break;
        case ZIKRouterTestTypeAddAsSubview:
            name = @"Test AddAsSubview";
            break;
        case ZIKRouterTestTypeCustom:
            name = @"Test Custom";
            break;
        case ZIKRouterTestTypeGetDestination:
            name = @"Test GetDestination";
            break;
        case ZIKRouterTestTypeAutoCreate:
            name = @"Test AutoCreate";
            break;
        case ZIKRouterTestTypeCircularDependencies:
            name = @"Test Circular Dependencies";
            break;
        case ZIKRouterTestTypeSubclassHierarchy:
            name = @"Test Subclass Hierarchy";
            break;
        case ZIKRouterTestTypeServiceRouter:
            name = @"Test ServiceRouter";
            break;
        case ZIKRouterTestTypeSwiftSample:
            name = @"Swift Sample";
            break;
        default:
            name = @"undefined";
            break;
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
    ZIKRouterTestType testType = indexPath.row;
    switch (testType) {
        case ZIKRouterTestTypePush:
            routerClass = [ZIKTestPushViewRouter class];
            break;
            
        case ZIKRouterTestTypePresentModally:
            routerClass = [ZIKTestPresentModallyViewRouter class];
            break;
            
        case ZIKRouterTestTypePresentAsPopover:
            routerClass = [ZIKTestPresentAsPopoverViewRouter class];
            break;
            
        case ZIKRouterTestTypePerformSegue:
            routerClass = [ZIKTestPerformSegueViewRouter class];
            break;
            
        case ZIKRouterTestTypeShow:
            routerClass = [ZIKTestShowViewRouter class];
            break;
            
        case ZIKRouterTestTypeShowDetail:
            routerClass = [ZIKTestShowDetailViewRouter class];
            break;
            
        case ZIKRouterTestTypeAddAsChildViewController:
            routerClass = [ZIKTestAddAsChildViewRouter class];
            break;
            
        case ZIKRouterTestTypeAddAsSubview:
            routerClass = [ZIKTestAddAsSubviewViewRouter class];
            break;
            
        case ZIKRouterTestTypeCustom:
            routerClass = [ZIKTestCustomViewRouter class];
            break;
            
        case ZIKRouterTestTypeGetDestination:
            routerClass = [ZIKTestGetDestinationViewRouter class];
            break;
            
        case ZIKRouterTestTypeAutoCreate:
            routerClass = [ZIKTestAutoCreateViewRouter class];
            break;
            
        case ZIKRouterTestTypeCircularDependencies:
            routerClass = [ZIKTestCircularDependenciesViewRouter class];
            break;
            
        case ZIKRouterTestTypeSubclassHierarchy:
            routerClass = [TestClassHierarchyViewRouter class];
            break;
            
        case ZIKRouterTestTypeServiceRouter:
            routerClass = [ZIKTestServiceRouterViewRouter class];
            break;
            
        case ZIKRouterTestTypeSwiftSample:
//            routerClass = [SwiftSampleViewRouter class];
            routerClass = ZIKViewRouter.classToView(ZIKRoutableProtocol(SwiftSampleViewInput));
            break;
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
