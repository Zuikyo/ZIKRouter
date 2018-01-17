# ZIKRouter

![](https://img.shields.io/cocoapods/p/ZIKRouter.svg?style=flat)
![](https://img.shields.io/badge/language-objectivec-green.svg)
![ZIKRouter](https://img.shields.io/cocoapods/v/ZIKRouter.svg?style=flat)
![](https://img.shields.io/badge/language-swift-orange.svg)
![ZRouter](https://img.shields.io/cocoapods/v/ZRouter.svg?style=flat)
![license](https://img.shields.io/github/license/mashape/apistatus.svg)

An interface-oriented iOS router for discovering modules and injecting dependencies with protocol.

The view router can perform all navigation types in UIKit through one method.

The service router can discover corresponding module with it's protocol.

---

一个用于模块间路由，基于接口进行模块发现和依赖注入的Router。包括view router和service router。

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

## Sample Code

### View Router

Showing a view controller：

```swift
///editor view's interface
protocol NoteEditorInput {
    weak var delegate: EditorDelegate? { get set }
    func constructForCreatingNewNote()
}

///Editor view controller
class NoteEditorViewController: UIViewController, NoteEditorInput {
    ...
}
```

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
                //Route config
                //Transition type
                config.routeType = ViewRouteType.push
                config.routeCompletion = { destination in
                    //Transition completes
                }
                config.errorHandler = { (action, error) in
                    //Transition is failed
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

<details><summary>Objecive-C Sample</summary>
  
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
```objectivec
@implementation TestViewController

- (void)showEditorDirectly {
    //Transition to editor view directly
    [ZIKViewRouter.toView(@protocol(NoteEditorInput))
	     performFromSource:self routeType:ZIKViewRouteTypePush];
}

- (void)showEditor {
    //Transition to editor view, and prepare the destination with NoteEditorInput
    [ZIKViewRouter.toView(@protocol(NoteEditorInput))
	     performFromSource:self
	     configuring:^(ZIKViewRouteConfig *config) {
	         //Route config
            //Transition type
	         config.routeType = ZIKViewRouteTypePush;
	         config.prepareDestination = ^(id<NoteEditorInput> destination) {
	             //Prepare the destination before transition
	             destination.delegate = self;
	             [destination constructForCreatingNewNote];
	         };
	         config.routeCompletion = ^(id<NoteEditorInput> destination) {
	             //Transition completes
	         };
	         config.performerErrorHandler = ^(SEL routeAction, NSError * error) {
	             //Transition is failed
	         };
	     }];
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
   id<TimeServiceInput> timeService = [ZIKServiceRouter.toService(TimeServiceInput) makeDestination];
   self.timeLabel.text = [timeService currentTimeString];    
}

```

</details>

## Demo and Practice

ZIKRouter is designed for VIPER architecture at first. But you can also use it in MVC or anywhere.

The demo (ZIKRouterDemo) in this repository shows how to use ZIKRouter to perform each route type.

If you want to see how it works in a VIPER architecture app, go to [ZIKViper](https://github.com/Zuikyo/ZIKViper).

## Cocoapods

For Objective-C project:

```
pod 'ZIKRouter', '0.10.0'
```
For Swift project:

```
pod 'ZRouter', '0.5.0'
```

## License

ZIKRouter is available under the MIT license. See the LICENSE file for more info.