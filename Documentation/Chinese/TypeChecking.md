# Type Checking

ZIKRouter对路由进行了安全检查和使用限制，能够最大程度地消除动态特性带来的隐患。通过实现以下两个机制进行安全保障：

* 只有被声明为可路由的protocol才能用于路由，否则会产生编译错误
* 可路由的protocol必定有一个对应的模块存在

## 编译检查

#### Swift

Swift中，用条件extension来声明可路由的protocol，从而利用编译器检查非法protocol的使用。

具体见 [Routable Declaration](RoutableDeclaration.md#Routable)。

#### Objective-C

在Objective-C中，使用一些虚假类和宏定义制造编译检查。

在注册protocol和获取router类时，用`ZIKRoutableProtocol`包裹protocol：

```objectivec
@implementation EditorViewRouter

+ (void)registerRoutableDestination {
    [self registerView:[EditorViewController class]];
    
    //如果protocol不是继承自ZIKViewRoutable，将会编译错误
    [self registerViewProtocol:ZIKRoutableProtocol(NoteEditorInput)];
}

@end
```
```
//如果protocol不是继承自ZIKViewRoutable，将会编译错误
ZIKViewRouter.classToView(ZIKRoutableProtocol(NoteEditorInput))
```

使用宏定义 `ZIKViewRouterToView`、`ZIKViewRouterToModule`、`ZIKServiceRouterToService`、`ZIKServiceRouterToModule` 来获取router类：

```objectivec
//如果protocol不是继承自ZIKViewRoutable，将会编译错误
ZIKViewRouterToView(NoteEditorInput)
```

在调用方法时，方法中的参数也会自动进行编译检查：

```objectivec
//3处地方的参数有继承关系
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

这里的编译检查并不像Swift中那样完美。编译器只会检查是否有继承关系，当参数变成了parent protocol时，并不会有编译错误。

## 动态检查

在自动注册完毕时，ZIKRouter将会进行下列检查：

* 所有router子类都需要注册至少一个view class或者service class
* 所有继承自`ZIKViewRoutable`、`ZIKViewModuleRoutable`、`ZIKServiceRoutable`、`ZIKServiceModuleRoutable`的protocol，都至少注册给了一个router
* 如果router注册了protocol，检查router注册的view、service和configuration是否遵守所注册的protocol
* 动态检查支持纯Swift类型，可以检查某个Swift类型是否遵守某个protocol

不足之处：

Objective-C可以保证所有声明为routable的protocol都注册给了对应的router，但是在Swift中无法用runtime枚举所有纯Swift protocol进行检查，因此需要手动检查本模块中所使用的外部的依赖是否已经正确地注册:

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

## 泛型

在创建router子类的时候，可以指定泛型参数，在重写父类方法时就能利用泛型指定参数类型。ZIKViewRouter和ZIKServiceRouter有两个泛型参数：`Destination`、`RouteConfig`。

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

在创建router子类时，泛型只是用于辅助子类在重写父类方法时进行参数类型限制，因此并不要求泛型参数和注册的protocol一致。

### Destination参数

Destination是指router所管理的destination的类型。

### RouteConfig参数

RouteConfig是指router用于执行路由时的configuration类型。当使用自定义的ModuleConfig时，可以指定。

### 泛型的使用

由于swift的自定义泛型不支持协变和逆变，因此不能把`ZIKViewRouter<UIViewController, ViewRouteConfig>`类型赋值给`ZIKViewRouter<AnyObject, ViewRouteConfig>`类型。因此在swift里，用了另外的`ViewRouter`和`ServiceRouter`类来包裹`ZIKViewRouter`和`ZIKServiceRouter`。

两个泛型每次只会自定义一个。可以用`DestinationViewRouter`、`DestinationServiceRouter`、`ModuleViewRouter`、`ModuleServiceRouter`来指定一个泛型值，另一个用默认值。

例如`ViewRouter<NoteEditorInput, ViewRouteConfig>`可以简写为`DestinationViewRouter<NoteEditorInput>`。

当指定了module config protocol时，就不需要再指定destination的类型了。因为目前不支持同时用module protocol和destination protocol查找router。如果需要返回指定的destination，则在module config protocol的接口里返回。