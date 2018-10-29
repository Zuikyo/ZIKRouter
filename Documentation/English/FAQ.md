# FAQ

### Should all protocols be put in a public module?

Centrally putting all routable protocols in a public module is the most direct  way to provide them. But it's not easy to maintain them. And you may import those unused protocols.

Protocols used by ZIKRouter are explicitly declared as routable. You can use multi protocols for a same module. So those protocols can be managed discretely. Then you don't have to put them in a same public module.

### How to get all routable protocols?

Protocols are all declared in headers. You can search these declaration code:

`extension RoutableView where Protocol ==`

`extension RoutableViewModule where Protocol ==`

`extension RoutableService where Protocol ==`

`extension RoutableServiceModule where Protocol ==`

`@protocol ... <ZIKViewRoutable>`

`@protocol ... <ZIKViewModuleRoutable>`

`@protocol ... <ZIKServiceRoutable>`

`@protocol ... <ZIKServiceModuleRoutable>`

You can also get all protocols by runtime methods.

If you are using swift, Xcode will auto list all routable protocol:

![Xcode Auto Completion](../Resources/route-auto-completion.png)

There're compile-time check when routing with protocols, so you won't use any undeclared protocols.

### What's required protocol and provided protocol？

`required protocol` is the protocol used by the module's user. `provided protocol` is the real protocol provided by the module. One `provided protocol` can has multi `required protocol`.

### Why separating required protocol and provided protocol?

* Module and module's user are isolated in code. Separating their protocols can decouple them thoroughly
* The provided module can be replaced with any other module that can be adapted with the required protocol. The modules' manager (app context) is responsible for adapting required protocol and provided protocol
* A module can declare its required protocols to explicitly declare its dependencies. Then it's much easier to provide mocked dependencies in unit test, without importing any third-party modules

### Can required protocol and provided protocol provide different interface?

Methods in required protocol and provided protocol can be different, as long as they provide same function. You can adapt required protocol and provided protocol with category, extension, proxy and subclass.

In most case, the required protocol is same as the provided protocol, but just change a name.

### What's adapter?

ZIKViewRouteAdapter and ZIKServiceRouteAdapter are just for registering required protocol for other router. You still need to add required protocol for the provided module.

### Where to put code for adapters?

Adapters exist in app context. Modules don't know those adapters. You can put them in a same adapter file, or in different adapter classes.

### What's the different between ZRouter and ZIKRouter?

ZRouter encapsulates ZIKRouter, provides swifty methods for swift, and supports swift class and swift protocol.

### Does ZIKRouter support swift value type?

NO. ZIKRouter only supports class type. Value type should not be used in different modules. If you really want to manage value types, you can provide value types with a value type factory protocol.

### How to declare protocol with class at same time?

In swift, you can declare composed protocol:

```swift
typealias ViewControllerInput = UIViewController & ControllerInput

extension RoutableView where Protocol == ViewControllerInput {
    init() { self.init(declaredProtocol: Protocol.self) }
}
```

When fetching router with `ViewControllerInput`, you can get a `UIViewController` conforming to `ControllerInput`.

But we can't declare this in Objective-C.

### How to use the destination after performing route?

The router only keep week reference to the destination after performing route. You need to hold the destination if you want to use it later.

```swift
class TestViewController: UIViewController {
	var mySubview: MySubviewInput?
	
	func addMySubview() {
        Router.perform(
        to: RoutableView<MySubviewInput>(),
        path: .addAsSubview(from: self.view),
        configuring: { (config, _) in
            config.successHandler = { destination in
                self.mySubview = destination
            }
    	 })
	}
}
```

<details><summary>Objective-C Sample</summary>
  
```objectivec
@interface TestViewController: UIViewController
@property (nonatomic, strong) UIView<MySubviewInput> *mySubview;
@end
@implementation TestViewController

- (void)addMySubview {
    [ZIKRouterToView(MySubviewInput) performPath:ZIKViewRoutePath.addAsSubviewFrom(self.view) configuring:^(ZIKViewRouteConfiguration *config) {
        config.successHandler = ^(id<MySubviewInput> destination) {
            self.mySubview = destination;
        };
    }];
}

@end
```

</details>

### How to handle route error?

In general, route errors appear in development stage. Errors are caused by:

* Errors from UIKit when showing view controller, such as pushing a view controller when there is no navigationController
* Pass wrong parameters or miss parameters when routing, so the router make this routing failed

You should solve route errors in development stage. You can track all errors in `globalErrorHandler`.

### How to handle non-existent routing?

You may use non-existent url in URL router, and you can provide a default error view controller in this situation.

But with ZIKRouter, you won't use wrong protocol when routing. You only need to check whether the router exists when fetching router with identifier. If the router is nil, you can use a default router to perform this route.