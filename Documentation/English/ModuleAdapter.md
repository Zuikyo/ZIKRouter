# Module Adapter

If you don't want to depend same protocol in module and module's user, use adapter to make totally decouple.

## `Provided protocol` and `Required protocol`

A router can register with multi protocols. The protocol provided by module itself is the `provided protocol`. The protocol used inside the module's user is the `required protocol`。

See `Required Interface` and `Provided Interface` in component diagrams[component diagrams](http://www.uml-diagrams.org/component-diagrams.html):

![component diagrams](http://upload-images.jianshu.io/upload_images/5879294-6309bffe07ebf178.png?imageMogr2/auto-orient/strip%7CimageView2/2)

Read [VIPER architecture](https://github.com/Zuikyo/ZIKViper) to get more details about implementing `Required Interface` and `Provided Interface`.

App Context is responsible for adapting interfaces. The module's user uses `Required Interface`, and the adapter forwards `Required Interface` to `Provided Interface`.

## Add `Required Interface` for module

Add `required protocol` for module with category and extension in app context.

For example, a module A needs to show a login view, and the login view can display a custom tip.

Module A:

```swift
protocol ModuleARequiredLoginViewInput {
  var message: String? { get set } //Message displayed on login view
}
//Show login view in module A
Router.perform(
    to RoutableView<ModuleARequiredLoginViewInput>(),
    path: .presentModally(from: self)
    configuring { (config, _) in
        config.prepareDestination = { destination in
            destination.message = "Please login to read this note"
        }
    })
```
<details><summary>Objective-C Sample</summary>

```objectivec
@protocol ModuleARequiredLoginViewInput <ZIKViewRoutable>
@property (nonatomic, copy) NSString *message;
@end

//Show login view in module A
[ZIKRouterToView(ModuleARequiredLoginViewInput)
	          performPath:ZIKViewRoutePath.presentModallyFrom(self)
	          configuring:^(ZIKViewRouteConfiguration *config) {
	              config.prepareDestination = ^(id<ModuleARequiredLoginViewInput> destination) {
	                  destination.message = @"Please login to read this note";
	              };
	          }];
```
</details>

`ZIKViewAdapter` and `ZIKServiceAdapter` are responsible for registering protocols for other router.

Make login view support `ModuleARequiredLoginViewInput`:

```swift
//Login Module Provided Interface
protocol ProvidedLoginViewInput {
   var notifyString: String? { get set }
}
```
```swift
//Write in app context, make ZIKEditorViewRouter supports ModuleARequiredLoginViewInput
class LoginViewAdapter: ZIKViewRouteAdapter {
    override class func registerRoutableDestination() {
        //If you can get the router, you can just register ModuleARequiredLoginViewInput to it
        ZIKEditorViewRouter.register(RoutableView<ModuleARequiredLoginViewInput>())
        //If you don't know the router, you can use adapter
        register(adapter: RoutableView<ModuleARequiredLoginViewInput>(), forAdaptee: RoutableView<ProvidedLoginViewInput>())
    }
}

extension LoginViewController: ModuleARequiredLoginViewInput {
    var message: String? {
        get {
            return notifyString
        }
        set {
            notifyString = newValue
        }
    }
}
```
<details><summary>Objective-C Sample</summary>

```objectivec
//Login Module Provided Interface
@protocol ProvidedLoginViewInput <NSObject>
@property (nonatomic, copy) NSString *notifyString;
@end
```
```objectivec
//LoginViewAdapter.h
@interface LoginViewAdapter : ZIKViewRouteAdapter
@end

//LoginViewAdapter.m
@implementation LoginViewAdapter

+ (void)registerRoutableDestination {
	//If you can get the router, you can just register ModuleARequiredLoginViewInput to it
	[ZIKEditorViewRouter registerViewProtocol:ZIKRoutable(ModuleARequiredLoginViewInput)];
	//If you don't know the router, you can use adapter
	[self registerDestinationAdapter:ZIKRoutable(ModuleARequiredLoginViewInput) forAdaptee:ZIKRoutable(ProvidedLoginViewInput)];
}

@end

//Make LoginViewController support ModuleARequiredLoginViewInput
@interface LoginViewController (ModuleAAdapter) <ModuleARequiredLoginViewInput>
@property (nonatomic, copy) NSString *message;
@end
@implementation LoginViewController (ModuleAAdapter)
- (void)setMessage:(NSString *)message {
	self.notifyString = message;
}
- (NSString *)message {
	return self.notifyString;
}
@end
```
</details>

## Forward Interface with Proxy

If you can't add `required protocol` for module, for example, the delegate type in protocol is different:

```swift
protocol ModuleARequiredLoginViewDelegate {
    func didFinishLogin() -> Void
}
protocol ModuleARequiredLoginViewInput {
  var message: String? { get set }
  var delegate: ModuleARequiredLoginViewDelegate { get set }
}
```
<details><summary>Objective-C Sample</summary>

```objectivec
@protocol ModuleARequiredLoginViewDelegate <NSObject>
- (void)didFinishLogin;
@end

@protocol ModuleARequiredLoginViewInput <ZIKViewRoutable>
@property (nonatomic, copy) NSString *message;
@property (nonatomic, weak) id<ModuleARequiredLoginViewDelegate> delegate;
@end
```
</details>

Delegate is different in provided module:

```swift
protocol ProvidedLoginViewDelegate {
    func didLogin() -> Void
}
protocol ProvidedLoginViewInput {
  var notifyString: String? { get set }
  var delegate: ProvidedLoginViewDelegate { get set }
}
```
<details><summary>Objective-C Sample</summary>

```objectivec
@protocol ProvidedLoginViewDelegate <NSObject>
- (void)didLogin;
@end

@protocol ProvidedLoginViewInput <NSObject>
@property (nonatomic, copy) NSString *notifyString;
@property (nonatomic, weak) id<ProvidedLoginViewDelegate> delegate;
@end
```
</details>

In this situation, you can create a new router to forward the real router, and return a proxy for the real destination:

```swift
class ModuleAReqiredEditorViewRouter: ZIKViewRouter {
   override class func registerRoutableDestination() {
       registerView(/*proxy class*/)
       register(RoutableView<ModuleARequiredLoginViewInput>())
   }
   override func destination(with configuration: ZIKViewRouteConfiguration) -> ModuleARequiredLoginViewInput? {
       //Get real destination with ProvidedLoginViewInput's router
       let realDestination: ProvidedLoginViewInput = ZIKEditorViewRouter.makeDestination()
       //Proxy is responsible for forwarding ModuleARequiredLoginViewInput to ProvidedLoginViewInput
       let proxy: ModuleARequiredLoginViewInput = ProxyForDestination(realDestination)
       return proxy
   }
}

```
<details><summary>Objective-C Sample</summary>

```objectivec
@implementation ZIKModuleARequiredEditorViewRouter
+ (void)registerRoutableDestination {
	//Register ModuleARequiredLoginViewInput with ZIKModuleARequiredEditorViewRouter
	[self registerView:/* proxy class*/];
	[self registerViewProtocol:ZIKRoutable(NoteListRequiredNoteEditorProtocol)];
}
- (id)destinationWithConfiguration:(ZIKViewRouteConfiguration *)configuration {
   //Get real destination with ProvidedLoginViewDelegate's router
   id<ProvidedLoginViewInput> realDestination = [ZIKEditorViewRouter makeDestination];
    //Proxy is responsible for forwarding ModuleARequiredLoginViewInput to ProvidedLoginViewInput
    id<ModuleARequiredLoginViewInput> proxy = ProxyForDestination(realDestination);
    return proxy;
}
@end
```
</details>

For simple objc classes, you can use NSProxy to create a proxy. For those complex classes such as UIViewController in UIKit, you can subclass the UIViewController, and override methods to adapt interface.

You don't have to always separate `requiredProtocol` and `providedProtocol`. It's ok to use the same protocol in module and its user. Change it only when you need it.