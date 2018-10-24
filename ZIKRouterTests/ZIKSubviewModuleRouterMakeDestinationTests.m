//
//  ZIKSubviewModuleRouterMakeDestinationTests.m
//  ZIKRouterTests
//
//  Created by zuik on 2018/4/20.
//  Copyright © 2018 zuik. All rights reserved.
//

#import "ZIKRouterTestCase.h"
#import "BSubviewModuleInput.h"

@interface ZIKSubviewModuleRouterMakeDestinationTests : ZIKRouterTestCase

@end

@implementation ZIKSubviewModuleRouterMakeDestinationTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testMakeDestination {
    @autoreleasepool {
        BOOL canMakeDestination = [ZIKRouterToViewModule(BSubviewModuleInput) canMakeDestination];
        XCTAssertTrue(canMakeDestination);
        id<BSubviewInput> destination = [ZIKRouterToViewModule(BSubviewModuleInput) makeDestination];
        XCTAssertNotNil(destination);
        XCTAssertTrue([(id)destination conformsToProtocol:@protocol(BSubviewInput)]);
        self.destination = destination;
    }
}

- (void)testMakeDestinationWithPreparation {
    @autoreleasepool {
        BOOL canMakeDestination = [ZIKRouterToViewModule(BSubviewModuleInput) canMakeDestination];
        XCTAssertTrue(canMakeDestination);
        id<BSubviewInput> destination = [ZIKRouterToViewModule(BSubviewModuleInput) makeDestinationWithPreparation:^(id<BSubviewInput>  _Nonnull destination) {
            destination.title = @"test title";
        }];
        XCTAssertNotNil(destination);
        XCTAssertTrue([(id)destination conformsToProtocol:@protocol(BSubviewInput)]);
        XCTAssert([destination.title isEqualToString:@"test title"]);
        self.destination = destination;
    }
}

- (void)testMakeDestinationWithPrepareDestination {
    XCTestExpectation *prepareDestinationExpectation = [self expectationWithDescription:@"prepareDestination"];
    XCTestExpectation *successHandlerExpectation = [self expectationWithDescription:@"successHandler"];
    XCTestExpectation *performerSuccessHandlerExpectation = [self expectationWithDescription:@"performerSuccessHandler"];
    XCTestExpectation *completionHandlerExpectation = [self expectationWithDescription:@"completionHandler"];
    BOOL canMakeDestination = [ZIKRouterToViewModule(BSubviewModuleInput) canMakeDestination];
    XCTAssertTrue(canMakeDestination);
    id<BSubviewInput> destination = [ZIKRouterToViewModule(BSubviewModuleInput) makeDestinationWithConfiguring:^(ZIKPerformRouteConfiguration<BSubviewModuleInput> * _Nonnull config) {
        config.title = @"test title";
        [config makeDestinationCompletion:^(id<BSubviewInput> destination) {
            XCTAssert([destination.title isEqualToString:@"test title"]);
        }];
        config.prepareDestination = ^(id<BSubviewInput>  _Nonnull destination) {
            [prepareDestinationExpectation fulfill];
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
        };
    }];
    XCTAssertNotNil(destination);
    XCTAssertTrue([(id)destination conformsToProtocol:@protocol(BSubviewInput)]);
    XCTAssert([destination.title isEqualToString:@"test title"]);
    
    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
        !error? : NSLog(@"%@", error);
    }];
}

- (void)testMakeDestinationWithSuccessHandler {
    XCTestExpectation *successHandlerExpectation = [self expectationWithDescription:@"successHandler"];
    XCTestExpectation *performerSuccessHandlerExpectation = [self expectationWithDescription:@"performerSuccessHandler"];
    XCTestExpectation *completionHandlerExpectation = [self expectationWithDescription:@"completionHandler"];
    BOOL canMakeDestination = [ZIKRouterToViewModule(BSubviewModuleInput) canMakeDestination];
    XCTAssertTrue(canMakeDestination);
    id<BSubviewInput> destination = [ZIKRouterToViewModule(BSubviewModuleInput) makeDestinationWithConfiguring:^(ZIKPerformRouteConfiguration<BSubviewModuleInput> * _Nonnull config) {
        config.title = @"test title";
        [config makeDestinationCompletion:^(id<BSubviewInput> destination) {
            XCTAssert([destination.title isEqualToString:@"test title"]);
        }];
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
        };
    }];
    XCTAssertNotNil(destination);
    XCTAssertTrue([(id)destination conformsToProtocol:@protocol(BSubviewInput)]);
    
    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
        !error? : NSLog(@"%@", error);
    }];
}

- (void)testMakeDestinationWithErrorHandler {
    XCTestExpectation *errorHandlerExpectation = [self expectationWithDescription:@"errorHandler"];
    XCTestExpectation *performerErrorHandlerExpectation = [self expectationWithDescription:@"performerErrorHandler"];
    XCTestExpectation *completionHandlerExpectation = [self expectationWithDescription:@"completionHandler"];
    TestConfig.routeShouldFail = YES;
    BOOL canMakeDestination = [ZIKRouterToViewModule(BSubviewModuleInput) canMakeDestination];
    XCTAssertTrue(canMakeDestination);
    id<BSubviewInput> destination = [ZIKRouterToViewModule(BSubviewModuleInput) makeDestinationWithConfiguring:^(ZIKPerformRouteConfiguration<BSubviewModuleInput> * _Nonnull config) {
        config.title = @"test title";
        [config makeDestinationCompletion:^(id<BSubviewInput> destination) {
            XCTAssert([destination.title isEqualToString:@"test title"]);
        }];
        config.successHandler = ^(id  _Nonnull destination) {
            XCTAssert(NO, @"successHandler should not be called");
        };
        config.performerSuccessHandler = ^(id  _Nonnull destination) {
            XCTAssert(NO, @"performerSuccessHandler should not be called");
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
        };
    }];
    XCTAssertNil(destination);
    
    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
        !error? : NSLog(@"%@", error);
    }];
}

#pragma mark Strict

- (void)testStrictMakeDestinationWithPrepareDestination {
    XCTestExpectation *successHandlerExpectation = [self expectationWithDescription:@"successHandler"];
    XCTestExpectation *performerSuccessHandlerExpectation = [self expectationWithDescription:@"performerSuccessHandler"];
    XCTestExpectation *completionHandlerExpectation = [self expectationWithDescription:@"completionHandler"];
    BOOL canMakeDestination = [ZIKRouterToViewModule(BSubviewModuleInput) canMakeDestination];
    XCTAssertTrue(canMakeDestination);
    id<BSubviewInput> destination = [ZIKRouterToViewModule(BSubviewModuleInput)
                                     makeDestinationWithStrictConfiguring:^(ZIKPerformRouteStrictConfiguration *config, ZIKPerformRouteConfiguration<BSubviewModuleInput> * _Nonnull module) {
                                         module.title = @"test title";
                                         [module makeDestinationCompletion:^(id<BSubviewInput> destination) {
                                             XCTAssert([destination.title isEqualToString:@"test title"]);
                                         }];
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
                                         };
                                     }];
    XCTAssertNotNil(destination);
    XCTAssertTrue([(id)destination conformsToProtocol:@protocol(BSubviewInput)]);
    XCTAssert([destination.title isEqualToString:@"test title"]);
    
    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
        !error? : NSLog(@"%@", error);
    }];
}

- (void)testStrictMakeDestinationWithSuccessHandler {
    XCTestExpectation *successHandlerExpectation = [self expectationWithDescription:@"successHandler"];
    XCTestExpectation *performerSuccessHandlerExpectation = [self expectationWithDescription:@"performerSuccessHandler"];
    XCTestExpectation *completionHandlerExpectation = [self expectationWithDescription:@"completionHandler"];
    BOOL canMakeDestination = [ZIKRouterToViewModule(BSubviewModuleInput) canMakeDestination];
    XCTAssertTrue(canMakeDestination);
    id<BSubviewInput> destination = [ZIKRouterToViewModule(BSubviewModuleInput)
                                     makeDestinationWithStrictConfiguring:^(ZIKPerformRouteStrictConfiguration *config, ZIKPerformRouteConfiguration<BSubviewModuleInput> * _Nonnull module) {
                                         module.title = @"test title";
                                         [module makeDestinationCompletion:^(id<BSubviewInput> destination) {
                                             XCTAssert([destination.title isEqualToString:@"test title"]);
                                         }];
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
                                         };
                                     }];
    XCTAssertNotNil(destination);
    XCTAssertTrue([(id)destination conformsToProtocol:@protocol(BSubviewInput)]);
    
    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
        !error? : NSLog(@"%@", error);
    }];
}

- (void)testStrictMakeDestinationWithErrorHandler {
    XCTestExpectation *errorHandlerExpectation = [self expectationWithDescription:@"errorHandler"];
    XCTestExpectation *performerErrorHandlerExpectation = [self expectationWithDescription:@"performerErrorHandler"];
    XCTestExpectation *completionHandlerExpectation = [self expectationWithDescription:@"completionHandler"];
    TestConfig.routeShouldFail = YES;
    BOOL canMakeDestination = [ZIKRouterToViewModule(BSubviewModuleInput) canMakeDestination];
    XCTAssertTrue(canMakeDestination);
    id<BSubviewInput> destination = [ZIKRouterToViewModule(BSubviewModuleInput)
                                     makeDestinationWithStrictConfiguring:^(ZIKPerformRouteStrictConfiguration *config, ZIKPerformRouteConfiguration<BSubviewModuleInput> * _Nonnull module) {
                                         module.title = @"test title";
                                         [module makeDestinationCompletion:^(id<BSubviewInput> destination) {
                                             XCTAssert([destination.title isEqualToString:@"test title"]);
                                         }];
                                         config.successHandler = ^(id  _Nonnull destination) {
                                             XCTAssert(NO, @"successHandler should not be called");
                                         };
                                         config.performerSuccessHandler = ^(id  _Nonnull destination) {
                                             XCTAssert(NO, @"performerSuccessHandler should not be called");
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
                                         };
                                     }];
    XCTAssertNil(destination);
    
    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
        !error? : NSLog(@"%@", error);
    }];
}

@end
