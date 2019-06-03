# 设计思路

## 基本架构

<p align="center">
  <img src="../Resources/ArchitecturePreview.png" width="100%">
  数据流向图
</p>

## 设计特点

ZIKRouter 使用接口管理和使用模块。设计特色：

* 无需修改模块的代码即可让模块路由化，最大程度地减少模块化的成本
* 依赖编译检查，实现严格的类型安全，减少重构时的成本
* 进行路由检查，编译时即可避免使用不存在的路由模块，减少维护的成本
* 通过接口检查，保证模块正确实现所提供的接口
* 通过接口明确声明模块所需的依赖，允许外部进行依赖注入
* 利用接口，区分 required protocol 和 provided protocol，进行明确的模块适配，实现彻底解耦，即便模块间有互相依赖，也可以做到单独编译

使用 ZIKRouter 来管理模块，可以充分发挥编译检查的功能，做到动态化和安全性兼得。

## 路由工具对比

相比其他路由工具和模块管理工具，ZIKRouter 有什么优势？

### URL Router

ZIKRouter 实现了基于接口的模块管理方式，而大部分路由工具都是基于 URL 实现的。

代码示例：

```objective-c
// 注册某个URL
[URLRouter registerURL:@"app://editor" handler:^(NSDictionary *param) {
    UIViewController *editorViewController = [[EditorViewController alloc] initWithParam:param];
    return editorViewController;
}];
```

```objective-c
// 调用路由
[URLRouter openURL:@"app://editor/?debug=true" completion:^(NSDictionary *info) {

}];
```

URL router 的优点：

* 极高的动态性
* 方便地统一管理多平台的路由规则
* 易于适配 URL Scheme

URL router 的缺点：

* 传参方式有限，并且无法利用编译器进行参数类型检查
* 只适用于界面模块，不适用于通用模块
* 不能使用 designated initializer 声明必需参数
* 要让 view controller 支持 url，需要为其新增初始化方法，因此需要对模块做出修改
* 不支持 storyboard
* 无法明确声明模块提供的接口，只能依赖于接口文档，重构时无法确保修改正确
* 依赖于字符串硬编码，难以管理
* 无法保证所使用的模块一定存在
* 解耦能力有限，url 的注册、实现、使用必须用相同的字符规则，一旦任何一方做出修改都会导致其他方的代码失效（无法区分 required protocol 和 provided protocol，因此无法彻底解耦）

#### 代表框架

* [routable-ios](https://github.com/clayallsopp/routable-ios)
* [JLRoutes](https://github.com/joeldev/JLRoutes)
* [MGJRouter](https://github.com/meili/MGJRouter)
* [HHRouter](https://github.com/lightory/HHRouter)

#### ZIKRouter 的改进

通过接口管理模块，有效避免了 URL router 的缺点。参数可以通过 protocol 直接传递，能够利用编译器检查参数类型，并且 ZIKRouter 能通过路由声明和编译检查，保证所使用的模块一定存在。在为模块创建路由时，也无需修改模块的代码。

同时 ZIKRouter 可以通过字符串匹配 router，因此可以轻易地和其他 URL router 对接。

### 基于反射的模块管理工具

有一些模块管理工具基于 Objective-C 的 runtime、category 特性动态获取模块。例如通过`NSClassFromString`获取类并创建实例，通过`performSelector:` `NSInvocation`动态调用方法。

例如基于 target-action 模式的设计，大致是利用 category 为路由工具添加新接口，在接口中通过字符串获取对应的类，再用 runtime 创建实例，动态调用实例的方法。

示例代码：

```objective-c
// 模块管理者，提供了动态调用 target-action 的基本功能
@interface Mediator : NSObject

+ (instancetype)sharedInstance;

- (id)performTarget:(NSString *)targetName action:(NSString *)actionName params:(NSDictionary *)params;

@end
```

```objective-c
// 模块调用者在 category 中定义新接口
@interface Mediator (ModuleActions)
- (UIViewController *)Mediator_editorViewController;
@end

@implementation Mediator (ModuleActions)

- (UIViewController *)Mediator_editorViewController {
    // 使用字符串硬编码，通过 runtime 动态创建 Target_Editor，并调用 Action_viewController:
    UIViewController *viewController = [self performTarget:@"Editor" action:@"viewController" params:@{@"key":@"value"}];
    return viewController;
}

@end
  
// 调用者通过 Mediator 的接口调用模块
UIViewController *editor = [[Mediator sharedInstance] Mediator_editorViewController];
```

```objective-c
// 模块提供者提供 target-action 的调用方式
@interface Target_Editor : NSObject
- (UIViewController *)Action_viewController:(NSDictionary *)params;
@end

@implementation Target_Editor

- (UIViewController *)Action_viewController:(NSDictionary *)params {
    // 参数通过字典传递，无法保证类型安全
    EditorViewController *viewController = [[EditorViewController alloc] init];
    viewController.valueLabel.text = params[@"key"];
    return viewController;
}

@end
```

优点：

* 利用 category 可以明确声明接口，进行编译检查
* 实现方式轻量

缺点：

* 在 category 中仍然引入了字符串硬编码
* 无法保证所使用的模块一定存在
* 无法区分 required protocol 和 provided protocol，因此无法彻底解耦
* 过于依赖 runtime 特性，无法应用到纯 swift 上
* 使用 runtime 相关的接口调用任意类的任意方法，有被苹果审核拒绝的风险，需要注意别被苹果的审核误伤。参考：[Are performSelector and respondsToSelector banned by App Store?
  ](https://stackoverflow.com/questions/42662028/are-performselector-and-respondstoselector-banned-by-app-store)

#### 代表框架

[CTMediator](https://github.com/casatwy/CTMediator)

#### ZIKRouter 的改进

ZIKRouter 避免使用 runtime 获取和调用模块，因此可以适配 OC 和 swift。同时，基于 protocol 匹配的方式，避免引入字符串硬编码，能够更好地管理模块。

### 基于 protocol 匹配的模块管理工具

有一些模块管理工具或者依赖注入工具，也实现了基于接口的管理方式。实现思路是将 protocol 和对应的类进行字典匹配，之后就可以用 protocol 获取 class，再动态创建实例。

BeeHive 示例代码：

```objective-c
// 注册模块 (protocol-class 匹配)
[[BeeHive shareInstance] registerService:@protocol(EditorViewProtocol) service:[EditorViewController class]];
```

```objective-c
// 获取模块 (用 runtime 创建 EditorViewController 实例)
id<EditorServiceProtocol> editor = [[BeeHive shareInstance] createService:@protocol(EditorServiceProtocol)];
```

Swinject 示例代码：

```swift
let container = Container()

// 注册模块
container.register(EditorViewProtocol.self) { _ in
    EditorViewController()
}
// 获取模块
let editor = container.resolve(EditorViewProtocol.self)!
```

优点：

- 利用接口调用，实现了参数传递时的类型安全

缺点：

- 由框架来创建所有对象，创建方式有限，例如不支持外部传入参数，再调用自定义初始化方法
- 用 OC runtime 创建对象，不支持 Swift
- 只做了 protocol 和 class 的匹配，不支持更复杂的创建方式和依赖注入
- 无法保证所使用的 protocol 一定存在对应的模块，也无法直接判断某个 protocol 是否能用于获取模块

#### 代表框架

[BeeHive](https://github.com/alibaba/BeeHive)

[Swinject](https://github.com/Swinject/Swinject)

#### ZIKRouter 的改进

BeeHive 这种方式和 ZIKRouter 的思路类似，但是不支持纯 Swift 类型，不支持使用自定义初始化方法以及详细的依赖注入。 ZIKRouter 进行了进一步的改进，并不是直接对 protocol 和 class 进行匹配，而是将 protocol 和 router 子类进行匹配，在 router 子类中再提供创建模块的实例的方式。

加了一层 router 中间层之后，解耦能力一下子就增强了：

* 可以让多个 protocol 和同一个模块进行匹配
* 可以让模块进行接口适配，允许外部做完适配后，为 router 添加新的 protocol，解决编译依赖的问题
* 在 router 子类中可以进行更详细的依赖注入和自定义操作，也能进行更自由的扩展
* 可以自定义创建对象的方式，例如自定义初始化方法、工厂方法，在重构时可以直接搬运现有的创建代码
* 可以根据条件，返回不同的对象，例如适配不同系统版本时，返回不同的控件，让外部只关注接口

同时，ZIKRouter 也限制了路由的动态特性，只能使用经过声明的 protocol，在编译阶段就能防止使用不存在的模块。这是 ZIKRouter 最有特色的功能。

通过实现以下两个原则，保障了动态模块的确定性：

- 只有被声明为可路由的 protocol 才能用于路由，否则会产生编译错误
- 可路由的 protocol 必定有一个对应的模块存在

## 架构图

![详细架构](../Resources/Architecture.png)

## 博客详解

更详细的讲解，可以阅读这三篇博客：

[iOS VIPER架构实践(一)：从MVC到MVVM到VIPER](https://zuikyo.github.io/2017/07/21/iOS%20VIPER架构实践(一)：从MVC到MVVM到VIPER/)

[iOS VIPER架构实践(二)：VIPER详解与实现](https://zuikyo.github.io/2017/08/11/iOS%20VIPER架构实践(二)：VIPER详解与实现/)

[iOS VIPER架构实践(三)：面向接口的路由设计](https://zuikyo.github.io/2017/09/27/iOS%20VIPER架构实践(三)：基于接口的路由设计/)