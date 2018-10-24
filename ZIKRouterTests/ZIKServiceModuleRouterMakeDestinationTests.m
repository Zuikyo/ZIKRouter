//
//  ZIKServiceModuleRouterMakeDestinationTests.m
//  ZIKRouterTests
//
//  Created by zuik on 2018/4/19.
//  Copyright © 2018 zuik. All rights reserved.
//

#import "ZIKRouterTestCase.h"
@import ZIKRouter;
#import "AServiceModuleInput.h"
#import "TestConfig.h"

@interface ZIKServiceModuleRouterMakeDestinationTests : ZIKRouterTestCase

@end

@implementation ZIKServiceModuleRouterMakeDestinationTests

- (void)setUp {
    [super setUp];
    
}

- (void)tearDown {
    [super tearDown];
    
}

- (void)testMakeDestination {
    @autoreleasepool {
        BOOL canMakeDestination = [ZIKRouterToServiceModule(AServiceModuleInput) canMakeDestination];
        XCTAssertTrue(canMakeDestination);
        id<AServiceInput> destination = [ZIKRouterToServiceModule(AServiceModuleInput) makeDestination];
        XCTAssertNotNil(destination);
        XCTAssertTrue([(id)destination conformsToProtocol:@protocol(AServiceInput)]);
        self.destination = destination;
    }
}

- (void)testMakeDestinationWithPreparation {
    @autoreleasepool {
        BOOL canMakeDestination = [ZIKRouterToServiceModule(AServiceModuleInput) canMakeDestination];
        XCTAssertTrue(canMakeDestination);
        id<AServiceInput> destination = [ZIKRouterToServiceModule(AServiceModuleInput) makeDestinationWithPreparation:^(id<AServiceInput>  _Nonnull destination) {
            destination.title = @"test title";
        }];
        XCTAssertNotNil(destination);
        XCTAssertTrue([(id)destination conformsToProtocol:@protocol(AServiceInput)]);
        XCTAssert([destination.title isEqualToString:@"test title"]);
        self.destination = destination;
    }
}

- (void)testMakeDestinationWithPrepareDestination {
    XCTestExpectation *prepareDestinationExpectation = [self expectationWithDescription:@"prepareDestination"];
    XCTestExpectation *successHandlerExpectation = [self expectationWithDescription:@"successHandler"];
    XCTestExpectation *performerSuccessHandlerExpectation = [self expectationWithDescription:@"performerSuccessHandler"];
    XCTestExpectation *completionHandlerExpectation = [self expectationWithDescription:@"completionHandler"];
    BOOL canMakeDestination = [ZIKRouterToServiceModule(AServiceModuleInput) canMakeDestination];
    XCTAssertTrue(canMakeDestination);
    id<AServiceInput> destination = [ZIKRouterToServiceModule(AServiceModuleInput) makeDestinationWithConfiguring:^(ZIKPerformRouteConfiguration<AServiceModuleInput> * _Nonnull config) {
        config.title = @"test title";
        [config makeDestinationCompletion:^(id<AServiceInput> destination) {
            XCTAssert([destination.title isEqualToString:@"test title"]);
        }];
        config.prepareDestination = ^(id<AServiceInput>  _Nonnull destination) {
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
    XCTAssertTrue([(id)destination conformsToProtocol:@protocol(AServiceInput)]);
    XCTAssert([destination.title isEqualToString:@"test title"]);
    
    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
        !error? : NSLog(@"%@", error);
    }];
}

- (void)testMakeDestinationWithSuccessHandler {
    XCTestExpectation *successHandlerExpectation = [self expectationWithDescription:@"successHandler"];
    XCTestExpectation *performerSuccessHandlerExpectation = [self expectationWithDescription:@"performerSuccessHandler"];
    XCTestExpectation *completionHandlerExpectation = [self expectationWithDescription:@"completionHandler"];
    BOOL canMakeDestination = [ZIKRouterToServiceModule(AServiceModuleInput) canMakeDestination];
    XCTAssertTrue(canMakeDestination);
    id<AServiceInput> destination = [ZIKRouterToServiceModule(AServiceModuleInput) makeDestinationWithConfiguring:^(ZIKPerformRouteConfiguration<AServiceModuleInput> * _Nonnull config) {
        config.title = @"test title";
        [config makeDestinationCompletion:^(id<AServiceInput> destination) {
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
    XCTAssertTrue([(id)destination conformsToProtocol:@protocol(AServiceInput)]);
    
    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
        !error? : NSLog(@"%@", error);
    }];
}

- (void)testMakeDestinationWithErrorHandler {
    XCTestExpectation *errorHandlerExpectation = [self expectationWithDescription:@"errorHandler"];
    XCTestExpectation *performerErrorHandlerExpectation = [self expectationWithDescription:@"performerErrorHandler"];
    XCTestExpectation *completionHandlerExpectation = [self expectationWithDescription:@"completionHandler"];
    TestConfig.routeShouldFail = YES;
    BOOL canMakeDestination = [ZIKRouterToServiceModule(AServiceModuleInput) canMakeDestination];
    XCTAssertTrue(canMakeDestination);
    id<AServiceInput> destination = [ZIKRouterToServiceModule(AServiceModuleInput) makeDestinationWithConfiguring:^(ZIKPerformRouteConfiguration<AServiceModuleInput> * _Nonnull config) {
        config.title = @"test title";
        [config makeDestinationCompletion:^(id<AServiceInput> destination) {
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
    BOOL canMakeDestination = [ZIKRouterToServiceModule(AServiceModuleInput) canMakeDestination];
    XCTAssertTrue(canMakeDestination);
    id<AServiceInput> destination = [ZIKRouterToServiceModule(AServiceModuleInput)
                                     makeDestinationWithStrictConfiguring:^(ZIKPerformRouteStrictConfiguration *config, ZIKPerformRouteConfiguration<AServiceModuleInput> * _Nonnull module) {
                                         module.title = @"test title";
                                         [module makeDestinationCompletion:^(id<AServiceInput> destination) {
                                             XCTAssert([destination.title isEqualToString:@"test title"]);
                                         }];
                                         config.successHandler = ^(id<AServiceInput> destination) {
                                             [successHandlerExpectation fulfill];
                                         };
                                         config.performerSuccessHandler = ^(id<AServiceInput> destination) {
                                             [performerSuccessHandlerExpectation fulfill];
                                         };
                                         config.errorHandler = ^(ZIKRouteAction  _Nonnull routeAction, NSError * _Nonnull error) {
                                             XCTAssert(NO, @"errorHandler should not be called");
                                         };
                                         config.performerErrorHandler = ^(ZIKRouteAction  _Nonnull routeAction, NSError * _Nonnull error) {
                                             XCTAssert(NO, @"performerErrorHandler should not be called");
                                         };
                                         config.completionHandler = ^(BOOL success, id<AServiceInput> _Nullable destination, ZIKRouteAction  _Nonnull routeAction, NSError * _Nullable error) {
                                             XCTAssertTrue(success);
                                             [completionHandlerExpectation fulfill];
                                         };
                                     }];
    XCTAssertNotNil(destination);
    XCTAssertTrue([(id)destination conformsToProtocol:@protocol(AServiceInput)]);
    XCTAssert([destination.title isEqualToString:@"test title"]);
    
    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
        !error? : NSLog(@"%@", error);
    }];
}

- (void)testStrictMakeDestinationWithSuccessHandler {
    XCTestExpectation *successHandlerExpectation = [self expectationWithDescription:@"successHandler"];
    XCTestExpectation *performerSuccessHandlerExpectation = [self expectationWithDescription:@"performerSuccessHandler"];
    XCTestExpectation *completionHandlerExpectation = [self expectationWithDescription:@"completionHandler"];
    BOOL canMakeDestination = [ZIKRouterToServiceModule(AServiceModuleInput) canMakeDestination];
    XCTAssertTrue(canMakeDestination);
    id<AServiceInput> destination = [ZIKRouterToServiceModule(AServiceModuleInput)
                                     makeDestinationWithStrictConfiguring:^(ZIKPerformRouteStrictConfiguration *config, ZIKPerformRouteConfiguration<AServiceModuleInput> * _Nonnull module) {
                                         module.title = @"test title";
                                         [module makeDestinationCompletion:^(id<AServiceInput> destination) {
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
    XCTAssertTrue([(id)destination conformsToProtocol:@protocol(AServiceInput)]);
    
    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
        !error? : NSLog(@"%@", error);
    }];
}

- (void)testStrictMakeDestinationWithErrorHandler {
    XCTestExpectation *errorHandlerExpectation = [self expectationWithDescription:@"errorHandler"];
    XCTestExpectation *performerErrorHandlerExpectation = [self expectationWithDescription:@"performerErrorHandler"];
    XCTestExpectation *completionHandlerExpectation = [self expectationWithDescription:@"completionHandler"];
    TestConfig.routeShouldFail = YES;
    BOOL canMakeDestination = [ZIKRouterToServiceModule(AServiceModuleInput) canMakeDestination];
    XCTAssertTrue(canMakeDestination);
    id<AServiceInput> destination = [ZIKRouterToServiceModule(AServiceModuleInput)
                                     makeDestinationWithStrictConfiguring:^(ZIKPerformRouteStrictConfiguration *config, ZIKPerformRouteConfiguration<AServiceModuleInput> * _Nonnull module) {
                                         module.title = @"test title";
                                         [module makeDestinationCompletion:^(id<AServiceInput> destination) {
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
