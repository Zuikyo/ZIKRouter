<p align="center">
  <img src="Documentation/Resources/icon.png" width="33%">
</p>

# ZIKRouter

![](https://img.shields.io/cocoapods/p/ZIKRouter.svg?style=flat)
![](https://img.shields.io/badge/language-objectivec-blue.svg)
![](https://img.shields.io/badge/language-swift-orange.svg)
![ZIKRouter](https://img.shields.io/cocoapods/v/ZIKRouter.svg?style=flat)
![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)
![license](https://img.shields.io/github/license/mashape/apistatus.svg)

An interface-oriented router for discovering modules and injecting dependencies with protocol.

The view router can perform all navigation types in UIKit / AppKit through one method.

The service router can discover and prepare corresponding module with its protocol.

---

一个用于模块间解耦和通信，基于接口进行模块管理和依赖注入的组件化路由工具。

通过 protocol 寻找对应的模块，并用 protocol 进行依赖注入和模块通信。

View router 将 UIKit / AppKit 中的所有界面跳转方式封装成一个统一的方法。Service router 用于支持任意自定义模块。

### [中文文档](Documentation/Chinese/README.md)

---

## Features

- [x] Support Swift and Objective-C
- [x] Support iOS, macOS and tvOS
- [x] Routing for UIViewController / NSViewController, UIView / NSView and any OC class and swift class
- [x] Dependency injection, including dynamic injection and static injection
- [x] **Declare routable protocol for compile-time checking. Using undeclared protocol will bring compile error. This is one of the most powerful feature**
- [x] **Locate module with its protocol**
- [x] **Locate module with identifier, compatible with other URL router frameworks**
- [x] **Prepare the module with its protocol when performing route, rather than passing a parameter dictionary**
- [x] **Use different required protocol and provided protocol inside module and module's user to make thorough decouple**
- [x] **Decouple modules and add compatible interfaces with adapter**
- [x] **Support storyboard. UIViewController / NSViewController and UIView / NSView from a segue can auto create it's registered router**
- [x] Encapsulate navigation methods in UIKit and AppKit (push, present modally, present as popover present as sheet, segue, show, showDetail, addChildViewController, addSubview) and custom transitions into one method
- [x] Remove an UIViewController/UIView or unload a module through one method, without using pop、dismiss、removeFromParentViewController、removeFromSuperview in different situations. Router can choose the proper method
- [x] Error checking for view transition
- [x] AOP for view transition
- [x] Detect memory leaks
- [x] Send custom events to router
- [x] Auto register all routers

## Documentation

### Design Idea

[Design Idea](Documentation/English/DesignPhilosophy.md)

### Basics

1. [Router Implementation](Documentation/English/RouterImplementation.md)
2. [Module Registration](Documentation/English/ModuleRegistration.md)
3. [Routable Declaration](Documentation/English/RoutableDeclaration.md)
4. [Type Checking](Documentation/English/TypeChecking.md)
5. [Perform Route](Documentation/English/PerformRoute.md)
6. [Remove Route](Documentation/English/RemoveRoute.md)
7. [Transfer Parameters with Custom Configuration](Documentation/English/CustomConfiguration.md)

### Advanced Features

1. [Error Handle](Documentation/English/ErrorHandle.md)
2. [Storyboard and Auto Create](Documentation/English/Storyboard.md)
3. [AOP](Documentation/English/AOP.md)
4. [Dependency Injection](Documentation/English/DependencyInjection.md)
5. [Circular Dependency](Documentation/English/CircularDependencies.md)
6. [Module Adapter](Documentation/English/ModuleAdapter.md)

[FAQ](Documentation/English/FAQ.md)



## Quick Start Guide

1. [Create Router](#1-Create-Router)
   1. [Router Subclass](#11-Router-Subclass)
   2. [Simple Router](#12-Simple-Router)
2. [Declare Routable Type](#2-Declare-Routable-Type)
3. [View Router](#View-Router)
   1. [Transition directly](#Transition-directly)
   2. [Prepare before Transition](#Prepare-before-Transition)
   3. [Make Destination](#Make-Destination)
   4. [Transfer Parameters in a Powerful Pattern](#Transfer-Parameters-in-a-Powerful-Pattern)
   5. [Remove](#Remove)
   6. [Adapter](#Adapter)
   7. [URL Router](#URL-Router)
4. [Service Router](#Service-Router)
5. [Demo and Practice](#Demo-and-Practice)
6. [File Template](#File-Template)

## Requirements

* iOS 7.0+
* Swift 3.2+
* Xcode 9.0+

## Installation

### Cocoapods

Add this to your Podfile.

For Objective-C project:

```
pod 'ZIKRouter', '>= 1.0.10'

# or only use ServiceRouter
pod 'ZIKRouter/ServiceRouter' , '>=1.0.10'
```
For Swift project:

```
pod 'ZRouter', '>= 1.0.10'

# or only use ServiceRouter
pod 'ZRouter/ServiceRouter' , '>=1.0.10'
```

### Carthage

Add this to your Cartfile:

```
github "Zuikyo/ZIKRouter" >= 1.0.10
```

Build frameworks:

```
carthage update
```

Build DEBUG version to enable route checking:

```
carthage update --configuration Debug
```
Remember to use release version in production environment.

For Objective-C project, use `ZIKRouter.framework`. For Swift project, use `ZRouter.framework`.

## Getting Started

This is the demo view controller and protocol：

```swift
///Editor view's interface
protocol EditorViewInput: class {
    weak var delegate: EditorDelegate? { get set }
    func constructForCreatingNewNote()
}

///Editor view controller
class NoteEditorViewController: UIViewController, EditorViewInput {
    ...
}
```

<details><summary>Objective-C Sample</summary>

```objectivec
///editor view's interface
@protocol EditorViewInput <ZIKViewRoutable>
@property (nonatomic, weak) id<EditorDelegate> delegate;
- (void)constructForCreatingNewNote;
@end
```

```objectivec
///Editor view controller
@interface NoteEditorViewController: UIViewController <EditorViewInput>
@end
@implementation NoteEditorViewController
@end
```

</details>


There're 2 steps to create route for your module.

### 1. Create Router

To make your class become modular, you need to create router for your module. You don't need to modify the module's code. That will reduce the cost for refactoring existing modules.

#### 1.1 Router Subclass

Create router subclass for your module:

```swift
import ZIKRouter.Internal
import ZRouter

class NoteEditorViewRouter: ZIKViewRouter<NoteEditorViewController, ViewRouteConfig> {
    override class func registerRoutableDestination() {
        // Register class with this router. A router can register multi views, and a view can be registered with multi routers
        registerView(NoteEditorViewController.self)
        // Register protocol. Then we can fetch this router with the protocol
        register(RoutableView<EditorViewInput>())
    }
    
    // Return the destination module
    override func destination(with configuration: ViewRouteConfig) -> NoteEditorViewController? {
        // In configuration, you can get parameters from the caller for creating the instance
        let destination: NoteEditorViewController? = ... /// instantiate your view controller
        return destination
    }
    
    override func prepareDestination(_ destination: NoteEditorViewController, configuration: ViewRouteConfig) {
        // Inject dependencies to destination
    }
}
```

<details><summary>Objective-C Sample</summary>

```objectivec
//NoteEditorViewRouter.h
@import ZIKRouter;

@interface NoteEditorViewRouter : ZIKViewRouter
@end

//NoteEditorViewRouter.m
@import ZIKRouter.Internal;

@implementation NoteEditorViewRouter

+ (void)registerRoutableDestination {
    // Register class with this router. A router can register multi views, and a view can be registered with multi routers
    [self registerView:[NoteEditorViewController class]];
    // Register protocol. Then we can fetch this router with the protocol
    [self registerViewProtocol:ZIKRoutable(EditorViewInput)];
}

// Return the destination module
- (NoteEditorViewController *)destinationWithConfiguration:(ZIKViewRouteConfiguration *)configuration {
	// In configuration, you can get parameters from the caller for creating the instance 
    NoteEditorViewController *destination = ... // instantiate your view controller
    return destination;
}

- (void)prepareDestination:(NoteEditorViewController *)destination configuration:(ZIKViewRouteConfiguration *)configuration {
    // Inject dependencies to destination
}

@end
```

</details>

Read the documentation for more details and more methods to override.

#### 1.2 Simple Router

If your module is very simple and don't need a router subclass, you can just register the class in a simpler way:

```swift
ZIKAnyViewRouter.register(RoutableView<EditorViewInput>(), forMakingView: NoteEditorViewController.self)
```

<details><summary>Objective-C Sample</summary>

```objectivec
[ZIKViewRouter registerViewProtocol:ZIKRoutable(EditorViewInput) forMakingView:[NoteEditorViewController class]];
```

</details>

or with custom creating block:

```swift
ZIKAnyViewRouter.register(RoutableView<EditorViewInput>(), 
                 forMakingView: NoteEditorViewController.self) { (config, router) -> EditorViewInput? in
                     let destination: NoteEditorViewController? = ... // instantiate your view controller
                     return destination;
        }

```

<details><summary>Objective-C Sample</summary>

```objectivec
[ZIKViewRouter
    registerViewProtocol:ZIKRoutable(EditorViewInput)
    forMakingView:[NoteEditorViewController class]
    making:^id _Nullable(ZIKViewRouteConfiguration *config, ZIKViewRouter *router) {
        NoteEditorViewController *destination = ... // instantiate your view controller
        return destination;
 }];
```

</details>

or with custom factory function:

```swift
function makeEditorViewController(config: ViewRouteConfig) -> EditorViewInput? {
    let destination: NoteEditorViewController? = ... // instantiate your view controller
    return destination;
}

ZIKAnyViewRouter.register(RoutableView<EditorViewInput>(), 
                 forMakingView: NoteEditorViewController.self, making: makeEditorViewController)
```

<details><summary>Objective-C Sample</summary>

```objectivec
id<EditorViewInput> makeEditorViewController(ZIKViewRouteConfiguration *config) {
    NoteEditorViewController *destination = ... // instantiate your view controller
    return destination;
}

[ZIKViewRouter
    registerViewProtocol:ZIKRoutable(EditorViewInput)
    forMakingView:[NoteEditorViewController class]
    factory:makeEditorViewController];
```

</details>

### 2. Declare Routable Type

The declaration is for checking routes at compile time, and supporting storyboard.

```swift
// Declare NoteEditorViewController is routable
// This means there is a router for NoteEditorViewController
extension NoteEditorViewController: ZIKRoutableView {
}

// Declare EditorViewInput is routable
// This means you can use EditorViewInput to fetch router
extension RoutableView where Protocol == EditorViewInput {
    init() { self.init(declaredProtocol: Protocol.self) }
}
```

<details><summary>Objective-C Sample</summary>

```objectivec
// Declare NoteEditorViewController is routable
// This means there is a router for NoteEditorViewController
DeclareRoutableView(NoteEditorViewController, NoteEditorViewRouter)

// If the protocol inherits from ZIKViewRoutable, it's routable
// This means you can use EditorViewInput to fetch router
// If you use an undeclared protocol, there will be compile time warning
@protocol EditorViewInput <ZIKViewRoutable>
@property (nonatomic, weak) id<EditorDelegate> delegate;
- (void)constructForCreatingNewNote;
@end
```

</details>

**If you use an undeclared protocol for routing, there will be compile time error. So it's much easier to manage protocols and to know which protocols are routable.**

Unroutable error in Swift:

![Unroutable-error-Swift](Documentation/Resources/Unroutable-error-Swift.png)

Unroutable error in Objective-C:

![Unroutable-error-OC](Documentation/Resources/Unroutable-error-OC.png)

Now you can get and show `NoteEditorViewController` with router.

### View Router

#### Transition directly

Transition to editor view directly:

```swift
class TestViewController: UIViewController {

    // Transition to editor view directly
    func showEditorDirectly() {
        Router.perform(to: RoutableView<EditorViewInput>(), path: .push(from: self))
    }
}
```

<details><summary>Objective-C Sample</summary>

```objectivec
@implementation TestViewController

- (void)showEditorDirectly {
    // Transition to editor view directly
    [ZIKRouterToView(EditorViewInput) performPath:ZIKViewRoutePath.pushFrom(self)];
}

@end
```

</details>

You can change transition type with `ViewRoutePath`:

```swift
enum ViewRoutePath {
    case push(from: UIViewController)
    case presentModally(from: UIViewController)
    case presentAsPopover(from: UIViewController, configure: ZIKViewRoutePopoverConfigure)
    case performSegue(from: UIViewController, identifier: String, sender: Any?)
    case show(from: UIViewController)
    case showDetail(from: UIViewController)
    case addAsChildViewController(from: UIViewController, addingChildViewHandler: (UIViewController, @escaping () -> Void) -> Void)
    case addAsSubview(from: UIView)
    case custom(from: ZIKViewRouteSource?)
    case makeDestination
    case extensible(path: ZIKViewRoutePath)
}
```

#### Prepare before Transition

Prepare it before transition to editor view:

```swift
class TestViewController: UIViewController {

    // Transition to editor view, and prepare the destination with EditorViewInput
    func showEditor() {
        Router.perform(
            to: RoutableView<EditorViewInput>(),
            path: .push(from: self),
            configuring: { (config, _) in
                // Route config
                // Prepare the destination before transition
                config.prepareDestination = { [weak self] destination in
                    //destination is inferred as EditorViewInput
                    destination.delegate = self
                    destination.constructForCreatingNewNote()
                }
                config.successHandler = { destination in
                    // Transition succeed
                }
                config.errorHandler = { (action, error) in
                    // Transition failed
                }                
        })
    }
}
```

<details><summary>Objective-C Sample</summary>

```objectivec
@implementation TestViewController

- (void)showEditor {
    // Transition to editor view, and prepare the destination with EditorViewInput
    [ZIKRouterToView(EditorViewInput)
	     performPath:ZIKViewRoutePath.pushFrom(self)
	     configuring:^(ZIKViewRouteConfig *config) {
	         // Route config
	         // Prepare the destination before transition
	         config.prepareDestination = ^(id<EditorViewInput> destination) {
	             destination.delegate = self;
	             [destination constructForCreatingNewNote];
	         };
	         config.successHandler = ^(id<EditorViewInput> destination) {
	             // Transition is completed
	         };
	         config.errorHandler = ^(ZIKRouteAction routeAction, NSError * error) {
	             // Transition failed
	         };
	     }];
}

@end
```

</details>

For more detail, read [Perform Route](Documentation/English/PerformRoute.md).

#### Make Destination

If you don't wan't to show a view, but only need to get instance of the module, you can use `makeDestination`:

```swift
// destination is inferred as EditorViewInput
let destination = Router.makeDestination(to: RoutableView<EditorViewInput>())
```

<details><summary>Objective-C Sample</summary>

```objectivec
id<EditorViewInput> destination = [ZIKRouterToView(EditorViewInput) makeDestination];
```
</details>

#### Transfer Parameters in a Powerful Pattern

Sometimes the destination class uses custom initializers to create instance, router needs to get required parameter from the caller. 

Sometimes your module contains multi components, and you need to pass parameters to those components. And those parameters do not belong to the destination. 

You can use module config protocol and a custom configuration to transfer parameters.

Instead of  `EditorViewInput`, we use another routable protocol `EditorViewModuleInput`  as config protocol for routing:

```swift
// In general, a module config protocol only contains `makeDestinationWith`, for declaring parameters and destination type. You can also add other properties or methods
protocol EditorViewModuleInput: class {
    // Transfer parameters and make destination
    var makeDestinationWith: (_ note: Note) -> EditorViewInput? { get }
}
```

<details><summary>Objective-C Sample</summary>

```objectivec
// In general, a module config protocol only contains `makeDestinationWith`, for declaring parameters and destination type. You can also add other properties or methods
@protocol EditorViewModuleInput <ZIKViewModuleRoutable>
 // Transfer parameters and make destination
@property (nonatomic, copy, readonly) id<EditorViewInput> _Nullable(^makeDestinationWith)(Note *note);
@end
```

</details>

You can use a configuration subclass and store parameters on its properties.

<details><summary>configuration subclass</summary>

```swift
// Configuration subclass conforming to EditorViewModuleInput
// Swift generic class is not OC Class. It won't be in the `__objc_classlist` section of the Mach-O file. So it won't affect the app launching time.
class EditorViewModuleConfiguration<T>: ZIKViewMakeableConfiguration<NoteEditorViewController>, EditorViewModuleInput {
    // User is responsible for calling makeDestinationWith and giving parameters
    var makeDestinationWith: (_ note: Note) -> EditorViewInput? {
        return { note in
            // Capture parameters in makeDestination, so we don't need configuration subclass to hold the parameters
            // MakeDestination will be used for creating destination instance
            self.makeDestination = { [unowned self] () in
                // Use custom initializer
                let destination = NoteEditorViewController(note: note)
                return destination
            }
            if let destination = self.makeDestination?() {
                // Set makedDestination so router will use this destination when performing
                self.makedDestination = destination
                return destination
            }
            return nil
        }
    }
}

func makeEditorViewModuleConfiguration() -> ZIKViewMakeableConfiguration<NoteEditorViewController> & EditorViewModuleInput {
	return EditorViewModuleConfiguration<Any>()
}
```

</details>

If the protocol is very simple and you don't need a configuration subclass,or you're using Objective-C and don't want too many subclass, you can choose generic class`ViewMakeableConfiguration`and`ZIKViewMakeableConfiguration`:

```swift
extension ViewMakeableConfiguration: EditorViewModuleInput where Destination == EditorViewInput, Constructor == (Note) -> EditorViewInput? {
}

// ViewMakeableConfiguration with generic arguments works as the same as  EditorViewModuleConfiguration
// The config works like EditorViewModuleConfiguration<Any>()
func makeEditorViewModuleConfiguration() -> ViewMakeableConfiguration<EditorViewInput, (Note) -> EditorViewInput?> {
	let config = ViewMakeableConfiguration<EditorViewInput, (Note) -> EditorViewInput?>({ _ in})
	
	// User is responsible for calling makeDestinationWith and giving parameters
	config.makeDestinationWith = { [unowned config] note in
        // Capture parameters in makeDestination, so we don't need configuration subclass to hold the parameters
        // MakeDestination will be used for creating destination instance
	    config.makeDestination = { () in
	         // Use custom initializer
	         let destination = NoteEditorViewController(note: note)
	         return destination
	    }
        if let destination = config.makeDestination?() {
            // Set makedDestination so router will use this destination when performing
            config.makedDestination = destination
            return destination
        }
        return nil
	}
	return config
}

```

<details><summary>Objective-C Sample</summary>

Generic class`ZIKViewMakeableConfiguration`has property`makeDestinationWith`with`id(^)()`type. `id(^)()`means the block can accept any parameters. So you can declare your custom parameters of `makeDestinationWith` in protocol.

```objectivec
// The config works like EditorViewModuleConfiguration
ZIKViewMakeableConfiguration<NoteEditorViewController *> * makeEditorViewModuleConfiguration() {
	ZIKViewMakeableConfiguration<NoteEditorViewController *> *config = [ZIKViewMakeableConfiguration<NoteEditorViewController *> new];
	__weak typeof(config) weakConfig = config;
	
	// User is responsible for calling makeDestinationWith and giving parameters
	config.makeDestinationWith = ^id<EditorViewInput> _Nullable(Note *note) {
        // Capture parameters in makeDestination, so we don't need configuration subclass to hold the parameters
        // MakeDestination will be used for creating destination instance
	     weakConfig.makeDestination = ^ NoteEditorViewController * _Nullable{
	         // Use custom initializer
	         NoteEditorViewController *destination = [NoteEditorViewController alloc] initWithNote:note];
	         return destination;
	     };
        // Set makedDestination so router will use this destination when performing
        weakConfig.makedDestination = weakConfig.makeDestination();
        return weakConfig.makedDestination;
	};
	return config;
}
```

</details>

Override`defaultRouteConfiguration`in router to use your custom configuration:

```swift
class EditorViewRouter: ZIKViewRouter<NoteEditorViewController, ZIKViewMakeableConfiguration<NoteEditorViewController>> {
    
    override class func registerRoutableDestination() {
        // Register class
        registerView(NoteEditorViewController.self)
        // Register module config protocol, then we can use this protocol to fetch the router
        register(RoutableViewModule<EditorViewModuleInput>())
    }
    
    // Use custom configuration
    override class func defaultRouteConfiguration() -> ZIKViewMakeableConfiguration<NoteEditorViewController> {
        return makeEditorViewModuleConfiguration()
    }
    
    override func destination(with configuration: ZIKViewMakeableConfiguration<NoteEditorViewController>) -> NoteEditorViewController? {
        if let makeDestination = configuration.makeDestination {
            return makeDestination()
        }
        return nil
    }
    ...
}
```

<details><summary>Objective-C Sample</summary>

```swift
@interface EditorViewRouter: ZIKViewRouter<NoteEditorViewController, ZIKViewMakeableConfiguration<NoteEditorViewController>>
@end
@implementation EditorViewRouter {
    
+ (void) registerRoutableDestination {
    // Register class
    [self registerView:[NoteEditorViewController class]];
    // Register module config protocol, then we can use this protocol to fetch the router
    [self registerModuleProtocol:ZIKRoutable(EditorViewModuleInput)];
}
    
// Use custom configuration
+(ZIKViewMakeableConfiguration<NoteEditorViewController *> *)defaultRouteConfiguration() {
    return makeEditorViewModuleConfiguration();
}

- (NoteEditorViewController *)destinationWithConfiguration:(ZIKViewMakeableConfiguration<NoteEditorViewController *> *)configuration {
	if (configuration.makeDestination) {
	    return configuration.makeDestination();
	}
	return nil;
}
...
}
```

</details>

If you're not using router subclass, you can register config factory to create route:

```swift
// Register EditorViewModuleInput and factory function of custom configuration
ZIKAnyViewRouter.register(RoutableViewModule<EditorViewModuleInput>(),
   forMakingView: NoteEditorViewController.self, 
   making: makeEditorViewModuleConfiguration)
```

<details><summary>Objective-C Sample</summary>

```objectivec
// Register EditorViewModuleInput and factory function of custom configuration
[ZIKModuleViewRouter(EditorViewModuleInput)
     registerModuleProtocol:ZIKRoutable(EditorViewModuleInput)
     forMakingView:[NoteEditorViewController class]
     factory: makeEditorViewModuleConfiguration];
```

</details>

Now the user can use the module with its module config protocol and transfer parameters:

```swift
var note = ...
Router.makeDestination(to: RoutableViewModule<EditorViewModuleInput>()) { (config) in
     // Transfer parameters and get EditorViewInput
     let destination = config.makeDestinationWith(note)
}
```

<details><summary>Objective-C Sample</summary>

```objectivec
Note *note = ...
[ZIKRouterToViewModule(EditorViewModuleInput)
    performPath:ZIKViewRoutePath.showFrom(self)
    configuring:^(ZIKViewRouteConfiguration<EditorViewModuleInput> *config) {
        // Transfer parameters and get EditorViewInput
        id<EditorViewInput> destination = config.makeDestinationWith(note);
 }];
```

</details>

In this design pattern, we reduce much glue code for transferring parameters, and the module can re-declare their parameters with generic arguments and module config protocol.

For more detail, read [Transfer Parameters with Custom Configuration](Documentation/English/CustomConfiguration.md).

#### Remove

You can remove the view by `removeRoute`, without using pop / dismiss / removeFromParentViewController / removeFromSuperview:

```swift
class TestViewController: UIViewController {
    var router: DestinationViewRouter<EditorViewInput>?
    
    func showEditor() {
        // Hold the router
        router = Router.perform(to: RoutableView<EditorViewInput>(), path: .push(from: self))
    }
    
    // Router will pop the editor view controller
    func removeEditorDirectly() {
        guard let router = router, router.canRemove else {
            return
        }
        router.removeRoute()
        router = nil
    }
    
    func removeEditorWithResult() {
        guard let router = router, router.canRemove else {
            return
        }
        router.removeRoute(successHandler: {
            print("remove success")
        }, errorHandler: { (action, error) in
            print("remove failed, error: \(error)")
        })
        router = nil
    }
    
    func removeEditorAndPrepare() {
        guard let router = router, router.canRemove else {
            return
        }
        router.removeRoute(configuring: { (config) in
	            config.animated = true
	            config.prepareDestination = { destination in
	                // Use destination before remove it
	            }
            })
        router = nil
    }
}
```

<details><summary>Objective-C Sample</summary>

```objectivec
@interface TestViewController()
@property (nonatomic, strong) ZIKDestinationViewRouter(id<EditorViewInput>) *router;
@end
@implementation TestViewController

- (void)showEditorDirectly {
    // Hold the router
    self.router = [ZIKRouterToView(EditorViewInput) performPath:ZIKViewRoutePath.pushFrom(self)];
}

// Router will pop the editor view controller
- (void)removeEditorDirectly {
    if (![self.router canRemove]) {
        return;
    }
    [self.router removeRoute];
    self.router = nil;
}

- (void)removeEditorWithResult {
    if (![self.router canRemove]) {
        return;
    }
    [self.router removeRouteWithSuccessHandler:^{
        NSLog(@"pop success");
    } errorHandler:^(ZIKRouteAction routeAction, NSError *error) {
        NSLog(@"pop failed,error: %@",error);
    }];
    self.router = nil;
}

- (void)removeEditorAndPrepare {
    if (![self.router canRemove]) {
        return;
    }
    [self.router removeRouteWithConfiguring:^(ZIKViewRemoveConfiguration *config) {
        config.animated = YES;
        config.prepareDestination = ^(UIViewController<EditorViewInput> *destination) {
            // Use destination before remove it
        };
    }];
    self.router = nil;
}

@end
```

</details>

For more detail, read [Remove Route](Documentation/English/RemoveRoute.md).

### Adapter

You can use another protocol to get router, as long as the protocol provides the same interface of the real protocol. Even the protocol is little different from the real protocol, you can  adapt two protocols with category, extension and proxy.

Required protocol used by the user:

```swift
/// Required protocol to use editor module
protocol RequiredEditorViewInput: class {
    weak var delegate: EditorDelegate? { get set }
    func constructForCreatingNewNote()
}
```

<details><summary>Objective-C Sample</summary>

```objectivec
/// Required protocol to use editor module
@protocol RequiredEditorViewInput <ZIKViewRoutable>
@property (nonatomic, weak) id<EditorDelegate> delegate;
- (void)constructForCreatingNewNote;
@end
```

</details>

Use`RequiredEditorViewInput`to get module:

```swift
class TestViewController: UIViewController {

    func showEditorDirectly() {
        Router.perform(to: RoutableView<RequiredEditorViewInput>(), path: .push(from: self))
    }
}
```

<details><summary>Objective-C Sample</summary>

```objectivec
@implementation TestViewController

- (void)showEditorDirectly {
    [ZIKRouterToView(RequiredEditorViewInput) performPath:ZIKViewRoutePath.pushFrom(self)];
}

@end
```
</details>

Use `required protocol` and `provided protocol` to perfectly decouple modules, adapt interface and declare dependencies of the module. And you don't have to use a public header to manage those protocols.

You need to connect required protocol and provided protocol. For more detail, read [Module Adapter](Documentation/English/ModuleAdapter.md).

### URL Router

ZIKRouter is also compatible with other URL router frameworks.

You can register string identifier with router:

```swift
class NoteEditorViewRouter: ZIKViewRouter<NoteEditorViewController, ViewRouteConfig> {
    override class func registerRoutableDestination() {
        // Register identifier with this router
        registerIdentifier("myapp://noteEditor")
    }
}
```

<details><summary>Objective-C Sample</summary>

```objectivec
@implementation NoteEditorViewRouter

+ (void)registerRoutableDestination {
    // Register identifier with this router
    [self registerIdentifier:@"myapp://noteEditor"];
}

@end
```
</details>

Then perform route with the identifier:

```swift
Router.to(viewIdentifier: "myapp://noteEditor")?.perform(path .push(from: self))
```

<details><summary>Objective-C Sample</summary>

```objectivec
[ZIKViewRouter.toIdentifier(@"myapp://noteEditor") performPath:ZIKViewRoutePath.pushFrom(self)];
```
</details>

And handle URL Scheme:

```swift
public func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        // You can use other URL router frameworks
        let routerIdentifier = URLRouter.routerIdentifierFromURL(url)
        guard let identifier = routerIdentifier else {
            return false
        }
        guard let routerType = Router.to(viewIdentifier: identifier) else {
            return false
        }
        let params: [String : Any] = [ "url": url, "options": options ]
        routerType.perform(path: .show(from: rootViewController), configuring: { (config, _) in
            // Pass parameters
            config.addUserInfo(params)
        })
        return true
    }
```

<details><summary>Objective-C Sample</summary>

```objectivec
- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
    
    // You can use other URL router frameworks
    NSString *identifier = [URLRouter routerIdentifierFromURL:url];
    if (identifier == nil) {
        return NO;
    }
    ZIKViewRouterType *routerType = ZIKViewRouter.toIdentifier(identifier);
    if (routerType == nil) {
        return NO;
    }
    
    NSDictionary *params = @{ @"url": url,
                              @"options" : options
                              };
    [routerType performPath:ZIKViewRoutePath.showFrom(self.rootViewController)
                configuring:^(ZIKViewRouteConfiguration * _Nonnull config) {
                    // Pass parameters
                    [config addUserInfo:params];
                }];
    return YES;
}
```
</details>

### Service Router

Instead of view, you can also get any service modules:

```swift
/// time service's interface
protocol TimeServiceInput {
    func currentTimeString() -> String
}
```
```swift
class TestViewController: UIViewController {
    @IBOutlet weak var timeLabel: UILabel!
    
    func callTimeService() {
        // Get the service for TimeServiceInput
        let timeService = Router.makeDestination(
            to: RoutableService<TimeServiceInput>(),
            preparation: { destination in
            // prepare the service if needed
        })
        //Use the service
        timeLabel.text = timeService.currentTimeString()
    }
}
```

<details><summary>Objective-C Sample</summary>

```objectivec
/// time service's interface
@protocol TimeServiceInput <ZIKServiceRoutable>
- (NSString *)currentTimeString;
@end
```

```objectivec
@interface TestViewController ()
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@end

@implementation TestViewController

- (void)callTimeService {
   // Get the service for TimeServiceInput
   id<TimeServiceInput> timeService = [ZIKRouterToService(TimeServiceInput) makeDestination];
   self.timeLabel.text = [timeService currentTimeString];    
}

```

</details>

## Demo and Practice

ZIKRouter is designed for VIPER architecture at first. But you can also use it in MVC or anywhere.

The demo (ZIKRouterDemo) in this repository shows how to use ZIKRouter to perform each route type.

If you want to see how it works in a VIPER architecture app, go to [ZIKViper](https://github.com/Zuikyo/ZIKViper).

## File Template

You can use Xcode file template to create router and protocol code quickly:

![File Template](Documentation/Resources/filetemplate.png)

The template `ZIKRouter.xctemplate` is in [Templates](Templates/).

Copy `ZIKRouter.xctemplate` to `~/Library/Developer/Xcode/Templates/ZIKRouter.xctemplate`, then you can use it in `Xcode -> File -> New -> File -> Templates`.

## License

ZIKRouter is available under the MIT license. See the LICENSE file for more info.