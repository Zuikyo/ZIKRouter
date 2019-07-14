# Unit Test

With required protocol and provided protocol,  it's much easier to mock dependencies in unit test.

Let's see a login module depending to a net service:

```swift
// Login module
class LoginService {

    func login(account: String, password: String, completion: (Result<LoginError>) -> Void) {
        // Use RequiredNetServiceInput to request the network
        let netService = Router.makeDestination(to: RoutableService<RequiredNetServiceInput
        >())
        let request = makeLoginRequest(account: account, password: password)
        netService?.POST(request: request, completion: completion)
    }
}

// Dependencies
extension RoutableService where Protocol == RequiredNetServiceInput {
    init() {}
}
```

<details><summary>Objective-C Sample</summary>

```objectivec
Use RequiredNetServiceInput to request the network// Login module
@interface LoginService : NSObject
@end
@implementation LoginService

- (void)loginWithAccount:(NSString *)account password:(NSString *)password  completion:(void(^)(Result *result))completion {
    // Use RequiredNetServiceInput to request the network
    id<RequiredNetServiceInput> netService = [ZIKRouterToService(RequiredNetServiceInput) makeDestination];
    Request *request = makeLoginRequest(account, password);
    [netService POSTRequest:request completion: completion];
}

@end
  
// Dependencies
@protocol RequiredNetServiceInput <ZIKServiceRoutable>
- (void)POSTRequest:(Request *)request completion:(void(^)(Result *result))completion;
@end
```

</details>

You don't need to import a real network module in unit test. Just write a fake network module:

```swift
class MockNetService: RequiredNetServiceInput {
    func POST(request: Request, completion: (Result<NetError>) {
        completion(.success)
    }
}
```

```swift
// Register the fake module
ZIKAnyServiceRouter.register(RoutableService<RequiredNetServiceInput>(), 
                 forMakingService: MockNetService.self) { (config, router) -> EditorViewProtocol? in
                     return MockNetService()
        }
```

<details><summary>Objective-C Sample</summary>

```objectivec
@interface MockNetService : NSObject <RequiredNetServiceInput>
@end
@implementation MockNetService

- (void)POSTRequest:(Request *)request completion:(void(^)(Result *result))completion {
    completion([Result success]);
}
  
@end
```

```objectivec
// Register the fake module
[ZIKServiceRouter registerServiceProtocol:ZIKRoutable(EditorViewInput) forMakingService:[MockNetService class]];
```

</details>

Unit test code:

```swift
class LoginServiceTests: XCTestCase {
    
    func testLoginSuccess() {
        let expectation = expectation(description: "end login")
        
        let loginService = LoginService()
        loginService.login(account: "account", password: "pwd") { result in
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5, handler: { if let error = $0 {print(error)}})
    }
    
}
```

<details><summary>Objective-C Sample</summary>

```objectivec
@interface LoginServiceTests : XCTestCase
@end
@implementation LoginServiceTests

- (void)testLoginSuccess {
    XCTestExpectation *expectation = [self expectationWithDescription:@"end login"];
    
    [[LoginService new] loginWithAccount:@"" password:@"" completion:^(Result *result) {
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
        !error? : NSLog(@"%@", error);
    }];
}
@end
```

</details>

