# Type Checking

ZIKRouter checks and limits the routing to make dynamic routing safer. The  principle:

* Only routable protocol can be used for routing, or there will be complie errors
* If a protocol is routable, there must be a router for it

## Compile-Time Checking

#### Swift

In Swift, use conditional extension to declare routable protocol, and let the compiler to check illegal usage.

See [Routable Declaration](RoutableDeclaration.md#Routable).

#### Objective-C

In Objective-C, we use generic and macros to make compile time checking.

When registering and getting router with protocol, use macro `ZIKRoutable` to wrap the protocol:

```objectivec
@implementation EditorViewRouter

+ (void)registerRoutableDestination {
    [self registerView:[EditorViewController class]];
    
    //If the protocol is not inherited from ZIKViewRoutable, there will be compile warning
    [self registerViewProtocol:ZIKRoutable(NoteEditorInput)];
}

@end
```

Use macro `ZIKRouterToView`, `ZIKRouterToViewModule`, `ZIKRouterToService`, `ZIKRouterToServiceModule` to get router class:

```objectivec
//If the protocol doesn't inherit from ZIKViewRoutable, there will be compile warning:
//'incompatible pointer types passing 'Protocol<UndeclaredProtocol> *' to parameter of type 'Protocol<ZIKViewRoutable> *'
ZIKRouterToView(UndeclaredProtocol)
```

You can set`Build Settings`->`Treat Incompatible Pointer Type Warnings as Errors`to YES.

And the protocol type will affect the parameters in methods:

```objectivec
//The 3 parameters have inheritance relationship
[ZIKRouterToView(NoteEditorInput) //1
     performPath:ZIKViewRoutePath.pushFrom(self)
     strictConfiguring:^(ZIKViewRouteStrictConfiguration<id<NoteEditorInput>> *config, //2
                         ZIKViewRouteConfiguration *module) {
         config.prepareDestination = ^(id<NoteEditorInput> destination) { //3
         	   destination.delegate = weakSelf;
             destination.name = @"zuik";
             destination.age = 18;
         }
     }];
```

It's not 100% perfect like in Swift. If the protocol is changed to parent protocol, the compiler won't give any errors.

## Runtime Checking

After auto registration is finished, ZIKRouter will check:

* All routers were registered with at least one destination class
* All protocols inheriting from `ZIKViewRoutable`,`ZIKViewModuleRoutable`,`ZIKServiceRoutable`,`ZIKServiceModuleRoutable` were registered with at least one router
* All swift protocols declared in extensions of `RoutableView`, `RoutableViewModule`, `RoutableService`, `RoutableServiceModule` were registered with at least one router
* If router is registered with a protocol, the router's destination or configuration must conforms to the protocol
* Even for a Swift type, ZIKRouter can also check it conformance with dynamic protocol types

For dynamically checking swift types, ZIKRouter uses private APIs in `libswiftCore.dylib`, and these code won't be compiled in release mode.

You can also do custom checking. In DEBUG mode, all routers' `+_didFinishRegistration` will be invoked when all registrations are finished. You can do custom checking here:

```swift
class SwiftSampleViewRouter: ZIKAnyViewRouter {
    ...
    override class func _didFinishRegistration() {
        // Custom checking
    }
    ...
}

```

## Generic Parameter

The router subclass can set generic parameters when inheriting from ZIKViewRouter. There two generic parameters: `Destination` and `RouteConfig`.

```swift
class SwiftSampleViewRouter: ZIKViewRouter<SwiftSampleViewController, SwiftSampleViewConfiguration> {
    
    override class func registerRoutableDestination() {
        registerView(SwiftSampleViewController.self)
        register(RoutableView<PureSwiftSampleViewInput>())
        register(RoutableViewModule<SwiftSampleViewConfig>())
    }
    
    override class func defaultRouteConfiguration() -> SwiftSampleViewConfiguration {
        return SwiftSampleViewConfiguration()
    }
    
    override func destination(with configuration: SwiftSampleViewConfiguration) -> SwiftSampleViewController? {
        let sb = UIStoryboard.init(name: "Main", bundle: nil)
        let destination = sb.instantiateViewController(withIdentifier: "SwiftSampleViewController") as! SwiftSampleViewController
        return destination
    }
    
    override func prepareDestination(_ destination: SwiftSampleViewController, configuration: ZIKViewRouteConfiguration) {
        destination.injectedAlertRouter = Router.to(RoutableViewModule<ZIKCompatibleAlertConfigProtocol>())
    }
}
```

Generic parameters are just for indicating parameter type when overriding methods. So the generic parameters can be different from router's real destination or protocol.

### Destination

`Destination` is type of router's destination.

### RouteConfig

RouteConfig is type of router's configuration. You can use a custom type when using module config protocol.

### Usage of Generic Parameters

Custom Swift generic doesn't support covariance and contravariance. So a `ZIKViewRouter<UIViewController, ViewRouteConfig>` type is not a `ZIKViewRouter<AnyObject, ViewRouteConfig>` type, there will be complie error if you assign one type to another. And OC class's generic parameters can't be pure swift types, therefore, we use `ViewRouter` and `ServiceRouter` to wrap `ZIKViewRouter` and `ZIKServiceRouter`, to support pure swift types.

Only one generic parameter will be set for each router. You can use convenient types like `DestinationViewRouter`,`DestinationServiceRouter`,`ModuleViewRouter`,`ModuleServiceRouter`. `ViewRouter<NoteEditorInput, ViewRouteConfig>` can be replaced with `DestinationViewRouter<NoteEditorInput>`.

When the router uses a module config protocol, the destination type can't be designated in generic parameter. If you wan't to designated destination type, you should return the destination in module config protocol's interface.

---
#### Next section：[Perform Route](./PerformRoute.md)