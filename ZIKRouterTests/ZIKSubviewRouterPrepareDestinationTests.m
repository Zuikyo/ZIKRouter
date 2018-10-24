//
//  ZIKSubviewRouterPrepareDestinationTests.m
//  ZIKRouterTests
//
//  Created by zuik on 2018/4/19.
//  Copyright © 2018 zuik. All rights reserved.
//

#import "ZIKRouterTestCase.h"
#import "BSubviewInput.h"
#import "BSubview.h"

@interface ZIKSubviewRouterPrepareDestinationTests : ZIKRouterTestCase

@end

@implementation ZIKSubviewRouterPrepareDestinationTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testPrepareDestinationWithSuccessHandler {
    XCTestExpectation *successHandlerExpectation = [self expectationWithDescription:@"successHandler"];
    XCTestExpectation *performerSuccessHandlerExpectation = [self expectationWithDescription:@"performerSuccessHandler"];
    XCTestExpectation *completionHandlerExpectation = [self expectationWithDescription:@"completionHandler"];
    @autoreleasepool {
        [self enterTest];
        BSubview *destination = [[BSubview alloc] init];
        self.router = [ZIKRouterToView(BSubviewInput) prepareDestination:destination configuring:^(ZIKViewRouteConfiguration * _Nonnull config) {
            config.prepareDestination = ^(id<BSubviewInput>  _Nonnull destination) {
                destination.title = @"test title";
            };
            config.successHandler = ^(id  _Nonnull destination) {
                [successHandlerExpectation fulfill];
            };
            config.performerSuccessHandler = ^(id  _Nonnull destination) {
                [performerSuccessHandlerExpectation fulfill];
            };
            config.errorHandler = ^(ZIKRouteAction  _Nonnull routeAction, NSError * _Nonnull error) {
                XCTAssert(NO, @"errorHandler should not be called");
            };
            config.performerErrorHandler = ^(ZIKRouteAction  _Nonnull routeAction, NSError * _Nonnull error) {
                XCTAssert(NO, @"performerErrorHandler should not be called");
            };
            config.completionHandler = ^(BOOL success, id  _Nullable destination, ZIKRouteAction  _Nonnull routeAction, NSError * _Nullable error) {
                XCTAssertTrue(success);
                [completionHandlerExpectation fulfill];
                [self handle:^{
                    XCTAssertNotNil(self.router);
                    [self leaveTest];
                }];
            };
        }];
        XCTAssert([destination.title isEqualToString:@"test title"]);
        self.destination = destination;
    }
    
    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
        !error? : NSLog(@"%@", error);
    }];
}

- (void)testPrepareDestinationWithErrorHandler {
    XCTestExpectation *errorHandlerExpectation = [self expectationWithDescription:@"errorHandler"];
    XCTestExpectation *performerErrorHandlerExpectation = [self expectationWithDescription:@"performerErrorHandler"];
    XCTestExpectation *completionHandlerExpectation = [self expectationWithDescription:@"completionHandler"];
    @autoreleasepool {
        [self enterTest];
        id invalidDestination = [[UIViewController alloc] init];
        self.router = [ZIKRouterToView(BSubviewInput) prepareDestination:invalidDestination configuring:^(ZIKViewRouteConfiguration * _Nonnull config) {
            config.prepareDestination = ^(id<BSubviewInput>  _Nonnull destination) {
                destination.title = @"test title";
            };
            config.successHandler = ^(id  _Nonnull destination) {
                XCTAssert(NO, @"successHandler should not be called");
            };
            config.performerSuccessHandler = ^(id  _Nonnull destination) {
                XCTAssert(NO, @"performerErrorHandler should not be called");
            };
            config.errorHandler = ^(ZIKRouteAction  _Nonnull routeAction, NSError * _Nonnull error) {
                [errorHandlerExpectation fulfill];
            };
            config.performerErrorHandler = ^(ZIKRouteAction  _Nonnull routeAction, NSError * _Nonnull error) {
                [performerErrorHandlerExpectation fulfill];
            };
            config.completionHandler = ^(BOOL success, id  _Nullable destination, ZIKRouteAction  _Nonnull routeAction, NSError * _Nullable error) {
                XCTAssertFalse(success);
                XCTAssertNotNil(error);
                [completionHandlerExpectation fulfill];
                [self handle:^{
                    XCTAssertNil(self.router);
                    [self leaveTest];
                }];
            };
        }];
        self.destination = invalidDestination;
    }
    
    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
        !error? : NSLog(@"%@", error);
    }];
}

- (void)testStrictPrepareDestinationWithSuccessHandler {
    XCTestExpectation *successHandlerExpectation = [self expectationWithDescription:@"successHandler"];
    XCTestExpectation *performerSuccessHandlerExpectation = [self expectationWithDescription:@"performerSuccessHandler"];
    XCTestExpectation *completionHandlerExpectation = [self expectationWithDescription:@"completionHandler"];
    @autoreleasepool {
        [self enterTest];
        BSubview *destination = [[BSubview alloc] init];
        self.router = [ZIKRouterToView(BSubviewInput)
                       prepareDestination:destination
                       strictConfiguring:^(ZIKPerformRouteStrictConfiguration<id<BSubviewInput>> *config, ZIKViewRouteConfiguration * _Nonnull module) {
                           config.prepareDestination = ^(id<BSubviewInput> destination) {
                               destination.title = @"test title";
                           };
                           config.successHandler = ^(id<BSubviewInput> destination) {
                               [successHandlerExpectation fulfill];
                           };
                           config.performerSuccessHandler = ^(id<BSubviewInput> destination) {
                               [performerSuccessHandlerExpectation fulfill];
                           };
                           config.errorHandler = ^(ZIKRouteAction  _Nonnull routeAction, NSError * _Nonnull error) {
                               XCTAssert(NO, @"errorHandler should not be called");
                           };
                           config.performerErrorHandler = ^(ZIKRouteAction  _Nonnull routeAction, NSError * _Nonnull error) {
                               XCTAssert(NO, @"performerErrorHandler should not be called");
                           };
                           config.completionHandler = ^(BOOL success, id<BSubviewInput> _Nullable destination, ZIKRouteAction  _Nonnull routeAction, NSError * _Nullable error) {
                               XCTAssertTrue(success);
                               [completionHandlerExpectation fulfill];
                               [self handle:^{
                                   XCTAssertNotNil(self.router);
                                   [self leaveTest];
                               }];
                           };
                       }];
        XCTAssert([destination.title isEqualToString:@"test title"]);
        self.destination = destination;
    }
    
    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
        !error? : NSLog(@"%@", error);
    }];
}

- (void)testStrictPrepareDestinationWithErrorHandler {
    XCTestExpectation *errorHandlerExpectation = [self expectationWithDescription:@"errorHandler"];
    XCTestExpectation *performerErrorHandlerExpectation = [self expectationWithDescription:@"performerErrorHandler"];
    XCTestExpectation *completionHandlerExpectation = [self expectationWithDescription:@"completionHandler"];
    
    @autoreleasepool {
        [self enterTest];
        id invalidDestination = [[UIViewController alloc] init];
        self.router = [ZIKRouterToView(BSubviewInput)
                       prepareDestination:invalidDestination
                       strictConfiguring:^(ZIKPerformRouteStrictConfiguration<id<BSubviewInput>> *config, ZIKViewRouteConfiguration * _Nonnull module) {
                           config.prepareDestination = ^(id<BSubviewInput> destination) {
                               destination.title = @"test title";
                           };
                           config.successHandler = ^(id<BSubviewInput> destination) {
                               XCTAssert(NO, @"successHandler should not be called");
                           };
                           config.performerSuccessHandler = ^(id<BSubviewInput> destination) {
                               XCTAssert(NO, @"performerErrorHandler should not be called");
                           };
                           config.errorHandler = ^(ZIKRouteAction  _Nonnull routeAction, NSError * _Nonnull error) {
                               [errorHandlerExpectation fulfill];
                           };
                           config.performerErrorHandler = ^(ZIKRouteAction  _Nonnull routeAction, NSError * _Nonnull error) {
                               [performerErrorHandlerExpectation fulfill];
                           };
                           config.completionHandler = ^(BOOL success, id<BSubviewInput> _Nullable destination, ZIKRouteAction  _Nonnull routeAction, NSError * _Nullable error) {
                               XCTAssertFalse(success);
                               XCTAssertNotNil(error);
                               [completionHandlerExpectation fulfill];
                               [self handle:^{
                                   XCTAssertNil(self.router);
                                   [self leaveTest];
                               }];
                           };
                       }];
        self.destination = invalidDestination;
    }
    
    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
        !error? : NSLog(@"%@", error);
    }];
}

@end
