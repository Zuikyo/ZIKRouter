# Module Registration

You have to override `registerRoutableDestination` in router to register your module's class and its protocol. All routers' `registerRoutableDestination` will be automatically called when app is launched.

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

When you create router and inject required dependencies for your own module, the user has to use this router and can't create another router. You can use `+registerExclusiveView:` to make an exclusive registration. Then other router can't register this view, or there will be an assert failure.

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

If your module contains multi components, and those components' dependencies can't be passed through destination, you need a module config protocol, and configure components' dependencies inside router.

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

```swift
var userInfo: [String : Any] = ... // Pass parameters in a dictionary
Router.to(viewIdentifier: "viewController-editor")?
	.perform(path: .push(from: self), configuring: { (config, _) in
    	config.addUserInfo(userInfo)
	})
```

We can't check type of parameters when passing in a dictionary, so it's not recommanded to use this method for most cases. You should only use this method when the module needs to support URL scheme. You can combine other URL router with ZIKRouter by identifier matching.

## Auto Registration

When app is launched, ZIKRouter will enumerate all classes and call router's `registerRoutableDestination` method.

Enumerating all classes is optimized very fast, you don't need to worry about the performance. If your modules are more than 2000, you can try manually registration. The performance of auto registration is almost the same.
The difference is you can register part of modules in groups, but not register all modules at same time.
## Manually Registration

Manually registration means calling each router's `registerRoutableDestination` manually.

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

Then you can register each router:

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

You can use this functions to generate code for importing router headers and registering routers:

```swift
import ZIKRouter.Private

let importCode = codeForImportRouters()
let registeringCode = codeForRegisteringRouters()
```

```objectivec
@import ZIKRouter.Private;

NSString *importCode = codeForImportRouters();
NSString *registeringCode = codeForRegisteringRouters();
```

## Performance

You may worry about the performance of registration, the next tests will resolve your doubt.

### Auto Registration and Manually Registration

Here is the test of auto registration and manually registration:

* Test the time of 500, 1000, 2000, 5000 view controllers when auto registration and manually registration
* Register with `+registerExclusiveView:`and`+registerViewProtocol:`
* `ZIKRouter: register with blocks` means registering with `ZIKViewRoute`. It uses much less classes than using router subclasses, so it's a bit quicker, but it will cost more memorys.
* `ZIKRouter: register with subclass` means registering with router subclasses
* `ZRouter: register with string` means declaring and registering routable pure swift protocols with `init(declaredTypeName:)`. The performance of ZRouter is slightly worse than ZIKRouter, bacause ZRouter needs to support both objc protocols and pure swift protocols.

<p align="center">
  <img src="../Resources/Auto-register-manually-register-500.png" width="70%">
</p>

<p align="center">
  <img src="../Resources/Auto-register-manually-register-1000.png" width="70%">
</p>

<p align="center">
  <img src="../Resources/Auto-register-manually-register-2000.png" width="70%">
</p>

<p align="center">
  <img src="../Resources/Auto-register-manually-register-5000.png" width="70%">
</p>

There is no performance problem in 64 bit devices. In 32 bit devices like iPhone 5, most time is costed in objc method invocations. The time is almost the same even we replace registration methods with empty methods that do nothing.

If your project needs to support 32 bit device, and your modules are more than 1000, you can use manually registration. But you will not use manually registration in most of the time, because even in Wechat app, there are only about 700 hundred view controllers.

### Performance with other frameworks

Here is the performance with other frameworks:

* Test the time of 500, 1000, 2000, 5000 view controllers when auto registration and manually registration
* Register with `+registerExclusiveView:`and`+registerViewProtocol:`
* `ZRouter: register with type` means declaring and registering routable pure swift protocols with `init(declaredProtocol:)`
* Registering urls for other URL routers in a format like `/user/TestViewControllerxxx/:userID`

<p align="center">
  <img src="../Resources/Registration-performance-500.jpg" width="90%">
</p>

<p align="center">
  <img src="../Resources/Registration-performance-1000.jpg" width="90%">
</p>

<p align="center">
  <img src="../Resources/Registration-performance-2000.jpg" width="90%">
</p>

<p align="center">
  <img src="../Resources/Registration-performance-5000.jpg" width="90%">
</p>

Result:

* The best is `routable-ios` and `JLRoutes`, than ZIKRouter and ZRouter
* MGJRouter and HHRouter will processing the url string when registering, so there are a little performance costs.
* In Swift, the performances of `ZRouter: register with type` and Swinject  are much worse than others, because they use `String(describing:)` to convert swift type to string, and `String(describing:)` has poor performance
* Using `Zrouter: register with string` can easily and highly improve the performance, because it avoid using `String(describing:)`

So, my conclusion is: you don't need to worry about the performance of registration.

---
#### Next section: [Routable Declaration](./RoutableDeclaration.md)