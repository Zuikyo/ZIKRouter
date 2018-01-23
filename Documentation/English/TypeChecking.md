# Type Checking

ZIKRouter checks and limits the routing to make dynamic routing safer. The  principle:

* Only routable protocol can be used for routing, or there will be complie errors
* If a protocol is routable, there must be a router for it

## Compile-Time Checking

#### Swift

In Swift, use conditional extension to declare routable protocol, and let the compiler to check illegal usage.

See [Routable Declaration](RoutableDeclaration.md#Routable).

#### Objective-C

In Objective-C, we use some fake classes and macros to make compile time checking.

When registering and getting router with protocol, use macro `ZIKRoutableProtocol` to wrap the protocol:

```objectivec
@implementation EditorViewRouter

+ (void)registerRoutableDestination {
    [self registerView:[EditorViewController class]];
    
    //If the protocol is not inherited from ZIKViewRoutable, there will be compile error
    [self registerViewProtocol:ZIKRoutableProtocol(NoteEditorInput)];
}

@end
```
```
//If the protocol is not inherited from ZIKViewRoutable, there will be compile error
ZIKViewRouter.classToView(ZIKRoutableProtocol(NoteEditorInput))
```

Use macro `ZIKViewRouterToView`, `ZIKViewRouterToModule`, `ZIKServiceRouterToService`, `ZIKServiceRouterToModule` to get router class:

```objectivec
//If the protocol is not inherited from ZIKViewRoutable, there will be compile error
ZIKViewRouterToView(NoteEditorInput)
```

And the protocol type will affect the parameters in methods:

```objectivec
//The 3 parameters have inheritance relationship
[ZIKViewRouterToView(NoteEditorInput) //1
     performFromSource:self
     routeConfiguring:^(ZIKViewRouteConfig *config,
                        void (^prepareDest)(void (^)(id<NoteEditorInput>)), //2
                        void (^prepareModule)(void (^)(ZIKViewRouteConfig *))) {
         config.routeType = ZIKViewRouteTypePush;
         prepareDest(^(id<NoteEditorInput> dest){ //3
             dest.delegate = weakSelf;
             dest.name = @"zuik";
             dest.age = 18;
         });
     }];

```

It's not 100% perfect like in Swift. If the protocol is changed to parent protocol, the compiler won't give any errors.

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
    override class func _registrationDidFinished() {
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