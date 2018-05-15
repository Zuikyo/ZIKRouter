# Module Registration

You have to override `registerRoutableDestination` in router to register your module's class and it's protocol. All routers' `registerRoutableDestination` will be automatically called when app is launched.

## Register destination class

You can create multi routers for the same class. For example, there can be multi routers for `UIAlertController`, which providing different functions. Router A provides a compatible way to use `UIAlertView` and `UIAlertController`. Router B 
just provides easy functions to use `UIAlertController`. To use these routers in different situation, router A and B need to register different protocols, and get corresponding router with protocol.

```swift
class CommonAlertViewRouter: ZIKAnyViewRouter {
    override class func registerRoutableDestination() {
        registerView(UIAlertViewController.self)
        registerView(UIAlertView.self)
        register(RoutableView<CommonAlertViewInput>())
    }
}
```
```swift
class EasyAlertViewRouter: ZIKAnyViewRouter {
    override class func registerRoutableDestination() {
        registerView(UIAlertViewController.self)
        register(RoutableView<EasyAlertViewInput>())
    }
}
```

The propose of registering destination class, is for error checking, and supporting storyboard. When a segue is performed, we need to search the UIViewController's router to config it.

## Exclusiveness

When you create router and inject required dependencies for your own module, the user have to use this router and can't create another router. You can use `+registerExclusiveView:` to make an exclusive registration. Then other router can't register this view, or there will be an assert failure.

```swift
class EditorViewRouter: ZIKAnyViewRouter {
    override class func registerRoutableDestination() {
        registerExclusiveView(EditorViewController.self)
    }
}
```

Use common registration when the destination class is public, such as classes in system frameworks and third party. Use exclusiveness registration when the destination class is provided by your own.

## Register protocol

You can register destination's protocol. Then you can get the router with the protocol, rather than import the router subclass.

And you can prepare the destination and do method injection with the protocol when performing route.

### Destination protocol

If your module is simple and all dependencies can be set on destination, you only need to use protocol conformed by destination.

### Module protocol

If your module contains multi components, and those components' dependencies can't be passed through destination, you need a module config protocol, and config components' dependencies inside router.

For example, when you pass a model to a VIPER module, the destination is the view in VIPER, and the view is not responsible for accepting any models.

```swift
///Module config protocol for editor module
protocol EditorModuleConfig {
    var noteModel: Note?
}
///Use subclass of ZIKRouteConfiguration to save the custom config
class EditorModuleConfiguration: ZIKViewRouteConfiguration, EditorModuleConfig {
    var noteModel: Note?
}

class EditorViewRouter: ZIKViewRouter<EditorViewController, EditorModuleConfiguration> {
    override class func registerRoutableDestination() {
        registerView(EditorViewController.self)
        register(RoutableViewModule<EditorModuleConfig>())
    }
    //Use custom configuration
    override defaultConfiguration() -> EditorModuleConfiguration {
        return EditorModuleConfiguration()
    }
    
    override func destination(with configuration: EditorModuleConfiguration) -> EditorViewController? {
        let sb = UIStoryboard.init(name: "Main", bundle: nil)
        let destination = sb.instantiateViewController(withIdentifier: "EditorViewController") as! EditorViewController
        return destination
    }
    
    override func prepareDestination(_ destination: EditorViewController, configuration: EditorModuleConfiguration) {
        //Config VIPER module
        let view = destination
        guard view.presenter == nil else {
            return
        }
        let presenter = EditorPresenter()
        let interactor = EditorInteractor()
        
        //Give model to interactor
        interactor.note = configuration.noteModel
        
        presenter.interactor = interactor
        presenter.view = view
        view.presenter = presenter
    }
}

```

## Register Identifier

You can register a unique identifier for the router:

```swift
class EditorViewRouter: ZIKAnyViewRouter {
    override class func registerRoutableDestination() {
        registerIdentifier("viewController-editor")
    }
}
```

Then you can get the router with the identifier:

```
var userInfo: [String : Any] = ... // Pass parameters in a dictionary
Router.to(viewIdentifier: "viewController-editor")?
	.perform(path: .push(from: self), configuring: { (config, _, _) in
    	config.addUserInfo(userInfo)
	})
```

We can't check type of parameters when passing in a dictionary, so it's not recommanded to use for most cases. You should only use this function when the module needs to support URL scheme. You can combine other URL router with ZIKRouter with identifier matching.

## Auto Registration

When app is launched, ZIKRouter will enumerate all classes and call router's `registerRoutableDestination` method.

Here is the performance test for auto registration. There're 5000 UIViewController and 5000 router class.

Register by `+registerView:` and `+registerViewProtocol:`:

* iPhone 6s device: 58ms
* iPhone 5  device: 240ms

Register by `+registerExclusiveView:` and `+registerViewProtocol:`:

* iPhone 6s device: 50ms
* iPhone 5  device: 220ms

There is no performance problem in new device. In old device like iPhone 5, most time is costed by objc method invocation. The time is almost the same even we replace registration methods with empty methods that do nothing.

## Manually Registration

If you worry about the performance of auto registration in old device, you can disable auto registration, and register each router manually.

### 1. Disable Auto Registration

```objectivec
// Disable auto registration in +load, or before UIApplicationMain
+ (void)load {
    ZIKRouteRegistry.autoRegister = NO;
    [self registerForModulesBeforeRegistrationFinished];
}

+ (void)registerForModulesBeforeRegistrationFinished {
    // Register routers used when registration is not finished yet.
}

```

But if some modules require some routers before you register them, then there will be assert failure, you should register those required routers earlier. Such as routable initial view controller from storyboard, or any routers used in this initial view controller.

### 2. Register Routers

Then you can register each routers:

```objectivec
@import ZIKRouter.Internal;
#import "EditorViewRouter.h"

+ (void)registerRoutes {
    [EditorViewRouter registerRoutableDestination];
    ...
    // Finish
    [ZIKRouteRegistry notifyRegistrationFinished];
}

```
---
#### Next section: [Routable Declaration](./RoutableDeclaration.md)