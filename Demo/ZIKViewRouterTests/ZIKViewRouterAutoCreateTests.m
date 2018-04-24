//
//  ZIKViewRouterAutoCreateTests.m
//  ZIKViewRouterTests
//
//  Created by zuik on 2018/4/23.
//  Copyright © 2018 zuik. All rights reserved.
//

#import "ZIKViewRouterTestCase.h"
#import "TestPerformSegueViewController.h"
#import "TestPerformSegueViewRouter.h"
#import "ZIKInfoViewProtocol.h"

@interface ZIKViewRouterTestCase()
@property (nonatomic, strong) UIViewController *masterViewController;
@property (nonatomic, strong) TestPerformSegueViewRouter *sourceRouter;
@end

@interface ZIKViewRouterAutoCreateTests : ZIKViewRouterTestCase

@end

@implementation ZIKViewRouterAutoCreateTests

- (void)enterSourceViewWithSuccess:(void(^)(UIViewController *source))successHandler {
    self.sourceRouter = [TestPerformSegueViewRouter performPath:ZIKViewRoutePath.pushFrom(self.masterViewController) configuring:^(ZIKViewRouteConfig * _Nonnull config) {
        config.animated = NO;
        config.successHandler = ^(id  _Nonnull destination) {
            NSLog(@"%@: enterSourceView succeed", destination);
            if (successHandler) {
                successHandler(destination);
            }
        };
    }];
}

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testAutoCreateFromSegue {
    XCTestExpectation *showDestinationExpectation = [self expectationWithDescription:@"show destination from external"];
    XCTestExpectation *prepareDestinationFromExternalExpectation = [self expectationWithDescription:@"prepareDestinationFromExternal"];
    XCTestExpectation *prepareForSegueExpectation = [self expectationWithDescription:@"prepareForSegue"];
    [self enterTest:^(UIViewController *s) {
        TestPerformSegueViewController *source = (TestPerformSegueViewController *)s;
        source.prepareForSegueMonitor = ^(UIStoryboardSegue *segue) {
            XCTAssert([segue.identifier isEqualToString:@"presentInfo"]);
            XCTAssert([segue.destinationViewController conformsToProtocol:@protocol(ZIKInfoViewProtocol)]);
            [prepareForSegueExpectation fulfill];
        };
        source.prepareDestinationFromExternalMonitor = ^(id destination, ZIKViewRouteConfiguration *config) {
            XCTAssert([destination conformsToProtocol:@protocol(ZIKInfoViewProtocol)]);
            [prepareDestinationFromExternalExpectation fulfill];
        };
        
        [source performSegueWithIdentifier:@"presentInfo" sender:nil];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            UIViewController<ZIKInfoViewProtocol> *destination = (UIViewController<ZIKInfoViewProtocol> *)source.presentedViewController;
            XCTAssert([destination conformsToProtocol:@protocol(ZIKInfoViewProtocol)]);
            XCTAssertNotNil(destination.name);
            XCTAssert(source == (id)destination.delegate);
            if (destination) {
                [showDestinationExpectation fulfill];
            }
            [destination dismissViewControllerAnimated:NO completion:^{
                [self leaveTest];
            }];
        });
    }];
    
    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
        !error? : NSLog(@"%@", error);
    }];
}

@end

#import "SourceViewController.h"
#import "BSubview.h"
#import "BSubviewInput.h"

@interface ZIKViewRouterAutoCreateSubviewTests : ZIKViewRouterTestCase

@end

@implementation ZIKViewRouterAutoCreateSubviewTests

- (void)testAutoCreateFromAddsubviewToSuperviewInWindow {
    XCTestExpectation *prepareDestinationFromExternalExpectation = [self expectationWithDescription:@"prepareDestinationFromExternal"];
    [self enterTest:^(UIViewController *s) {
        SourceViewController *source = (SourceViewController *)s;
        BSubview *destinationView = [[BSubview alloc] init];
        source.prepareDestinationFromExternalMonitor = ^(id destination, ZIKViewRouteConfiguration *config) {
            XCTAssert([destination conformsToProtocol:@protocol(BSubviewInput)]);
            XCTAssert(destinationView == destination);
            [prepareDestinationFromExternalExpectation fulfill];
        };
        
        [source.view addSubview:destinationView];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self leaveTest];
        });
    }];
    
    [self waitForExpectationsWithTimeout:500 handler:^(NSError * _Nullable error) {
        !error? : NSLog(@"%@", error);
    }];
}

- (void)testAutoCreateFromAddsubviewToSuperviewNotInWindow {
    XCTestExpectation *prepareDestinationFromExternalExpectation = [self expectationWithDescription:@"prepareDestinationFromExternal"];
    [self enterTest:^(UIViewController *s) {
        SourceViewController *source = (SourceViewController *)s;
        BSubview *destinationView = [[BSubview alloc] init];
        source.prepareDestinationFromExternalMonitor = ^(id destination, ZIKViewRouteConfiguration *config) {
            XCTAssert([destination conformsToProtocol:@protocol(BSubviewInput)]);
            XCTAssert(destinationView == destination);
            [prepareDestinationFromExternalExpectation fulfill];
        };
        
        UIView *superviewNotInWindow = [[UIView alloc] init];
        [superviewNotInWindow addSubview:destinationView];
        [source.view addSubview:superviewNotInWindow];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self leaveTest];
        });
    }];
    
    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
        !error? : NSLog(@"%@", error);
    }];
}

@end
