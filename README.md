# ZIKRouter

![](https://img.shields.io/cocoapods/p/ZIKRouter.svg?style=flat)
![](https://img.shields.io/badge/language-objectivec-green.svg)
![ZIKRouter](https://img.shields.io/cocoapods/v/ZIKRouter.svg?style=flat)
![](https://img.shields.io/badge/language-swift-orange.svg)
![ZRouter](https://img.shields.io/cocoapods/v/ZRouter.svg?style=flat)
![license](https://img.shields.io/github/license/mashape/apistatus.svg)

An interface-oriented iOS router for decoupling modules, discovering modules and injecting dependencies with protocol.

The view router can perform all navigation types in UIKit through one method.

The service router can discover corresponding module with it's protocol.

---

一个用于模块间路由，基于接口进行模块发现和依赖注入的Router。包括view router和service router。

View router将UIKit中的所有界面跳转方式封装成一个统一的方法。

Service router用于模块寻找，通过protocol寻找对应的模块，并用protocol进行依赖注入和模块调用。

### [中文文档](Documentation/Chinese/README-CN.md)

---

## Features

* Discover view or module with protocol, decoupling the source and the destination class
* Prepare the route with protocol in block, instead of directly configuring the destination (the source is coupled with the destination) or in delegate method (in `-prepareForSegue:sender:` you have to distinguish different destinations, and they're alse coupled with source)
* Support route for view and any module
* Support all route types in UIKit (push, present modally, present as popover, segue, show, showDetail, addChildViewController, addSubview and custom presentation), encapsulating into one method
* Remove a view through one method, without using `-popViewControllerAnimated:`,`-dismissViewControllerAnimated:completion:`,`removeFromParentViewController`,`removeFromSuperview` in different sistuation. Router can choose the proper method
* Support storyboard. UIViewController and UIView from a segue can auto create it's registered router
* Enough error checking for view route action
* AOP support for view route action

## Features

- [x] Swift, Objective-C and mixed development Support
- [x] Routing for UIViewController, UIView and any classes
- [x] Dependency injection
- [x] Locate view and service with it's protocol
- [x] Prepare the module with it's protocol when performing route, such as passing parameters or method injection. Forget passing a parameters dictionary now
- [x] Declare routable protocol. There're compile-time checking and runtime checking to make safe routing
- [x] Declare a specific router with generic parameters
- [x] Decouple modules and add compatible interfaces with adapter
- [x] Encapsulate navigation methods in UIKit (push, present modally, present as popover, segue, show, showDetail, addChildViewController, addSubview) and your custom navigation actions into one method
- [x] Remove a UIviewController/UIView or unload a module by one method, never to use pop、dismiss、removeFromParentViewController、removeFromSuperview in different situation
- [x] Support storyboard
- [x] Error checking for UIKit view transition
- [x] AOP for view transition
- [ ] Support Mac OS and tv OS
- [ ] Register router manually after launch, but not auto registering all routers
- [ ] Add route for module with block, but not router subclass

## Interface-oriented Programming

ZIKRouter is an interface-oriented design. The caller of the module doesn't know the class of the module, but only the interface of the module. Caller can get the module with it's protocol, and use the module with the protocol.

Comparing to URL router, interface-oriented router is safer and low coupling. It's also more efficient when updating the module interface, relying on the compile-time checking.

## Dependency Injection

You can inject dependencies in module's router. Router can declare the module's dependencies in it's protocol.

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

- (void)showEditor {
    //Transition to editor view, and prepare the destination with NoteEditorInput
    [ZIKViewRouter.toView(@protocol(NoteEditorInput))
	     performFromSource:self
	     configuring:^(ZIKViewRouteConfig *config) {
	         //路由相关的设置
	         //设置跳转方式
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

## How to use

### Implement Router

Create a subclass of `ZIKViewRouter` for your module:

```objectivec
//MasterViewProtocol.h
//ZIKViewRotable declares that MasterViewProtocol can be used to get a router class by ZIKViewRouterForView()
@protocol MasterViewProtocol: ZIKViewRoutable

@end
```
```objectivec
//MasterViewRouter.h
@interface MasterViewRouter : ZIKViewRouter
@end

//MasterViewRouter.m
@implementation MasterViewRouter

//Override methods in superclass

+ (void)registerRoutableDestination {
    //Register MasterViewController with  MasterViewRouter. A view can be registered in multi routers, and a router can be registered with multi views.
    [self registerView:[MasterViewController class]];
    
    //Register MasterViewProtocol, then you can use ZIKViewRouter.toView() to get MasterViewRouter class. You can also use subclass of ZIKViewRouteAdapter, and register protocols for other ZIKViewRouter classes in it's +registerRoutableDestination
    [self registerViewProtocol:@protocol(MasterViewProtocol)];
}

//Initialize and return the destination
- (id)destinationWithConfiguration:(ZIKViewRouteConfiguration *)configuration {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    MasterViewController *destination = [sb instantiateViewControllerWithIdentifier:@"master"];
    return destination;
}

//Config the destination before peforming route
- (void)prepareDestination:(MasterViewController *)destination configuration:(ZIKViewRouteConfiguration *)configuration {
    destination.tableView.backgroundColor = [UIColor lightGrayColor];
}

//Destination is prepared, validate it's dependencies
- (void)didFinishPrepareDestination:(id)destination configuration:(__kindof ZIKViewRouteConfiguration *)configuration {
    
}

//AOP methods for routing
+ (void)router:(nullable ZIKViewRouter *)router willPerformRouteOnDestination:(id)destination fromSource:(id)source {
    
}
+ (void)router:(nullable ZIKViewRouter *)router didPerformRouteOnDestination:(id)destination fromSource:(id)source {
    
}
+ (void)router:(nullable ZIKViewRouter *)router willRemoveRouteOnDestination:(id)destination fromSource:(id)source {
    
}
+ (void)router:(nullable ZIKViewRouter *)router didRemoveRouteOnDestination:(id)destination fromSource:(id)source {
    
}

@end
```

### Use the Router

```objectivec
//In some view controller

@implementation TestViewController

- (void)showMasterViewController {
	ZIKViewRouter *router;
	
	//You can directly use MasterViewRouter，or use ZIKViewRouter.toView(@protocol(MasterViewProtocol)) to get the class.
	//When you use protocol to get the router class, you can use the protocol to config the destination
	router = [ZIKViewRouter.toView(@protocol(MasterViewProtocol))
	          performWithConfiguring:^(ZIKViewRouteConfiguration *config) {
	              config.source = self;
	              config.routeType = ZIKViewRouteTypePresentModally;
	              config.animated = YES;
	              config.prepareForRoute = ^(UIViewController *destination) {
	              //Config transition style
	                  destination.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
	              };
	              config.routeCompletion = ^(UIViewController *destination) {
	                  //Transition completes
	              };
	              config.performerErrorHandler = ^(SEL routeAction, NSError *error) {
	                  //Transition is failed
	              };
	          }];
	 self.router = router;
}

- (void)removeMasterViewController {
	//You can use the router to remove a routed view
	[self.router removeRouteWithSuccessHandler:^{
	    //Remove success
	} performerErrorHandler:^(SEL routeAction, NSError *error) {
	    //Remove failed
	}];
}
```

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