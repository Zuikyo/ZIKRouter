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

一个用于模块间路由，基于接口进行模块发现和依赖注入的Router。

View router将UIKit中的所有界面跳转方式封装成一个统一的方法。

Service router用于模块寻找，通过protocol寻找对应的模块，并用protocol进行依赖注入和模块调用。

### [中文文档](Documentation/Chinese/README-CN.md)

---

## Features

- [x] Swift, Objective-C and mixed development Support
- [x] Routing for UIViewController, UIView and any classes
- [x] Dependency injection
- [x] Locate view and service with it's protocol
- [x] Prepare the module with it's protocol when performing route, rather than passing a parameter dictionary
- [x] Use different protocols inside module and module's caller to get the same module, then the caller won't couple with any protocol
- [x] Declare routable protocol. There're compile-time checking and runtime checking to make safe routing
- [x] Declare a specific router with generic parameters
- [x] Decouple modules and add compatible interfaces with adapter
- [x] Encapsulate navigation methods in UIKit (push, present modally, present as popover, segue, show, showDetail, addChildViewController, addSubview) and custom transitions into one method
- [x] Remove a UIviewController/UIView or unload a module through one method, without using pop、dismiss、removeFromParentViewController、removeFromSuperview in different situation. Router can choose the proper method
- [x] Support storyboard. UIViewController and UIView from a segue can auto create it's registered router
- [x] Error checking for UIKit view transition
- [x] AOP for view transition
- [ ] Support Mac OS and tv OS
- [ ] Register router manually after launch, not just automatically registering all routers
- [ ] Add route for module with block, not just router subclasses

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
2. [Storyboard](Documentation/English/Storyboard.md)
3. [AOP](Documentation/English/AOP.md)
4. [Dependency Injection](Documentation/English/DependencyInjection.md)
5. [Circular Dependency](Documentation/English/CircularDependencies.md)
6. [Module Adapter](Documentation/English/ModuleAdapter.md)

## Sample

### View Router

Demo view controller and protocol：

```swift
///Editor view's interface
protocol NoteEditorInput {
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
        Router.perform(to: RoutableView<NoteEditorInput>(), from: self, routeType: .push)
        })
    }
}
```

<details><summary>Objective-C Sample</summary>

```objectivec
@implementation TestViewController

- (void)showEditorDirectly {
    //Transition to editor view directly
    [ZIKRouterToView(NoteEditorInput) performFromSource:self routeType:ZIKViewRouteTypePush];
}

@end
```

</details>

You can change transition type with `routeType`:

```swift
enum ZIKViewRouteType : Int {
    case push
    case presentModally
    case presentAsPopover
    case performSegue
    case show
    case showDetail
    case addAsChildViewController
    case addAsSubview
    case custom
    case getDestination
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
            from: self,
            configuring: { (config, prepareDestination, _) in
                //Route config
                //Transition type
                config.routeType = .push
                config.routeCompletion = { destination in
                    //Transition is completed
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
	     performFromSource:self
	     configuring:^(ZIKViewRouteConfig *config) {
	         //Route config
	         //Transition type
	         config.routeType = ZIKViewRouteTypePush;
	         //Prepare the destination before transition
	         config.prepareDestination = ^(id<NoteEditorInput> destination) {
	             destination.delegate = self;
	             [destination constructForCreatingNewNote];
	         };
	         config.routeCompletion = ^(id<NoteEditorInput> destination) {
	             //Transition is completed
	         };
	         config.performerErrorHandler = ^(SEL routeAction, NSError * error) {
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
        router = Router.perform(to: RoutableView<NoteEditorInput>(), from: self, routeType: .push)
        })
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
            print("remove failed, error:%@",error)
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
    self.router = [ZIKRouterToView(NoteEditorInput)
	     performFromSource:self routeType:ZIKViewRouteTypePush];
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
        NSLog(@"pop failed,error:%@",error);
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

## Installation

### Cocoapods

For Objective-C project:

```
pod 'ZIKRouter', '0.13.0'
```
For Swift project:

```
pod 'ZRouter', '0.9.0'
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
        let destination: SwiftSampleViewController? = ... ///instantiate your view controller
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
    [self registerView:[NoteEditorViewRouter class]];
    [self registerViewProtocol:ZIKRoutableProtocol(NoteEditorInput)];
}

- (NoteEditorViewRouter *)destinationWithConfiguration:(ZIKViewRouteConfiguration *)configuration {
    NoteEditorViewRouter *destination = ... ///instantiate your view controller
    return destination;
}

- (void)prepareDestination:(NoteEditorViewRouter *)destination configuration:(ZIKViewRouteConfiguration *)configuration {
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
    init() { }
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
        Router.perform(to: RoutableView<NoteEditorInput>(), from: self, routeType: .push)
        })
    }
    
    //Transition to editor view, and prepare the destination with NoteEditorInput
    func showEditor() {
        Router.perform(
            to: RoutableView<NoteEditorInput>(),
            from: self,
            configuring: { (config, prepareDestination, _) in
                config.routeType = .push
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
    [ZIKRouterToView(NoteEditorInput) performFromSource:self routeType:ZIKViewRouteTypePush];
}

//Transition to editor view, and prepare the destination with NoteEditorInput
- (void)showEditor {
    [ZIKRouterToView(NoteEditorInput)
	     performFromSource:self
	     configuring:^(ZIKViewRouteConfig *config) {
	         config.routeType = ZIKViewRouteTypePush;
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

## License

ZIKRouter is available under the MIT license. See the LICENSE file for more info.