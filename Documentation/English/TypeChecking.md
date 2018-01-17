# Type Checking

ZIKRouter checks and limits the routing to make dynamic routing safer. The  principle:

* Only routable protocol can be used for routing, or there will be complie errors
* If a protocol is routable, there must be a router for it

## Compile-Time Checking

#### Swift

In Swift, use conditional extension to declare routable protocol, and let the complier to check illegal use.

See[Routable Declaration](RoutableDeclaration.md#Routable).

#### Objective-C

In Objective-C, you need to make Compile-Time Checking by your own.

First, write a function to get router like this:

```objectivec
Class ViewRouterToView(Protocol<ZIKViewRoutable> *viewProtocol);
```

When you pass a protocol to `ViewRouterToView`, there will be a complie warning`Incompatible pointer types passing 'Protocol *' to parameter of type 'Protocol<ZIKViewRoutable> *'`:

```
Class viewRouterClass = ViewRouterToView(@protocol(EditorViewInput));
```
You can add `-Werror=incompatible-pointer-types` to your project's `Build Settings->Other C Flags`, to change warning to error.

Then, if the protocol is routable, make a Type Cast for it:

```
#define RoutableView_EditorViewInput (Protocol<ZIKViewRoutable> *)@protocol(EditorViewInput)
```

Now you can use the protocol without warning

```
Class viewRouterClass = ViewRouterToView(RoutableView_EditorViewInput);
```

## Runtime Checking

After auto registration is finished, ZIKRouter will check:

* All routers were registered with at least one destination class
* All protocols inheriting from `ZIKViewRoutable`,`ZIKViewModuleRoutable`,`ZIKServiceRoutable`,`ZIKServiceModuleRoutable` were registered with at least one router
* If router is registered with a protocol, the router's destination or configuration must conforms to the protocol
* Even for a Swift type, ZIKRouter can also check it conformance with dynamic protocol types

Shortcomings:

In Objective-C, we can enuemrate protocols to do checking. But pure Swift protocols can't be enumerated with runtime. So you need to do manually checking:

```swift
class SwiftSampleViewRouter: ZIKAnyViewRouter {
    ...
    override class func _autoRegistrationDidFinished() {
        //Make sure all routable dependencies in this module is available.
        assert((Router.to(RoutableService<SwiftServiceInput>()) != nil))
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
        Registry.register(RoutableView<PureSwiftSampleViewInput>(), forRouter: self)
        Registry.register(RoutableViewModule<SwiftSampleViewConfig>(), forRouter: self)
    }
    
    override class func defaultRouteConfiguration() -> SwiftSampleViewConfiguration {
        return SwiftSampleViewConfiguration()
    }
    
    override func destination(with configuration: SwiftSampleViewConfiguration) -> SwiftSampleViewController? {
        let sb = UIStoryboard.init(name: "Main", bundle: nil)
        let destination = sb.instantiateViewController(withIdentifier: "SwiftSampleViewController") as! SwiftSampleViewController
        return destination
    }
    
    override static func destinationPrepared(_ destination: SwiftSampleViewController) -> Bool {
        if (destination.injectedAlertRouter != nil) {
            return true
        }
        return false
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

Custom Swift generic doesn't support covariance and contravariance. So a `ZIKViewRouter<UIViewController, ViewRouteConfig>` type is not a `ZIKViewRouter<AnyObject, ViewRouteConfig>` type, there will be complie error if you assign one type to another. Therefore, we use `ViewRouter` and `ServiceRouter` to wrap `ZIKViewRouter` and `ZIKServiceRouter`.

Only one generic parameter will be set for each router. You can use convenient types like `DestinationViewRouter`,`DestinationServiceRouter`,`ModuleViewRouter`,`ModuleServiceRouter`. `ViewRouter<NoteEditorInput, ViewRouteConfig>` can be replaced with `DestinationViewRouter<NoteEditorInput>`.

When the router uses a module config protocol, the destination type can't be designated in generic parameter. If you wan't to designated destination type, you should return the destination in module config protocol's interface.