# Type Checking

ZIKRouter 对路由进行了安全检查和使用限制，能够最大程度地消除动态特性带来的隐患。通过实现以下两个机制进行安全保障：

* 只有被声明为可路由的 protocol 才能用于路由，否则会产生编译错误
* 可路由的 protocol 必定有一个对应的模块存在

## 编译检查

#### Swift

Swift 中，用条件 extension 来声明可路由的 protocol，从而利用编译器检查非法 protocol 的使用。

具体见 [Routable Declaration](RoutableDeclaration.md#Routable)。

#### Objective-C

在 Objective-C 中，使用泛型和宏定义制造编译检查。

在注册 protocol 和获取 router 类时，用`ZIKRoutable`包裹 protocol：

```objectivec
@implementation EditorViewRouter

+ (void)registerRoutableDestination {
    [self registerView:[EditorViewController class]];
    
    //如果 protocol 不是继承自 ZIKViewRoutable，将会产生编译警告
    [self registerViewProtocol:ZIKRoutable(NoteEditorInput)];
}

@end
```

使用宏定义 `ZIKRouterToView`、`ZIKRouterToViewModule`、`ZIKRouterToService`、`ZIKRouterToServiceModule` 来获取router类：

```objectivec
//如果 protocol 不是继承自 ZIKViewRoutable，将会产生编译警告：
//'incompatible pointer types passing 'Protocol<UndeclaredProtocol> *' to parameter of type 'Protocol<ZIKViewRoutable> *'
ZIKRouterToView(UndeclaredProtocol)
```

你可以开启工程的`Build Settings`->`Treat Incompatible Pointer Type Warnings as Errors`，把编译警告变为编译错误。

在调用方法时，方法中的参数也会自动进行编译检查：

```objectivec
//3处地方的参数有继承关系
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

这里的编译检查并不像 Swift 中那样完美。编译器只会检查是否有继承关系，当参数变成了 parent protocol 时，并不会有编译错误。

## 动态检查

在自动注册完毕时，ZIKRouter 将会进行下列检查：

* 所有 router 子类都需要注册至少一个 view class 或者 service class
* 所有继承自`ZIKViewRoutable`、`ZIKViewModuleRoutable`、`ZIKServiceRoutable`、`ZIKServiceModuleRoutable`的 protocol，都至少注册给了一个 router
* 所有用 swift extension 声明了的 swift protocol，都至少注册给了一个 router
* 如果 router 注册了 protocol，检查 router 注册的 view、service 和 configuration 是否遵守所注册的 protocol
* 动态检查支持纯 Swift 类型，可以检查某个Swift类型是否遵守某个protocol

你也可以做一些自定义的检查。

在 DEBUG 模式下，注册结束时会调用所有 router 的 `+_didFinishRegistration`方法，你可以在这里做一些检查：

```swift
class SwiftSampleViewRouter: ZIKAnyViewRouter {
    ...
    override class func _didFinishRegistration() {
        // 自定义检查
    }
    ...
}

```

## 泛型

在创建 router 子类的时候，可以指定泛型参数，在重写父类方法时就能利用泛型指定参数类型。ZIKViewRouter 和 ZIKServiceRouter 有两个泛型参数：`Destination`、`RouteConfig`。

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

在创建 router 子类时，泛型只是用于辅助子类在重写父类方法时进行参数类型限制，因此并不要求泛型参数和注册的 destination 或者 protocol 一致。

### Destination 参数

Destination 是指 router 所管理的 destination 的类型。

### RouteConfig 参数

RouteConfig 是指 router 用于执行路由时的 configuration 类型。当使用自定义的ModuleConfig 时，可以指定。

### 泛型的使用

由于 swift 的自定义泛型不支持协变和逆变，因此不能把`ZIKViewRouter<UIViewController, ViewRouteConfig>`类型赋值给`ZIKViewRouter<AnyObject, ViewRouteConfig>`类型。并且 OC 类的泛型不支持纯 swift 类型，因此在 swift 里，用了另外的`ViewRouter`和`ServiceRouter`类来包裹`ZIKViewRouter`和`ZIKServiceRouter`，以支持纯 swift 类型。

两个泛型每次只会自定义一个。可以用`DestinationViewRouter`、`DestinationServiceRouter`、`ModuleViewRouter`、`ModuleServiceRouter`来指定一个泛型值，另一个用默认值。

例如`ViewRouter<NoteEditorInput, ViewRouteConfig>`可以简写为`DestinationViewRouter<NoteEditorInput>`。

当指定了 module config protocol 时，就不需要再指定 destination 的类型了。因为目前不支持同时用 module protocol 和 destination protocol 查找 router。如果需要返回指定的destination，则在 module config protocol 的接口里返回。

---
#### 下一节：[执行路由](./PerformRoute.md)