# ZIKRouter
An interface-oriented iOS router for decoupling modules, discovering modules and injecting dependencies with protocol.

The view router can perform all navigation types in UIKit through one method.

The service router can discover corresponding module with it's protocol.

---

一个用于模块间路由，基于接口进行模块发现和依赖注入的Router。包括view router和service router。

View router将UIKit中的所有界面跳转方式封装成一个统一的方法。

Service router用于模块寻找，通过protocol寻找对应的模块，并用protocol进行依赖注入和模块调用。

### [中文文档](https://github.com/Zuikyo/ZIKRouter/blob/master/README-CN.md)

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

## Interface-oriented Programming

ZIKRouter is an interface-oriented design. The caller of the module doesn't know the class of the module, but only the interface of the module. Caller can get the module with it's protocol, and use the module with the protocol.

Comparing to URL router, interface-oriented router is safer and low coupling. It's also more efficient when updating the module interface, relying on the compile-time checking.

## Dependency Injection

You can inject dependencies in module's router. Router can declare the module's dependencies in it's protocol.

## Sample Code

How it looks like in code?

### View Router

Code for showing a view controller：

```objectivec
///editor view controller module's interface
@protocol NoteEditorProtocol <ZIKViewRoutable>
@property (nonatomic, weak) id<ZIKEditorDelegate> delegate;
- (void)constructForCreatingNewNote;
- (void)constructForEditingNote:(ZIKNoteModel *)note;
@end

```

```objectivec
@implementation TestEditorViewController

- (void)showEditor {
    //Transition to editor view. Get editor's router class with protocol, and prepare the editor view with the protocol.
    [ZIKViewRouterForConfig(@protocol(NoteEditorProtocol))
	     performWithConfigure:^(ZIKViewRouteConfiguration<NoteEditorProtocol> *config) {
	         //Route config
	         //Source view controller
	         config.source = self;
	         
	         //Transition type
	         config.routeType = ZIKViewRouteTypePush;
	         
	         //Router will config editor module with these arguments
	         config.delegate = self;
	         [config constructForCreatingNewNote];
	         
	         config.prepareForRoute = ^(id destination) {
	             //Prepare the destination before transition
	         };
	         config.routeCompletion = ^(id destination) {
	             //Transition completes
	         };
	         config.performerErrorHandler = ^(SEL routeAction, NSError * error) {
	             //Transition is failed
	         };
	     }];
}

@end
```
in Swift:

```swift
class TestEditorViewController: UIViewController {
    func showEditor() {
        ZIKSViewRouterForView(NoteEditorProtocol.self)?.perform { config in
            config.source = self
            config.routeType = ZIKViewRouteType.push
            config.constructForCreatingNewNote()
            config.prepareForRoute = { [weak self] des in
                let destination = des as! NoteEditorProtocol
                //Prepare the destination before transition
            }
            config.routeCompletion = { [weak self] des in
                let destination = des as! NoteEditorProtocol
                //Transition completes
            }
            config.performerErrorHandler = { [weak self] (action, error) in
                //Transition is failed
            }
        }
    }
}
```

### Service Router

Get a module and use:

```objectivec
///time service's interface
@protocol ZIKTimeServiceInput <ZIKServiceRoutable>
- (NSString *)currentTimeString;
@end
```

```objectivec
@interface TestServiceViewController ()
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@end

@implementation TestServiceViewController

- (void)callTimeService {
   [ZIKServiceRouterForService(@protocol(ZIKTimeServiceInput))
         performWithConfigure:^(ZIKServiceRouteConfiguration *config) {
            config.prepareForRoute = ^(id<ZIKTimeServiceInput> destination) {
                //config time service
            };
            config.routeCompletion = ^(id<ZIKTimeServiceInput> destination) {
                //Get timeService success
                id<ZIKTimeServiceInput> timeService = destination;
                //Use the service
                NSString *timeString = [timeService currentTimeString];
                self.timeLabel.text = timeString;
            };
        }];
    
}

```

## How to use

### Implement Router

Create a subclass of `ZIKViewRouter` for your module:

```objectivec
//MasterViewProtocol.h
//ZIKViewRotable declares that MasterViewProtocol can be used to get a router class by ZIKViewRouterForView()
@protocol MasterViewProtocol: ZIKViewRotable

@end
```
```objectivec
//MasterViewRouter.h
@interface MasterViewRouter : ZIKViewRouter <ZIKViewRouterProtocol>
@end

//MasterViewRouter.m
@implementation MasterViewRouter

//implementation of ZIKViewRouterProtocol

+ (void)registerRoutableDestination {
    //Register MasterViewController with  MasterViewRouter. A view can be registered in multi routers, and a router can be registered with multi views.
    ZIKViewRouter_registerView([MasterViewController class], self);
    
    //Register MasterViewProtocol, then you can use ZIKViewRouterForView() to get MasterViewRouter class. You can also use subclass of ZIKViewRouteAdapter, and register protocols for other ZIKViewRouter classes in it's +registerRoutableDestination
    ZIKViewRouter_registerViewProtocol(@protocol(MasterViewProtocol), self);
}

//Initialize and return the destination
- (id)destinationWithConfiguration:(__kindof ZIKRouteConfiguration *)configuration {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    MasterViewController *destination = [sb instantiateViewControllerWithIdentifier:@"master"];
    return destination;
}

//Config the destination before peforming route
- (void)prepareDestination:(MasterViewController *)destination configuration:(__kindof ZIKViewRouteConfiguration *)configuration {
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
	
	//You can directly use MasterViewRouter，or use ZIKViewRouterForView(@protocol(MasterViewProtocol)) to get the class.
	//When you use protocol to get the router class, you can use the protocol to config the destination
	router = [MasterViewRouter
	          performWithConfigure:^(ZIKViewRouteConfiguration *config) {
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

```
pod "ZIKRouter"
```

## License

ZIKRouter is available under the MIT license. See the LICENSE file for more info.