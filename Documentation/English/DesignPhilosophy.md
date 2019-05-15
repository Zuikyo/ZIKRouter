# Design Idea

## Basic Architecture

![Basic Architecture](../Resources/ArchitecturePreview.png)

## Design Idea

ZIKRouter uses protocol to manage modules. The advantages of interface oriented programming:

* Strict type safety with compile time checking
* Reduce refactoring costs with compile time checking
* Make sure the module implements its protocol
* Declare module's dependencies with protocol
* Avoid using non-existent module with parameter checking when routing
* Separate required protocol and provided protocol to thoroughly decouple

## Why ZIKRouter？

Comparing to other module manager or router frameworks, what's the advantages of ZIKRouter?

### URL Router

ZIKRouter manages modules with protocol, but most of router frameworks use URL matching to get modules.

Sample code:

```objective-c
// Register a URL
[URLRouter registerURL:@"app://editor" handler:^(NSDictionary *userInfo) {
    UIViewController *editorViewController = [[EditorViewController alloc] initWithParam:param];
    return editorViewController;
}];
```

```objective-c
// get instance
[URLRouter openURL:@"app://editor/?debug=true" completion:^(NSDictionary *info) {

}];
```

Advantages of URL router:

* Highly dynamic
* East to manage same route rules in multi platforms
* East to use URL Scheme

Disadvantages of URL router:

* Type of parameters is limited when routing, and there is no compile time checking
* Only for view module, not for any service module
* Can't use designated initializer to provide required parameters
* Need to add new initializer in the view controller to support its url
* Doesn't support storyboard
* Can't declare module's interface, highly rely on documentation. So it's not that safe when refactoring
* Can't make sure whether the module exists or not when you use it
* Hard to manage route strings
* Can't separate required protocol and provided protocol. So you can't thoroughly decouple

#### **Representative Framework**

- [routable-ios](https://github.com/clayallsopp/routable-ios)
- [JLRoutes](https://github.com/joeldev/JLRoutes)
- [MGJRouter](https://github.com/meili/MGJRouter)
- [HHRouter](https://github.com/lightory/HHRouter)

#### Improvement

All disadvantages of URL router can be resolved if we use protocol to manage modules. We can pass parameters with protocols and check type of parameters with the compile. And with routable declaration and compile-time checking, ZIKRouter can make sure the module exists when you use it. And you don't need to modify the module when adding route for it.

ZIKRouter also allows you to get router with string identifier. So it's easy to use ZIKRouter with other URL router frameworks.

### Module Manager with Reflection

Some module manager or dependency injection framework uses runtime and category features in Objective-C to get modules. Such as getting class with `NSClassFromString `, then use `performSelector:` `NSInvocation`to perform methods.

There is a target-action pattern. The general implementation is adding new interfaces with categories in the module manager, and in the category method, use strings to get class with runtime and perform methods.

Sample code:

```objective-c
// The module manager, providing basic method for target-action pattern
@interface Mediator : NSObject

+ (instancetype)sharedInstance;

- (id)performTarget:(NSString *)targetName action:(NSString *)actionName params:(NSDictionary *)params;

@end
```

```objective-c
// The caller adds interface in category
@interface Mediator (ModuleAActions)
- (UIViewController *)Mediator_editorViewController;
@end

@implementation Mediator (ModuleAActions)

- (UIViewController *)Mediator_editorViewController {
    // Create `Target_Editor` with runtime and call `Action_viewController:`
    UIViewController *viewController = [self performTarget:@"Editor" action:@"viewController" params:@{@"key":@"value"}];
    return viewController;
}

@end
  
// The caller get the module by Mediator's interface
UIViewController *editor = [[Mediator sharedInstance] Mediator_editorViewController];
```

```objective-c
// The module provides target-action pattern
@interface Target_Editor : NSObject
- (UIViewController *)Action_viewController:(NSDictionary *)params;
@end

@implementation Target_Editor

- (UIViewController *)Action_viewController:(NSDictionary *)params {
    // Pass parameters with dictionary. It's not type safe
    EditorViewController *viewController = [[EditorViewController alloc] init];
    viewController.valueLabel.text = params[@"key"];
    return viewController;
}

@end
```

Advantages:

* Compile time checking with category methods
* The implementation is lightweight

Disadvantages:

* Still use strings in category
* Can't make sure whether the module exists or not when you use it
* Can't separate required protocol and provided protocol in category methods. So you can't thoroughly decouple
* Rely too much on runtime feature, can't be used in pure Swift
* According to the [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/), it's not recommanded to invoke arbitrary methods with runtime. See [Are performSelector and respondsToSelector banned by App Store?
](https://stackoverflow.com/questions/42662028/are-performselector-and-respondstoselector-banned-by-app-store)

#### Representative Framework

[CTMediator](https://github.com/casatwy/CTMediator)

#### Improvement

ZIKRouter fetch modules with protocol matching instead of runtime discovering with strings. It can be used in Objective-C and Swift. And ZIKRouter can make sure all modules exists.

### Module Manager with Type Matching

Some module manager matchs module with its class or protocol, then create the object with`[[class alloc] init]` or with block.

Sample code of BeeHive:

```objective-c
// Register module (protocol-class pair)
[[BeeHive shareInstance] registerService:@protocol(EditorViewProtocol) service:[EditorViewController class]];
```

```objective-c
// Get module (Create EditorViewController with runtime)
id<EditorServiceProtocol> editor = [[BeeHive shareInstance] createService:@protocol(EditorServiceProtocol)];
```

Sample code of Swinject:

```swift
let container = Container()

// Register module
container.register(EditorViewProtocol.self) { _ in
    EditorViewController()
}
// Get module
let editor = container.resolve(EditorViewProtocol.self)!
```

Advantages:

- Passing parameters with protocol is type safe

Disadvantages:

- It's highly limited when the module manager handles all the instantiation
- Can't get parameters from the caller and use custom initializer
- It doesn't support swift if the module manager create object with OC runtime
- No further complicated dependency injection when there's only protocol-class matching
- Can't ensure the existence of target module of the protocol

#### Representative Framework

[BeeHive](https://github.com/alibaba/BeeHive)

[Swinject](https://github.com/Swinject/Swinject)

#### Improvement

BeeHive is similar to ZIKRouter, but it doesn't support pure Swift type, and it can't apply additional configuration to the module. ZIKRouter doesn't match protocol or class with the module directly, it matchs protocol with its router subclass, and let the router subclass to instantiate the module object.

After adding a router layer, we get a much powerful decoupling tool:

- A moudle can be matched with multi protocols
- The user can adapt other protocols  and add those protocols to the router. This can resovle the build problem when module depends to other modules
-  In the router subclass, we can inject dependencies  and add much more custom actions
- We can use much more methods to create module instance, such as custom designated initializer and factory method. We can directly use the current code when refactoring to moduling code
- Return different type of object for different condition. Such as differnt UI object in different iOS system version

And ZIKRouter makes limitation when passing protocol to fetch module. Only those protocols declared as routable can be used. Then you won't use a non-existent module.

There are two  principles to make dynamic modules exist:

- Only routable protocol can be used for routing, or there will be complier errors
- If a protocol is routable, there must be a router for it

## Architecture

![Architecture](../Resources/Architecture.png)