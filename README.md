<p align="center">
  <img src="Documentation/Resources/icon.png" width="33%">
</p>

# ZIKRouter

![](https://img.shields.io/cocoapods/p/ZIKRouter.svg?style=flat)
![](https://img.shields.io/badge/language-objectivec-blue.svg)
![ZIKRouter](https://img.shields.io/cocoapods/v/ZIKRouter.svg?style=flat)
![](https://img.shields.io/badge/language-swift-orange.svg)
![ZRouter](https://img.shields.io/cocoapods/v/ZRouter.svg?style=flat)
![license](https://img.shields.io/github/license/mashape/apistatus.svg)

An interface-oriented router for discovering modules and injecting dependencies with protocol.

The view router can perform all navigation types in UIKit through one method.

The service router can discover and prepare corresponding module with it's protocol.

---

一个用于模块间路由，基于接口进行模块发现和依赖注入的解耦工具。

View router 将 UIKit 中的所有界面跳转方式封装成一个统一的方法。

Service router 用于模块寻找，通过 protocol 寻找对应的模块，并用 protocol 进行依赖注入和模块调用。可和其他 URL router 兼容。

### [中文文档](Documentation/Chinese/README.md)

---

## Features

- [x] Support Swift and Objective-C
- [x] Routing for UIViewController, UIView and any classes
- [x] Dependency injection
- [x] **Locate module with it's protocol**
- [x] **Locate module with identifier, compatible with other URL router**
- [x] **Prepare the module with it's protocol when performing route, rather than passing a parameter dictionary**
- [x] **Use different adapter protocols inside module and module's user for the same module to make thorough decouple**
- [x] **Declare routable protocol. There're compile-time checking and runtime checking to make routing reliable**
- [x] Declare a specific router with generic parameters
- [x] **Decouple modules and add compatible interfaces with adapter**
- [x] Encapsulate navigation methods in UIKit (push, present modally, present as popover, segue, show, showDetail, addChildViewController, addSubview) and custom transitions into one method
- [x] Remove a UIviewController/UIView or unload a module through one method, without using pop、dismiss、removeFromParentViewController、removeFromSuperview in different situation. Router can choose the proper method
- [x] **Support storyboard. UIViewController and UIView from a segue can auto create it's registered router**
- [x] Error checking for UIKit view transition
- [x] AOP for view transition
- [x] Auto register all routers, or manually register each router
- [x] Add route with router subclasses, or with blocks
- [ ] Support Mac OS and tv OS (only iOS now)

## Table of Contents

### Basics

1. [Router Implementation](Documentation/English/RouterImplementation.md)
2. [Module Registration](Documentation/English/ModuleRegistration.md)
3. [Routable Declaration](Documentation/English/RoutableDeclaration.md)
4. [Type Checking](Documentation/English/TypeChecking.md)
5. [Perform Route](Documentation/English/PerformRoute.md)
6. [Remove Route](Documentation/English/RemoveRoute.md)
7. [Make Destination](Documentation/English/MakeDestination.md)

### Advanced Features

1. [Error Handle](Documentation/English/ErrorHandle.md)
2. [Storyboard and Auto Create](Documentation/English/Storyboard.md)
3. [AOP](Documentation/English/AOP.md)
4. [Dependency Injection](Documentation/English/DependencyInjection.md)
5. [Circular Dependency](Documentation/English/CircularDependencies.md)
6. [Module Adapter](Documentation/English/ModuleAdapter.md)

## Sample

### View Router

Demo view controller and protocol：

```swift
///Editor view's interface
protocol NoteEditorInput: class {
    weak var delegate: EditorDelegate? { get set }
    func constructForCreatingNewNote()
}

///Editor view controller
class NoteEditorViewController: UIViewController, NoteEditorInput {
    ...
}
```

<details><summary>Objective-C Sample</summary>
  
```objectivec
///editor view's interface
@protocol NoteEditorInput <ZIKViewRoutable>
@property (nonatomic, weak) id<EditorDelegate> delegate;
- (void)constructForCreatingNewNote;
@end
```

```objectivec
///Editor view controller
@interface NoteEditorViewController: UIViewController <NoteEditorInput>
@end
@implementation NoteEditorViewController
@end
```

</details>

#### Transition directly

Transition to editor view directly:

```swift
class TestViewController: UIViewController {

    //Transition to editor view directly
    func showEditorDirectly() {
        Router.perform(to: RoutableView<NoteEditorInput>(), path: .push(from: self))
    }
}
```

<details><summary>Objective-C Sample</summary>

```objectivec
@implementation TestViewController

- (void)showEditorDirectly {
    //Transition to editor view directly
    [ZIKRouterToView(NoteEditorInput) performPath:ZIKViewRoutePath.pushFrom(self)];
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

#### Transition and Prepare

Transition to editor view, and prepare it before transition:

```swift
class TestViewController: UIViewController {

    //Transition to editor view, and prepare the destination with NoteEditorInput
    func showEditor() {
        Router.perform(
            to: RoutableView<NoteEditorInput>(),
            path: .push(from: self),
            configuring: { (config, prepareDestination, _) in
                //Route config
                config.successHandler = { destination in
                    //Transition succeed
                }
                config.errorHandler = { (action, error) in
                    //Transition failed
                }
                //Prepare the destination before transition
                prepareDestination({ destination in
                    //destination is inferred as NoteEditorInput
                    destination.delegate = self
                    destination.constructForCreatingNewNote()
                })
        })
    }
}
```

<details><summary>Objective-C Sample</summary>

```objectivec
@implementation TestViewController

- (void)showEditor {
    //Transition to editor view, and prepare the destination with NoteEditorInput
    [ZIKRouterToView(NoteEditorInput)
	     performPath:ZIKViewRoutePath.pushFrom(self)
	     configuring:^(ZIKViewRouteConfig *config) {
	         //Route config
	         //Prepare the destination before transition
	         config.prepareDestination = ^(id<NoteEditorInput> destination) {
	             destination.delegate = self;
	             [destination constructForCreatingNewNote];
	         };
	         config.successHandler = ^(id<NoteEditorInput> destination) {
	             //Transition is completed
	         };
	         config.errorHandler = ^(SEL routeAction, NSError * error) {
	             //Transition failed
	         };
	     }];
}

@end
```

</details>

#### Remove

You can remove the view by `removeRoute`, without using pop / dismiss / removeFromParentViewController / removeFromSuperview:

```swift
class TestViewController: UIViewController {
    var router: DestinationViewRouter<NoteEditorInput>?
    
    func showEditor() {
        //Hold the router
        router = Router.perform(to: RoutableView<NoteEditorInput>(), path: .push(from: self))
    }
    
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
        router.removeRoute(configuring: { (config, prepareDestination) in
	            config.animated = true
	            prepareDestination({ destination in
	                //Use destination before remove it
	            })
            })
        router = nil
    }
}
```

<details><summary>Objective-C Sample</summary>

```objectivec
@interface TestViewController()
@property (nonatomic, strong) ZIKDestinationViewRouter(id<NoteEditorInput>) *router;
@end
@implementation TestViewController

- (void)showEditorDirectly {
    //Hold the router
    self.router = [ZIKRouterToView(NoteEditorInput) performPath:ZIKViewRoutePath.pushFrom(self)];
}

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
        config.prepareDestination = ^(UIViewController<NoteEditorInput> *destination) {
            //Use destination before remove it
        };
    }];
    self.router = nil;
}

@end
```

</details>

### Service Router

Get a module and use:

```swift
///time service's interface
protocol TimeServiceInput {
    func currentTimeString() -> String
}
```
```swift
class TestViewController: UIViewController {
    @IBOutlet weak var timeLabel: UILabel!
    
    func callTimeService() {
        //Get the service for TimeServiceInput
        let timeService = Router.makeDestination(
            to: RoutableService<TimeServiceInput>(),
            preparation: { destination in
            //prepare the service if needed
        })
        //Use the service
        timeLabel.text = timeService.currentTimeString()
    }
}
```

<details><summary>Objective-C Sample</summary>

```objectivec
///time service's interface
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
   //Get the service for TimeServiceInput
   id<TimeServiceInput> timeService = [ZIKRouterToService(TimeServiceInput) makeDestination];
   self.timeLabel.text = [timeService currentTimeString];    
}

```

</details>

## Demo and Practice

ZIKRouter is designed for VIPER architecture at first. But you can also use it in MVC or anywhere.

The demo (ZIKRouterDemo) in this repository shows how to use ZIKRouter to perform each route type.

If you want to see how it works in a VIPER architecture app, go to [ZIKViper](https://github.com/Zuikyo/ZIKViper).

## Requirements

* iOS 7.0+
* Swift 3.2+
* Xcode 9.0+

## Installation

### Cocoapods

For Objective-C project:

```
pod 'ZIKRouter', '>= 1.0.0'
```
For Swift project:

```
pod 'ZRouter', '>= 1.0.0'
```

## How to use

Quick start to use ZIKRouter.

### 1.Create Router

Create router subclass for your module:

```swift
import ZIKRouter.Internal
import ZRouter

class NoteEditorViewRouter: ZIKViewRouter<NoteEditorViewController, ViewRouteConfig> {
    override class func registerRoutableDestination() {
        registerView(NoteEditorViewController.self)
        register(RoutableView<NoteEditorInput>())
    }
    
    override func destination(with configuration: ViewRouteConfig) -> NoteEditorViewController? {
        let destination: NoteEditorViewController? = ... ///instantiate your view controller
        return destination
    }
    
    override func prepareDestination(_ destination: NoteEditorViewController, configuration: ViewRouteConfig) {
        //Inject dependencies to destination
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
    [self registerView:[NoteEditorViewController class]];
    [self registerViewProtocol:ZIKRoutable(NoteEditorInput)];
}

- (NoteEditorViewController *)destinationWithConfiguration:(ZIKViewRouteConfiguration *)configuration {
    NoteEditorViewController *destination = ... ///instantiate your view controller
    return destination;
}

- (void)prepareDestination:(NoteEditorViewController *)destination configuration:(ZIKViewRouteConfiguration *)configuration {
    //Inject dependencies to destination
}

@end
```

</details>

Read the documentation for more details and more methods to override.

### 2.Declare Routable Type

```swift
//Declare NoteEditorViewController is routable
extension NoteEditorViewController: ZIKRoutableView {
}

//Declare NoteEditorInput is routable
extension RoutableView where Protocol == NoteEditorInput {
    init() { self.init(declaredProtocol: Protocol.self) }
}
```

<details><summary>Objective-C Sample</summary>

```objectivec
//Declare NoteEditorViewController is routable
DeclareRoutableView(NoteEditorViewController, NoteEditorViewRouter)

///If the protocol inherits from ZIKViewRoutable, it's routable
@protocol NoteEditorInput <ZIKViewRoutable>
@property (nonatomic, weak) id<EditorDelegate> delegate;
- (void)constructForCreatingNewNote;
@end
```

</details>

### 3.Use

```swift
class TestViewController: UIViewController {

    //Transition to editor view directly
    func showEditorDirectly() {
        Router.perform(to: RoutableView<NoteEditorInput>(), path: .push(from: self))
    }
    
    //Transition to editor view, and prepare the destination with NoteEditorInput
    func showEditor() {
        Router.perform(
            to: RoutableView<NoteEditorInput>(),
            path: .push(from: self),
            configuring: { (config, prepareDestination, _) in
                //Prepare the destination before transition
                prepareDestination({ destination in
                    //destination is inferred as NoteEditorInput
                    destination.delegate = self
                    destination.constructForCreatingNewNote()
                })
        })
    }
}
```

<details><summary>Objective-C Sample</summary>

```objectivec
@implementation TestViewController

//Transition to editor view directly
- (void)showEditorDirectly {
    //Transition to editor view directly
    [ZIKRouterToView(NoteEditorInput) performPath:ZIKViewRoutePath.pushFrom(self)];
}

//Transition to editor view, and prepare the destination with NoteEditorInput
- (void)showEditor {
    [ZIKRouterToView(NoteEditorInput)
	     performPath:ZIKViewRoutePath.pushFrom(self)
	     configuring:^(ZIKViewRouteConfig *config) {
	         //Prepare the destination before transition
	         config.prepareDestination = ^(id<NoteEditorInput> destination) {
	             destination.delegate = self;
	             [destination constructForCreatingNewNote];
	         };
	     }];
}

@end
```

</details>

### File Template

You can use Xcode file template to create router and protocol code quickly:

![File Template](Documentation/Resources/filetemplate.png)

The template `ZIKRouter.xctemplate` is in [Templates](Templates/).

Copy `ZIKRouter.xctemplate` to `~/Library/Developer/Xcode/Templates/ZIKRouter.xctemplate`, then you can use it in `Xcode -> File -> New -> File -> Templates`.

## License

ZIKRouter is available under the MIT license. See the LICENSE file for more info.