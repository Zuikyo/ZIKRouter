//
//  EmptyContainerViewController.m
//  ZIKRouterDemo
//
//  Created by zuik on 2017/7/7.
//  Copyright © 2017 zuik. All rights reserved.
//

#import "EmptyContainerViewController.h"
@import ZIKRouter;
#import "ZIKInfoViewProtocol.h"
#import "ZIKSimpleLabel.h"

@interface EmptyContainerViewController () <ZIKInfoViewDelegate>

@end

@implementation EmptyContainerViewController

///Add subview by code or storyboard will auto create a corresponding router. We assume its superview's view controller as the performer. If your custom class view use a routable view as its part, the custom view should use a router to add and prepare the routable view, then the routable view don't need to search performer.

/**
 When a routable view is added from storyboard
 Invoking order in subview when subview needs prepare:
 1.willMoveToSuperview:
 2.didMoveToSuperview
 3.ZIKViewRouter_hook_viewDidLoad
    3.didFinishPrepareDestination:configuration:
    4.viewDidLoad
 5.willMoveToWindow:
    6.router:willPerformRouteOnDestination:fromSource:
 7.didMoveToWindow
 
 Invoking order in subview when subview doesn't need prepare:
 1.willMoveToSuperview:
    2.didFinishPrepareDestination:configuration:
    3.router:willPerformRouteOnDestination:fromSource:
 4.didMoveToSuperview
 5.willMoveToWindow:
 6.didMoveToWindow
 */
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (UIViewController<ZIKInfoViewProtocol> *)childInfoViewController {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    return [sb instantiateViewControllerWithIdentifier:@"childInfo"];
}

///Route UIViewController by code manually won't auto create a corresponding router, but router classes registered with the view controller will get AOP callback
- (IBAction)addChildManually:(id)sender {
    CGRect frame = [sender frame];
    frame.origin.y += 40;
    UIViewController<ZIKInfoViewProtocol> *childInfoViewController = [self childInfoViewController];
    
    childInfoViewController.delegate = self;
    [self addChildViewController:childInfoViewController];
    [self.view addSubview:childInfoViewController.view];
    [childInfoViewController didMoveToParentViewController:self];
}

/**
 Directly add to visible self.view.
 Invoking order in subview:
 1.willMoveToWindow:
 2.willMoveToSuperview:
    3.didFinishPrepareDestination:configuration:
    4.router:willPerformRouteOnDestination:fromSource:
 5.didMoveToWindow
 6.didMoveToSuperview
 */
- (IBAction)addSubviewManually:(id)sender {
    UIButton *button = sender;
    ZIKSimpleLabel *destination = [[ZIKSimpleLabel alloc] init];
    destination.text = @"Label added manually";
    destination.frame = CGRectMake(button.frame.origin.x, button.frame.origin.y - 100, 200, 50);
    [self.view addSubview:destination];
}

/**
 Add to a superview, then add the superview to self.view.
 Invoking order in subview when subview needs prepare:
 1.willMoveToSuperview:
 2.didMoveToSuperview
 3.willMoveToWindow:
 4.didMoveToWindow
    5.didFinishPrepareDestination:configuration:
    6.router:willPerformRouteOnDestination:fromSource:
 
 Invoking order in subview when subview doesn't need prepare:
 1.willMoveToSuperview:
    2.didFinishPrepareDestination:configuration:
 3.didMoveToSuperview
 4.willMoveToWindow:
    5.router:willPerformRouteOnDestination:fromSource:
 6.didMoveToWindow
 */
- (IBAction)addSubviewManually2:(id)sender {
    UIButton *button = sender;
    ZIKSimpleLabel *destination = [[ZIKSimpleLabel alloc] init];
    destination.text = @"Label added manually 2";
    destination.frame = CGRectMake(button.frame.origin.x, button.frame.origin.y - 100, 200, 50);
    UIView *superview = [UIView new];
    [superview addSubview:destination];
    [self.view addSubview:superview];
}

/**
 Add to a superviw, but the superview was never added to any view controller. This should get an error when subview need prepare.
 Invoking order in subview when subview needs prepare:
 1.willMoveToSuperview:newSuperview
 2.didMoveToSuperview
 3.willMoveToSuperview:nil
    4.when detected that last preparing is not finished, get invalid performer error
 5.didMoveToSuperview
 
 Invoking order in subview when subview doesn't need prepare:
 1.willMoveToSuperview:newSuperview
    2.didFinishPrepareDestination:configuration:
 3.didMoveToSuperview
 4.willMoveToSuperview:nil
    5.router:willPerformRouteOnDestination:fromSource:
    6.router:didPerformRouteOnDestination:fromSource: (the view was never displayed after added, so willMoveToWindow: is never be invoked, so router need to end the perform route action here.)
    7.router:willRemoveRouteOnDestination:fromSource:
 8.didMoveToSuperview
    9.router:didRemoveRouteOnDestination:fromSource:
 */
- (IBAction)addSubviewManuallyWithoutViewController:(id)sender {
    UIButton *button = sender;
    ZIKSimpleLabel *destination = [[ZIKSimpleLabel alloc] init];
//        destination.text = @"Label added manually";
    destination.frame = CGRectMake(button.frame.origin.x, button.frame.origin.y - 100, 200, 50);
    UIView *superview = [UIView new];
    [superview addSubview:destination];
}

/**
 Add to an UIWindow.  This should get an error when subview need prepare.
 Invoking order in subview when subview needs prepare:
 1.willMoveToWindow:newWindow
 2.willMoveToSuperview:newSuperview
    3.when detected that newSuperview is already on screen, but can't find the performer, get invalid performer error
 4.didMoveToWindow
 5.didMoveToSuperview
 
 Invoking order in subview when subview doesn't need prepare:
 1.willMoveToWindow:newWindow
 2.willMoveToSuperview:newSuperview
    3.didFinishPrepareDestination:configuration:
    4.router:willPerformRouteOnDestination:fromSource:
 5.didMoveToWindow
 6.didMoveToSuperview
 */
- (IBAction)addSubviewManuallyWithoutViewController2:(id)sender {
    UIButton *button = sender;
    ZIKSimpleLabel *destination = [[ZIKSimpleLabel alloc] init];
//        destination.text = @"Label added manually";
    destination.frame = CGRectMake(button.frame.origin.x, button.frame.origin.y - 100, 200, 50);
    [self.view.window addSubview:destination];
}

- (void)handleRemoveInfoViewController:(UIViewController *)infoViewController {
    [infoViewController willMoveToParentViewController:nil];
    [infoViewController.view removeFromSuperview];
    [infoViewController removeFromParentViewController];
}

- (void)prepareDestinationFromExternal:(id)destination configuration:(__kindof ZIKViewRouteConfiguration *)configuration {
    if ([destination conformsToProtocol:@protocol(ZIKInfoViewProtocol)]) {
        id<ZIKInfoViewProtocol> infoView = destination;
        infoView.name = @"Zuik";
        infoView.age = 18;
        infoView.delegate = self;
        return;
    } else if ([destination conformsToProtocol:@protocol(ZIKSimpleLabelProtocol)]) {
        id<ZIKSimpleLabelProtocol> simpleLabel = destination;
        simpleLabel.text = @"Label added manually";
        return;
    }
    NSAssert(NO, @"Can't prepare for unknown destination.");
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
