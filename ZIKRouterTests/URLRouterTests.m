//
//  URLRouterTests.m
//  ZIKRouterTests
//
//  Created by zuik on 2019/4/22.
//  Copyright © 2019 zuik. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "ZIKURLRouter.h"
@import ZIKRouter;

@interface URLRouterTests : XCTestCase
    @property (nonatomic, strong) ZIKURLRouter *router;
@end

@implementation URLRouterTests

- (void)setUp {
    self.router = [ZIKURLRouter new];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testURLWithHost {
    [_router registerURLPattern:@"app://host"];
    ZIKURLRouteResult *result = [_router resultForURL:@"app://host"];
    XCTAssert([result.identifier isEqualToString:@"app://host"]);
    XCTAssert([result.url.absoluteString isEqualToString:@"app://host"]);
}

- (void)testURLWithHostAndQuery {
    ZIKURLRouteResult *result;
    
    [_router registerURLPattern:@"app://host"];
    result = [_router resultForURL:@"app://host/?k=1"];
    XCTAssert([result.identifier isEqualToString:@"app://host"]);
    XCTAssert([result.url.absoluteString isEqualToString:@"app://host/?k=1"]);
    XCTAssert([result.parameters[@"k"] isEqualToString:@"1"]);
    
    result = [_router resultForURL:@"app://host/?k1=a&k2=b"];
    XCTAssert([result.identifier isEqualToString:@"app://host"]);
    XCTAssert([result.url.absoluteString isEqualToString:@"app://host/?k1=a&k2=b"]);
    XCTAssert([result.parameters[@"k1"] isEqualToString:@"a"]);
    XCTAssert([result.parameters[@"k2"] isEqualToString:@"b"]);
    
    result = [_router resultForURL:@"app://host/?k1=a&k2=二&k3=3"];
    XCTAssert([result.identifier isEqualToString:@"app://host"]);
    XCTAssert([result.url.absoluteString isEqualToString:[@"app://host/?k1=a&k2=二&k3=3" stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]);
    XCTAssert([result.parameters[@"k1"] isEqualToString:@"a"]);
    XCTAssert([result.parameters[@"k2"] isEqualToString:@"二"]);
    XCTAssert([result.parameters[@"k3"] isEqualToString:@"3"]);
}
    
- (void)testURLWithPath {
    ZIKURLRouteResult *result;
    
    [_router registerURLPattern:@"app://host/path"];
    result = [_router resultForURL:@"app://host/path"];
    XCTAssert([result.identifier isEqualToString:@"app://host/path"]);
    XCTAssert([result.url.absoluteString isEqualToString:@"app://host/path"]);
    
    [_router registerURLPattern:@"app://host/p1/p2"];
    result = [_router resultForURL:@"app://host/p1/p2"];
    XCTAssert([result.identifier isEqualToString:@"app://host/p1/p2"]);
    XCTAssert([result.url.absoluteString isEqualToString:@"app://host/p1/p2"]);
    
    [_router registerURLPattern:@"app://host/p1/p2/p3"];
    result = [_router resultForURL:@"app://host/p1/p2/p3"];
    XCTAssert([result.identifier isEqualToString:@"app://host/p1/p2/p3"]);
    XCTAssert([result.url.absoluteString isEqualToString:@"app://host/p1/p2/p3"]);
}
    
- (void)testURLWithPathAndQuery {
    ZIKURLRouteResult *result;
    
    [_router registerURLPattern:@"app://host/path"];
    result = [_router resultForURL:@"app://host/path/?k=1"];
    XCTAssert([result.identifier isEqualToString:@"app://host/path"]);
    XCTAssert([result.url.absoluteString isEqualToString:@"app://host/path/?k=1"]);
    XCTAssert([result.parameters[@"k"] isEqualToString:@"1"]);
    
    result = [_router resultForURL:@"app://host/path/?k1=a&k2=b"];
    XCTAssert([result.identifier isEqualToString:@"app://host/path"]);
    XCTAssert([result.url.absoluteString isEqualToString:@"app://host/path/?k1=a&k2=b"]);
    XCTAssert([result.parameters[@"k1"] isEqualToString:@"a"]);
    XCTAssert([result.parameters[@"k2"] isEqualToString:@"b"]);
    
    result = [_router resultForURL:@"app://host/path/?k1=a&k2=二&k3=3"];
    XCTAssert([result.identifier isEqualToString:@"app://host/path"]);
    XCTAssert([result.url.absoluteString isEqualToString:[@"app://host/path/?k1=a&k2=二&k3=3" stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]);
    XCTAssert([result.parameters[@"k1"] isEqualToString:@"a"]);
    XCTAssert([result.parameters[@"k2"] isEqualToString:@"二"]);
    XCTAssert([result.parameters[@"k3"] isEqualToString:@"3"]);
}
    
- (void)testURLWithPlaceholderPath {
    ZIKURLRouteResult *result;
    
    [_router registerURLPattern:@"app://host/:key"];
    result = [_router resultForURL:@"app://host/value"];
    XCTAssert([result.identifier isEqualToString:@"app://host/:key"]);
    XCTAssert([result.url.absoluteString isEqualToString:@"app://host/value"]);
    XCTAssertEqualObjects(result.parameters[@"key"], @"value");
    
    [_router registerURLPattern:@"app://host/path/:key"];
    result = [_router resultForURL:@"app://host/path/value"];
    XCTAssert([result.identifier isEqualToString:@"app://host/path/:key"]);
    XCTAssert([result.url.absoluteString isEqualToString:@"app://host/path/value"]);
    XCTAssertEqualObjects(result.parameters[@"key"], @"value");
    
    [_router registerURLPattern:@"app://host/:key1/:key2"];
    result = [_router resultForURL:@"app://host/value1/value2"];
    XCTAssert([result.identifier isEqualToString:@"app://host/:key1/:key2"]);
    XCTAssert([result.url.absoluteString isEqualToString:@"app://host/value1/value2"]);
    XCTAssertEqualObjects(result.parameters[@"key1"], @"value1");
    XCTAssertEqualObjects(result.parameters[@"key2"], @"value2");
    
    [_router registerURLPattern:@"app://host/p1/p2/:key1/:key2"];
    result = [_router resultForURL:@"app://host/p1/p2/value1/value2"];
    XCTAssert([result.identifier isEqualToString:@"app://host/p1/p2/:key1/:key2"]);
    XCTAssert([result.url.absoluteString isEqualToString:@"app://host/p1/p2/value1/value2"]);
    XCTAssertEqualObjects(result.parameters[@"key1"], @"value1");
    XCTAssertEqualObjects(result.parameters[@"key2"], @"value2");
    
    [_router registerURLPattern:@"app://host/:key1/:key2/:key3"];
    result = [_router resultForURL:@"app://host/value1/value2/value3"];
    XCTAssert([result.identifier isEqualToString:@"app://host/:key1/:key2/:key3"]);
    XCTAssert([result.url.absoluteString isEqualToString:@"app://host/value1/value2/value3"]);
    XCTAssertEqualObjects(result.parameters[@"key1"], @"value1");
    XCTAssertEqualObjects(result.parameters[@"key2"], @"value2");
    XCTAssertEqualObjects(result.parameters[@"key3"], @"value3");
}

- (void)testURLWithPlaceholderPathAndQuery {
    ZIKURLRouteResult *result;
    
    [_router registerURLPattern:@"app://host/:key"];
    result = [_router resultForURL:@"app://host/value/?k=1"];
    XCTAssert([result.identifier isEqualToString:@"app://host/:key"]);
    XCTAssert([result.url.absoluteString isEqualToString:@"app://host/value/?k=1"]);
    XCTAssertEqualObjects(result.parameters[@"key"], @"value");
    XCTAssertEqualObjects(result.parameters[@"k"], @"1");
    
    [_router registerURLPattern:@"app://host/:key1/:key2"];
    result = [_router resultForURL:@"app://host/value1/value2/?k1=a&k2=b"];
    XCTAssert([result.identifier isEqualToString:@"app://host/:key1/:key2"]);
    XCTAssert([result.url.absoluteString isEqualToString:@"app://host/value1/value2/?k1=a&k2=b"]);
    XCTAssertEqualObjects(result.parameters[@"key1"], @"value1");
    XCTAssertEqualObjects(result.parameters[@"key2"], @"value2");
    XCTAssertEqualObjects(result.parameters[@"k1"], @"a");
    XCTAssertEqualObjects(result.parameters[@"k2"], @"b");
    
    [_router registerURLPattern:@"app://host/:key1/:key2/:key3"];
    result = [_router resultForURL:@"app://host/value1/value2/value3/?k1=a&k2=二&k3=3"];
    XCTAssert([result.identifier isEqualToString:@"app://host/:key1/:key2/:key3"]);
    XCTAssert([result.url.absoluteString isEqualToString:[@"app://host/value1/value2/value3/?k1=a&k2=二&k3=3" stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]);
    XCTAssertEqualObjects(result.parameters[@"key1"], @"value1");
    XCTAssertEqualObjects(result.parameters[@"key2"], @"value2");
    XCTAssertEqualObjects(result.parameters[@"key3"], @"value3");
    XCTAssertEqualObjects(result.parameters[@"k1"], @"a");
    XCTAssertEqualObjects(result.parameters[@"k2"], @"二");
    XCTAssertEqualObjects(result.parameters[@"k3"], @"3");
}

- (void)testURLWithDiscontinuousPlaceholderPath {
    ZIKURLRouteResult *result;
    
    [_router registerURLPattern:@"app://host/:key1/path/:key2"];
    result = [_router resultForURL:@"app://host/value1/path/value2"];
    XCTAssert([result.identifier isEqualToString:@"app://host/:key1/path/:key2"]);
    XCTAssert([result.url.absoluteString isEqualToString:@"app://host/value1/path/value2"]);
    XCTAssertEqualObjects(result.parameters[@"key1"], @"value1");
    XCTAssertEqualObjects(result.parameters[@"key2"], @"value2");
    
    [_router registerURLPattern:@"app://host/:key1/path/:key2/path2"];
    result = [_router resultForURL:@"app://host/value1/path/value2/path2"];
    XCTAssert([result.identifier isEqualToString:@"app://host/:key1/path/:key2/path2"]);
    XCTAssert([result.url.absoluteString isEqualToString:@"app://host/value1/path/value2/path2"]);
    XCTAssertEqualObjects(result.parameters[@"key1"], @"value1");
    XCTAssertEqualObjects(result.parameters[@"key2"], @"value2");
    
    [_router registerURLPattern:@"app://host/:key1/path/path2/path3"];
    result = [_router resultForURL:@"app://host/value1/path/path2/path3"];
    XCTAssert([result.identifier isEqualToString:@"app://host/:key1/path/path2/path3"]);
    XCTAssert([result.url.absoluteString isEqualToString:@"app://host/value1/path/path2/path3"]);
    XCTAssertEqualObjects(result.parameters[@"key1"], @"value1");
}
    
- (void)testURLWithoutScheme {
    [_router registerURLPattern:@"://host/path"];
    ZIKURLRouteResult *result = [_router resultForURL:@"://host/path"];
    XCTAssert([result.identifier isEqualToString:@"://host/path"]);
    XCTAssertEqualObjects(result.url.absoluteString, @"://host/path");
}

@end
