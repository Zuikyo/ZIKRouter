//
//  TestAddAsSubviewViewController.m
//  ZIKRouterDemo
//
//  Created by zuik on 2017/7/5.
//  Copyright © 2017 zuik. All rights reserved.
//

#import "TestAddAsSubviewViewController.h"
@import ZIKRouter.Internal;
#import "ZIKSimpleLabelProtocol.h"
#import "ZIKInfoViewProtocol.h"

@interface TestContentView : UIView <ZIKRoutableView>
@end
@implementation TestContentView
@end

@interface TestAddAsSubviewViewController ()
@property (nonatomic, strong) ZIKViewRouter *labelRouter;
@end

@implementation TestAddAsSubviewViewController

- (void)loadView {
    UIView *view = [TestContentView new];
    self.view = view;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    UIButton *button1 = [UIButton buttonWithType:UIButtonTypeSystem];
    button1.frame = CGRectMake(100, 200, 200, 80);
    [button1 setTitle:@"addAsSubview" forState:UIControlStateNormal];
    [button1 addTarget:self action:@selector(addAsSubview:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button1];
    
    UIButton *button2 = [UIButton buttonWithType:UIButtonTypeSystem];
    button2.frame = CGRectMake(100, 400, 100, 80);
    [button2 setTitle:@"push" forState:UIControlStateNormal];
    [button2 addTarget:self action:@selector(push:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button2];
}

- (IBAction)addAsSubview:(id)sender {
    self.labelRouter = [ZIKRouterToView(ZIKSimpleLabelProtocol)
                        performPath:ZIKViewRoutePath.addAsSubviewFrom(self.view)
                        configuring:^(ZIKViewRouteConfiguration * _Nonnull config) {
                            config.prepareDestination = ^(id<ZIKSimpleLabelProtocol>  _Nonnull destination) {
                                destination.text = @"this is a label from router";
                                destination.frame = CGRectMake(50, 250, 200, 50);
                            };
                            config.successHandler = ^(UIView * _Nonnull destination) {
                                NSLog(@"add as subview complete");
                            };
                            config.errorHandler = ^(ZIKRouteAction routeAction, NSError * _Nonnull error) {
                                NSLog(@"add as subview failed: %@",error);
                            };
                        }];
}

- (IBAction)push:(id)sender {
    [ZIKRouterToView(ZIKInfoViewProtocol) performPath:ZIKViewRoutePath.pushFrom(self)];
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

@implementation TestContentViewRouter

+ (void)registerRoutableDestination {
#if TEST_BLOCK_ROUTES
    [ZIKDestinationViewRoute(TestContentView *) makeRouteWithDestination:[TestContentView class] makeDestination:^TestContentView * _Nullable(ZIKViewRouteConfig * _Nonnull config, __kindof ZIKRouter<TestContentView *,ZIKViewRouteConfig *,ZIKViewRemoveConfiguration *> * _Nonnull router) {
        return [[TestContentView alloc] init];
    }]
    .shouldAutoCreateForDestination(^BOOL(TestContentView *destination, id  _Nullable source) {
        if ([destination zix_isRootView] && [destination zix_isDuringNavigationTransitionBack]) {
            return NO;
        }
        return YES;
    })
    .prepareDestination(^(TestContentView *_Nonnull destination, ZIKViewRouteConfig * _Nonnull config, ZIKViewRouter * _Nonnull router) {
        destination.frame = [UIApplication sharedApplication].keyWindow.frame;
    })
    .makeSupportedRouteTypes(^ZIKBlockViewRouteTypeMask{
        return ZIKBlockViewRouteTypeMaskViewDefault;
    });
#endif
    [self registerView:[TestContentView class]];
}

+ (BOOL)shouldAutoCreateForDestination:(id)destination fromSource:(id)source {
    // You can check whether the destination already has a router or is already prepared, then you can ignore this auto creating.
    if ([destination zix_isRootView] && [destination zix_isDuringNavigationTransitionBack]) {
        return NO;
    }
    return YES;
}

- (TestContentView *)destinationWithConfiguration:(ZIKPerformRouteConfiguration *)configuration {
    return [TestContentView new];
}

- (void)prepareDestination:(TestContentView *)destination configuration:(ZIKViewRouteConfiguration *)configuration {
    destination.frame = [UIApplication sharedApplication].keyWindow.frame;
}

+ (ZIKViewRouteTypeMask)supportedRouteTypes {
    return ZIKViewRouteTypeMaskViewDefault;
}

+ (void)router:(nullable ZIKViewRouter *)router willPerformRouteOnDestination:(id)destination fromSource:(id)source {
    NSLog(@"\n----------------------\nrouter: (%@),\n\
          ➡️ will\n\
          perform route\n\
          from source: (%@),\n\
          destination: (%@),\n----------------------",router, source, destination);
}

+ (void)router:(nullable ZIKViewRouter *)router didPerformRouteOnDestination:(id)destination fromSource:(id)source {
    NSLog(@"\n----------------------\nrouter: (%@),\n\
          ✅ did\n\
          perform route\n\
          from source: (%@),\n\
          destination: (%@),\n----------------------",router, source, destination);
}

+ (void)router:(nullable ZIKViewRouter *)router willRemoveRouteOnDestination:(id)destination fromSource:(id)source {
    NSLog(@"\n----------------------\nrouter: (%@),\n\
          ⬅️ will\n\
          remove route\n\
          from source: (%@),\n\
          destination: (%@),\n----------------------",router, source, destination);
}

+ (void)router:(nullable ZIKViewRouter *)router didRemoveRouteOnDestination:(id)destination fromSource:(id)source {
    NSLog(@"\n----------------------\nrouter: (%@),\n\
          ❎ did\n\
          remove route\n\
          from source: (%@),\n\
          destination: (%@),\n----------------------",router, source, destination);
}

@end
