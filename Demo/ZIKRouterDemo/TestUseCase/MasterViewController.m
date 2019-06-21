//
//  MasterViewController.m
//  ZIKRouterDemo
//
//  Created by zuik on 2017/7/5.
//  Copyright © 2017 zuik. All rights reserved.
//

#import "MasterViewController.h"
@import ZIKRouter;
#import "TestViewRouterViewRouter.h"
#import "TestServiceRouterViewRouter.h"
#import "ZIKRouterDemo-Swift.h"

@interface MasterViewController ()
@property (nonatomic, strong) NSArray<NSString *> *cellNames;
@property (nonatomic, strong) NSArray<Class> *routerTypes;
@end

@implementation MasterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.cellNames = @[
                       @"Test ViewRouter",
                       @"Test ServiceRouter",
                       @"Decouple Sample"
                       ];
    self.routerTypes = @[
                         [TestViewRouterViewRouter class],
                         [TestServiceRouterViewRouter class],
                         ZIKRouterToView(DecoupleSampleViewInput)
                         ];
    
    
    NSAssert(self.cellNames.count == self.routerTypes.count, nil);
}

- (void)viewWillAppear:(BOOL)animated {
    self.clearsSelectionOnViewWillAppear = self.splitViewController.isCollapsed;
    [super viewWillAppear:animated];
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
    [routerType performPath:ZIKViewRoutePath.pushFrom(self)];
}

- (Class)routerClassForIndexPath:(NSIndexPath *)indexPath {
    Class routerClass;
    if (self.routerTypes.count > indexPath.row) {
        routerClass = self.routerTypes[indexPath.row];
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
