<p align="center">
  <img src="../Resources/icon.png" width="33%">
</p>

# ZIKRouter

![](https://img.shields.io/cocoapods/p/ZIKRouter.svg?style=flat)
![](https://img.shields.io/badge/language-objectivec-blue.svg)
![ZIKRouter](https://img.shields.io/cocoapods/v/ZIKRouter.svg?style=flat)
![](https://img.shields.io/badge/language-swift-orange.svg)
![ZRouter](https://img.shields.io/cocoapods/v/ZRouter.svg?style=flat)
![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)
![license](https://img.shields.io/github/license/mashape/apistatus.svg)

一个用于模块间解耦和通信，基于接口进行模块管理和依赖注入的组件化路由工具。用多种方式最大程度地发挥编译检查的功能。

通过 protocol 寻找对应的模块，并用 protocol 进行依赖注入和模块通信。

Service Router 可以管理任意自定义模块。View Router 进一步封装了界面跳转。

`ZRouter`为 Swift 提供更加 Swifty、更加安全的路由方式。

---

## Features

- [x] 支持 Swift 和 Objective-C，以及两者混编
- [x] 支持 iOS、macOS、tvOS
- [x] 提供规范化的代码模板，一键生成代码
- [x] 支持界面路由和任意 OC 模块、swift 模块的路由，无需修改模块代码即可让其支持路由
- [x] 支持对模块进行静态依赖注入和动态依赖注入
- [x] **明确声明可用于路由的 protocol，进行编译时检查，使用未声明的 protocol 会产生编译错误。这是 ZIKRouter 最特别的功能之一**
- [x] **用 protocol 获取模块并传递参数，基于接口进行类型安全的交互**
- [x] **支持 URL 路由**
- [x] **使用 required protocol 和 provided protocol 指向同一个模块，解除 protocol 依赖，支持各模块独立编译**
- [x] **支持 storyboard，可以对从 segue 中跳转的界面自动执行依赖注入**
- [x] 用 adapter 对两个模块进行解耦和接口兼容
- [x] 封装 UIKit / AppKit 里的所有界面跳转方式，同时支持界面回退和自定义跳转
- [x] 完备的错误检查，可以检测界面跳转时的大部分问题
- [x] 支持界面跳转过程中的 AOP 回调
- [x] 检测界面跳转和移除时的内存泄露
- [x] 发送自定义事件给 router 处理
- [x] 高性能的自动注册方式，也支持手动注册
- [x] 支持多种路由实现方式： 强大的 router 子类、简单的工厂 block 和 C 函数
- [x] 高可扩展性，可以轻松地加入各种自定义功能

## 快速入门

1. [创建 Router](#1-创建-Router)
   1. [Router 子类](#11-Router-子类)
   2. [快捷注册](#12-快捷注册)
2. [声明 Routable 类型](#2-声明-Routable-类型)
3. [View Router](#View-Router)
   1. [直接跳转](#直接跳转)
   2. [跳转前进行配置](#跳转前进行配置)
   3. [Make Destination](#Make-Destination)
   4. [必需参数与特殊参数](#必需参数与特殊参数)
   5. [Perform on Destination](#Perform-on-Destination)
   6. [Prepare on Destination](#Prepare-on-Destination)
   7. [Remove](#Remove)
   8. [Adapter](#Adapter)
   9. [模块化](#模块化)
   10. [URL Router](#URL-Router)
   11. [其他功能](#其他功能)
4. [Service Router](#Service-Router)
5. [Demo 和实践](#Demo-和实践)
6. [代码模板](#代码模板)

## 文档目录

### 设计思路

[设计思路](DesignPhilosophy.md)

### Basics

1. [创建路由](RouterImplementation.md)
2. [模块注册](ModuleRegistration.md)
3. [Routable 声明](RoutableDeclaration.md)
4. [类型检查](TypeChecking.md)
5. [执行路由](PerformRoute.md)
6. [移除路由](RemoveRoute.md)
7. [自定义 configuration 传参](CustomConfiguration.md)

### Advanced Features

1. [错误检查](ErrorHandle.md)
2. [Storyboard 和自动注入](Storyboard.md)
3. [AOP](AOP.md)
4. [依赖注入](DependencyInjection.md)
5. [循环依赖问题](CircularDependencies.md)
6. [模块化和解耦](ModuleAdapter.md)
7. [单元测试](UnitTest.md)

[常见问题](FAQ.md)

## Requirements

* iOS 7.0+
* Swift 3.2+
* Xcode 9.0+

## Installation

### Cocoapods

可以用 Cocoapods 安装 ZIKRouter：

```
pod 'ZIKRouter', '>= 1.1.0'

# 或者只使用 ServiceRouter 子模块
pod 'ZIKRouter/ServiceRouter' , '>=1.1.0'
```

如果是 Swift 项目，则使用 ZRouter：

```
pod 'ZRouter', '>= 1.1.0'

# 或者只使用 ServiceRouter 子模块
pod 'ZRouter/ServiceRouter' , '>=1.1.0'
```

### Carthage

添加到 Cartfile 文件：

```
github "Zuikyo/ZIKRouter" >= 1.1.0
```

编译 framework：

```
carthage update
```

编译 DEBUG 版本，开启运行时路由检查：

```
carthage update --configuration Debug
```
记得不要把 debug 版本的库用在 release 版本的 app 中。一定要在 release 版本的 app 中使用 release 版本的库。

对于 Objective-C 的项目，使用 `ZIKRouter.framework`。对于 Swift 项目，使用`ZRouter.framework`。

## Getting Started

下面演示 router 的基本使用。演示用的界面和 protocol:

```swift
///Editor 模块的接口和依赖
protocol EditorViewInput: class {
    weak var delegate: EditorDelegate? { get set }
    func constructForCreatingNewNote()
}

///Editor view controller
class NoteEditorViewController: UIViewController, EditorViewInput {
    ...
}
```

<details><summary>Objective-C Sample</summary>

```objectivec
///Editor 模块的接口和依赖
@protocol EditorViewInput <ZIKViewRoutable>
@property (nonatomic, weak) id<EditorDelegate> delegate;
- (void)constructForCreatingNewNote;
@end
```

```objectivec
///Editor view controller
@interface NoteEditorViewController: UIViewController <EditorViewInput>
@end
@implementation NoteEditorViewController
@end
```

</details>

创建路由只需要2步。

### 1. 创建 Router

将一个类模块化时，你需要为模块创建对应的 router。整个过程无需对模块本身做出任何修改，因此能够最大程度地减少模块化改造的成本。

#### 1.1 Router 子类

为你的模块创建 router 子类：

```swift
import ZIKRouter.Internal
import ZRouter

class NoteEditorViewRouter: ZIKViewRouter<NoteEditorViewController, ViewRouteConfig> {
    override class func registerRoutableDestination() {
        // 注册 class；一个 router 可以注册多个界面，一个界面也可以使用多个 router
        registerView(NoteEditorViewController.self)
        // 注册 protocol；之后就可以用这个 protocol 获取 此 router
        register(RoutableView<EditorViewInput>())
    }
    
    // 创建模块
    override func destination(with configuration: ViewRouteConfig) -> NoteEditorViewController? {
        let destination: NoteEditorViewController? = ... ///实例化 view controller
        return destination
    }
    
    override func prepareDestination(_ destination: NoteEditorViewController, configuration: ViewRouteConfig) {
        //为 destination 注入依赖
    }
}
```

<details><summary>Objective-C Sample</summary>

```objectivec
//NoteEditorViewRouter.h
@import ZIKRouter;

@interface NoteEditorViewRouter : ZIKViewRouter
@end

//NoteEditorViewRouter.m
@import ZIKRouter.Internal;

@implementation NoteEditorViewRouter

+ (void)registerRoutableDestination {
    // 注册 class；一个 Router 可以注册多个界面，一个界面也可以使用多个 Router
    [self registerView:[NoteEditorViewController class]];
    // 注册 protocol；之后就可以用这个 protocol 获取 此 router
    [self registerViewProtocol:ZIKRoutable(EditorViewInput)];
}

// 创建模块
- (NoteEditorViewController *)destinationWithConfiguration:(ZIKViewRouteConfiguration *)configuration {
    // 可以从configuration 中获取外部传入的参数，用于创建实例
    NoteEditorViewController *destination = ... // 实例化 view controller
    return destination;
}

- (void)prepareDestination:(NoteEditorViewController *)destination configuration:(ZIKViewRouteConfiguration *)configuration {
    // 为 destination 注入依赖
}

@end
```

</details>

ZIKRouter 的路由是离散式的管理方式，让每个模块各自管理路由过程，同时也能带来极强的可扩展性，可以进行非常多的自定义功能扩展。

关于更多可用于 override 的方法，请参考详细文档。

#### 1.2 快捷注册

如果你的类很简单，并不需要用到 router 子类，直接注册类即可：

```swift
ZIKAnyViewRouter.register(RoutableView<EditorViewInput>(), forMakingView: NoteEditorViewController.self)
```

<details><summary>Objective-C Sample</summary>

```objectivec
[ZIKViewRouter registerViewProtocol:ZIKRoutable(EditorViewInput) forMakingView:[NoteEditorViewController class]];
```

</details>

或者用 block 自定义创建对象的方式：

```swift
ZIKAnyViewRouter.register(RoutableView<EditorViewInput>(), 
                 forMakingView: NoteEditorViewController.self) { (config, router) -> EditorViewInput? in
                     let destination: NoteEditorViewController? = ... // 实例化 view controller
                     return destination;
        }

```

<details><summary>Objective-C Sample</summary>

```objectivec
[ZIKViewRouter
    registerViewProtocol:ZIKRoutable(EditorViewInput)
    forMakingView:[NoteEditorViewController class]
    making:^id _Nullable(ZIKViewRouteConfiguration *config, ZIKViewRouter *router) {
        NoteEditorViewController *destination = ... // 实例化 view controller
        return destination;
 }];
```

</details>

或者指定用 C 函数创建对象：

```swift
function makeEditorViewController(config: ViewRouteConfig) -> EditorViewInput? {
    let destination: NoteEditorViewController? = ... // 实例化 view controller
    return destination;
}

ZIKAnyViewRouter.register(RoutableView<EditorViewInput>(), 
                 forMakingView: NoteEditorViewController.self, making: makeEditorViewController)
```

<details><summary>Objective-C Sample</summary>

```objectivec
id<EditorViewInput> makeEditorViewController(ZIKViewRouteConfiguration *config) {
    NoteEditorViewController *destination = ... // 实例化 view controller
    return destination;
}

[ZIKViewRouter
    registerViewProtocol:ZIKRoutable(EditorViewInput)
    forMakingView:[NoteEditorViewController class]
    factory:makeEditorViewController];
```

</details>


### 2. 声明 Routable 类型

对路由进行声明，用于编译检查和支持 storyboard。

```swift
//声明 NoteEditorViewController 为 routable
//这表明 NoteEditorViewController 至少存在一个 对应的 router
extension NoteEditorViewController: ZIKRoutableView {
}

//声明 EditorViewInput 为 routable
//这份声明意味着我们可以用 EditorViewInput 来获取路由
extension RoutableView where Protocol == EditorViewInput {
    init() { self.init(declaredProtocol: Protocol.self) }
}
```

<details><summary>Objective-C Sample</summary>

```objectivec
//声明 NoteEditorViewController 为 routable
//这表明 NoteEditorViewController 至少存在一个 对应的 router
DeclareRoutableView(NoteEditorViewController, NoteEditorViewRouter)

///当 protocol 继承自 ZIKViewRoutable, 就是 routable 的
//这份声明意味着我们可以用 EditorViewInput 来获取路由
@protocol EditorViewInput <ZIKViewRoutable>
@property (nonatomic, weak) id<EditorDelegate> delegate;
- (void)constructForCreatingNewNote;
@end
```

</details>

**如果获取路由时，protocol 未经过声明，将会产生编译错误。这是 ZIKRouter 最特别的功能之一，可以让你更安全、更简单地管理所使用的路由接口，不必再用其他复杂的方式进行检查和维护。**

Swift 中使用未声明的 protocol：

![Unroutable-error-Swift](../Resources/Unroutable-error-Swift.png)

Objective-C 中使用未声明的 protocol：

![Unroutable-error-OC](../Resources/Unroutable-error-OC.png)

现在你可以用所声明的 protocol 进行路由操作了。

### View Router

#### 直接跳转

直接跳转到 editor 界面:

```swift
class TestViewController: UIViewController {

    //直接跳转到 editor view controller
    func showEditorDirectly() {
        Router.perform(to: RoutableView<EditorViewInput>(), path: .push(from: self))
    }
}
```

<details><summary>Objective-C Sample</summary>

```objectivec
@implementation TestViewController

- (void)showEditorDirectly {
    //直接跳转到 editor view controller
    [ZIKRouterToView(EditorViewInput) performPath:ZIKViewRoutePath.pushFrom(self)];
}

@end
```

</details>

可以用 `ViewRoutePath` 一键切换不同的跳转方式:

```swift
enum ViewRoutePath {
    case push(from: UIViewController)
    case presentModally(from: UIViewController)
    case presentAsPopover(from: UIViewController, configure: ZIKViewRoutePopoverConfigure)
    case performSegue(from: UIViewController, identifier: String, sender: Any?)
    case show(from: UIViewController)
    case showDetail(from: UIViewController)
    case addAsChildViewController(from: UIViewController, addingChildViewHandler: (UIViewController, @escaping () -> Void) -> Void)
    case addAsSubview(from: UIView)
    case custom(from: ZIKViewRouteSource?)
    case makeDestination
    case extensible(path: ZIKViewRoutePath)
}
```

封装界面跳转可以屏蔽 UIKit 的细节，此时界面跳转的代码就可以放在非 view 层（例如 presenter、view model、interactor、service），并且能够跨平台，也能轻易地通过配置切换跳转方式。

#### 跳转前进行配置

可以在跳转前配置页面，传递参数:

```swift
class TestViewController: UIViewController {

    //跳转到 editor 界面；通过 protocol 获取对应的 router 类，同时用 protocol 配置界面
    func showEditor() {
        Router.perform(
            to: RoutableView<EditorViewInput>(),
            path: .push(from: self),
            configuring: { (config, _) in
                //路由相关的设置
                //跳转前配置界面
                config.prepareDestination = { [weak self] destination in
                    //destination 自动推断为 EditorViewInput
                    destination.delegate = self
                    destination.constructForCreatingNewNote()
                }
                config.successHandler = { destination in
                    //跳转成功
                }
                config.errorHandler = { (action, error) in
                    //跳转失败
                }                
        })
    }
}
```

<details><summary>Objective-C Sample</summary>

```objectivec
@implementation TestViewController

- (void)showEditor {
    //跳转到 editor 界面；通过 protocol 获取对应的 router 类，同时用 protocol 配置界面
    [ZIKRouterToView(EditorViewInput)
	     performPath:ZIKViewRoutePath.pushFrom(self)
	     configuring:^(ZIKViewRouteConfig *config) {
	         //路由相关的设置
	         //跳转前配置界面
	         config.prepareDestination = ^(id<EditorViewInput> destination) {
	             destination.delegate = self;
	             [destination constructForCreatingNewNote];
	         };
	         config.successHandler = ^(id<EditorViewInput> destination) {
	             //跳转结束
	         };
	         config.errorHandler = ^(ZIKRouteAction routeAction, NSError * error) {
	             //跳转失败
	         };
	     }];
}

@end
```

</details>

更详细的内容，可以参考[执行路由](PerformRoute.md)。

#### Make Destination

如果不想执行界面跳转，只是想获取模块，执行自定义操作，可以使用`makeDestination`：

```swift
//destination 自动推断为 EditorViewInput
let destination = Router.makeDestination(to: RoutableView<EditorViewInput>())
```

<details><summary>Objective-C Sample</summary>

```objectivec
id<EditorViewInput> destination = [ZIKRouterToView(EditorViewInput) makeDestination];
```
</details>

#### 必需参数与特殊参数

有些参数不能直接通过 destination 的接口传递：

* 模块有自定义初始化方法，需要从外部传入一些必需参数后才能创建实例

* 需要传递的参数并不能都通过 destination 的接口设置，例如参数不属于 destination，而是属于模块内其他组件。如果把参数都放到 destination 的接口上，会导致接口被污染

传递必需参数需要使用工厂模式。此时可以对 router 的 configuration 进行扩展，用于保存参数。

之前用于路由的`EditorViewInput`是由 destination 遵守的，现在使用`EditorViewModuleInput`，由自定义的 configuration 遵守，用于声明模块需要的参数：

```swift
// protocol 里一般只需要 makeDestinationWith，用于声明参数类型和 destination 类型；也可以添加其他自定义的属性参数或者方法
protocol EditorViewModuleInput: class {
    // 工厂方法，传递参数，用于创建模块；这里声明了需要一个 Note 类型的参数，并返回一个 EditorViewInput
    var makeDestinationWith: (_ note: Note) -> EditorViewInput? { get }
}
```

<details><summary>Objective-C Sample</summary>

```objectivec
// 一般只需要 makeDestinationWith，用于声明参数类型和 destination 类型；也可以添加其他自定义的属性参数或者方法
@protocol EditorViewModuleInput <ZIKViewModuleRoutable>
 // 工厂方法，传递参数，用于创建模块； protocol 里声明了需要一个 Note 类型的参数，并返回一个 EditorViewInput
 @property (nonatomic, copy, readonly) id<EditorViewInput> _Nullable(^makeDestinationWith)(Note *note);
 @end
```

</details>

此时的 `EditorViewModuleInput ` 就类似于一个工厂类，通过它来声明和创建 destination。

使用者在调用模块时就能动态传入必需参数，调用时代码将会变成这样：

```swift
var note = ...
Router.makeDestination(to: RoutableViewModule<EditorViewModuleInput>()) { (config) in
     // 传递参数，得到 EditorViewInput
     let destination = config.makeDestinationWith(note)
}
```

<details><summary>Objective-C Sample</summary>

```objectivec
Note *note = ...
[ZIKRouterToViewModule(EditorViewModuleInput)
    performPath:ZIKViewRoutePath.showFrom(self)
    configuring:^(ZIKViewRouteConfiguration<EditorViewModuleInput> *config) {
        // 传递参数，得到 EditorViewInput
        id<EditorViewInput> destination = config.makeDestinationWith(note);
 }];
```
</details>

更详细的内容，可以参考[自定义 configuration 传参](CustomConfiguration.md)。

#### Perform on Destination

如果你从其他地方得到了一个 destination 对象，你可以用对应的 router 在这个 destination 上执行路由。

例如，某个 UIViewController 支持 3D touch，实现了`UIViewControllerPreviewingDelegate`：

```swift
class SourceViewController: UIViewController, UIViewControllerPreviewingDelegate {
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        //返回 destination UIViewController， 让系统执行预览
        let destination = Router.makeDestination(to: RoutableView<EditorViewInput>())
        return destination
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        guard let destination = viewControllerToCommit as? EditorViewInput else {
            return
        }
        //跳转到 destination
        Router.to(RoutableView<EditorViewInput>())?.perform(onDestination: destination, path: .presentModally(from: self))
}

```

<details><summary>Objective-C Sample</summary>

```objectivec
@implementation SourceViewController

- (nullable UIViewController *)previewingContext:(id <UIViewControllerPreviewing>)previewingContext viewControllerForLocation:(CGPoint)location {
    //返回 destination UIViewController， 让系统执行预览
    UIViewController<EditorViewInput> *destination = [ZIKRouterToView(EditorViewInput) makeDestination];
    return destination;
}

- (void)previewingContext:(id <UIViewControllerPreviewing>)previewingContext commitViewController:(UIViewController *)viewControllerToCommit {
    //跳转到 destination
    UIViewController<EditorViewInput> *destination;
    if ([viewControllerToCommit conformsToProtocol:@protocol(EditorViewInput)]) {
        destination = viewControllerToCommit;
    } else {
        return;
    }
    [ZIKRouterToView(EditorViewInput) performOnDestination:destination path:ZIKViewRoutePath.presentModallyFrom(self)];
}

@end
```

</details>

#### Prepare on Destination

如果你并不想执行路由，而只是想配置某个 destination 对象，可以用 router 执行 prepare 操作。这样， router 内部对 destination 对象执行的所有依赖注入操作就都会生效，destination 就被正确地配置好了。

```swift
var destination: DestinationViewInput = ...
Router.to(RoutableView<EditorViewInput>())?.prepare(destination: destination, configuring: { (config, _) in
            config.prepareDestination = { destination in
                // Prepare
            }
        })

```

<details><summary>Objective-C Sample</summary>

```objectivec
UIViewController<EditorViewInput> *destination = ...
[ZIKRouterToView(EditorViewInput) prepareDestination:destination configuring:^(ZIKViewRouteConfiguration *config) {
            config.prepareDestination = ^(id<EditorViewInput> destination) {
                // Prepare
            };
        }];
```

</details>

#### Remove

执行路由后，可以用`removeRoute`一键移除界面，无需区分调用 pop / dismiss / removeFromParentViewController / removeFromSuperview:

```swift
class TestViewController: UIViewController {
    var router: DestinationViewRouter<EditorViewInput>?
    
    func showEditor() {
        //持有 router
        router = Router.perform(to: RoutableView<EditorViewInput>(), path: .push(from: self))
    }
    
    //Router 会对 editor view controller 执行 pop 操作，移除界面
    func removeEditorDirectly() {
        guard let router = router, router.canRemove else {
            return
        }
        router.removeRoute()
        router = nil
    }
    
    func removeEditorWithResult() {
        guard let router = router, router.canRemove else {
            return
        }
        router.removeRoute(successHandler: {
            print("remove success")
        }, errorHandler: { (action, error) in
            print("remove failed, error: \(error)")
        })
        router = nil
    }
    
    func removeEditorAndPrepare() {
        guard let router = router, router.canRemove else {
            return
        }
        router.removeRoute(configuring: { (config) in
            config.animated = true
            config.prepareDestination = { destination in
                //在消除界面之前调用界面的方法
            }
        })
        router = nil
    }
}
```

<details><summary>Objective-C Sample</summary>

```objectivec
@interface TestViewController()
@property (nonatomic, strong) ZIKDestinationViewRouter(id<EditorViewInput>) *router;
@end
@implementation TestViewController

- (void)showEditorDirectly {
    //持有 router
    self.router = [ZIKRouterToView(EditorViewInput) performPath:ZIKViewRoutePath.pushFrom(self)];
}

//Router 会对 editor view controller 执行 pop 操作，移除界面
- (void)removeEditorDirectly {
    if (![self.router canRemove]) {
        return;
    }
    [self.router removeRoute];
    self.router = nil;
}

- (void)removeEditorWithResult {
    if (![self.router canRemove]) {
        return;
    }
    [self.router removeRouteWithSuccessHandler:^{
        NSLog(@"pop success");
    } errorHandler:^(ZIKRouteAction routeAction, NSError *error) {
        NSLog(@"pop failed,error:%@",error);
    }];
    self.router = nil;
}

- (void)removeEditorAndPrepare {
    if (![self.router canRemove]) {
        return;
    }
    [self.router removeRouteWithConfiguring:^(ZIKViewRemoveConfiguration *config) {
        config.animated = YES;
        config.prepareDestination = ^(UIViewController<EditorViewInput> *destination) {
            //在消除界面之前调用界面的方法
        };
    }];
    self.router = nil;
}

@end
```

</details>

更详细的内容，可以参考[移除路由](RemoveRoute.md)。

### Adapter

可以用另一个 protocol 获取 router，只要两个 protocol 提供了相同功能的接口即可，因此模块不会和某个固定的 protocol 耦合。即便接口有稍微不同，也可以通过 category、extension、proxy 等方式进行接口适配。

使用者需要用到的接口：

```swift
/// 使用者需要用到的 editor 模块的接口
protocol RequiredEditorViewInput: class {
    weak var delegate: EditorDelegate? { get set }
    func constructForCreatingNewNote()
}
```

<details><summary>Objective-C Sample</summary>

```objectivec
/// 使用者需要用到的 editor 模块的接口
@protocol RequiredEditorViewInput <ZIKViewRoutable>
@property (nonatomic, weak) id<EditorDelegate> delegate;
- (void)constructForCreatingNewNote;
@end
```

</details>

由宿主 app 对接 required protocol 和 provided protocol：
```swift
/// 在宿主 app 中，为 router 添加 required protocol
class EditorViewAdapter: ZIKViewRouteAdapter {
    override class func registerRoutableDestination() {
        //如果可以获取到 router 类，可以直接为 router 添加 RequiredEditorViewInput
        NoteEditorViewRouter.register(RoutableView<RequiredEditorViewInput>())
        
        //如果不能得到对应模块的 router，可以注册 adapter
        register(adapter: RoutableView<RequiredEditorViewInput>(), forAdaptee: RoutableView<EditorViewInput>())
    }
}

/// 让 NoteEditorViewController 支持 RequiredEditorViewInput
extension NoteEditorViewController: RequiredEditorViewInput {
}
```

<details><summary>Objective-C Sample</summary>

```objectivec
/// 在宿主 app 中，为 router 添加 required protocol

//EditorViewAdapter.h
@interface EditorViewAdapter : ZIKViewRouteAdapter
@end

//EditorViewAdapter.m
@implementation EditorViewAdapter

+ (void)registerRoutableDestination {
	//如果可以获取到 router 类，可以直接为 router 添加 RequiredEditorViewInput
	[NoteEditorViewRouter registerViewProtocol:ZIKRoutable(RequiredEditorViewInput)];
	//如果不能得到对应模块的 router，可以注册 adapter
	[self registerDestinationAdapter:ZIKRoutable(RequiredEditorViewInput) forAdaptee:ZIKRoutable(EditorViewInput)];
}

@end

/// 让 NoteEditorViewController 支持 RequiredEditorViewInput
@interface NoteEditorViewController (Adapter) <RequiredEditorViewInput>
@end
@implementation NoteEditorViewController (Adapter)
@end
```

</details>

适配之后，`RequiredEditorViewInput` 和 `EditorViewInput` 就会指向同一个 router。

使用`RequiredEditorViewInput`获取模块：

```swift
class TestViewController: UIViewController {

    func showEditorDirectly() {
        Router.perform(to: RoutableView<RequiredEditorViewInput>(), path: .push(from: self))
    }
}
```

<details><summary>Objective-C Sample</summary>

```objectivec
@implementation TestViewController

- (void)showEditorDirectly {
    [ZIKRouterToView(RequiredEditorViewInput) performPath:ZIKViewRoutePath.pushFrom(self)];
}

@end
```
</details>

使用 required protocol 和 provided protocol，就可以让模块间完美解耦，并进行接口适配，同时还能用 required protocol 声明模块所需的依赖。并且 required protocol 只需要是 provided protocol 的子集，让使用者只接触到自己用到的那些接口，限制接口的粒度。此时不再需要用一个公共库来集中存放所有的 protocol，即便模块间有互相依赖，也可以各自单独进行编译。

### 模块化

区分了`required protocol`和`provided protocol`后，就可以实现真正的模块化。在调用者声明了所需要的`required protocol`后，被调用模块就可以随时被替换成另一个相同功能的模块。

参考 demo 中的`ZIKLoginModule`示例模块，登录模块依赖于一个弹窗模块，而这个弹窗模块在`ZIKRouterDemo`和`ZIKRouterDemo-macOS`中是不同的，而在切换弹窗模块时，登录模块中的代码不需要做任何改变。

更详细的内容，可以参考[模块化和解耦](ModuleAdapter.md)。

### URL Router

ZIKRouter 也实现了一个默认的 URLRouter，可以方便地通过 url 调用模块，让模块能够统一处理 url 路由和接口调用。

ZIKRouter 默认没有附带此功能，如果需要，则在 `Podfile` 中添加子模块：`pod 'ZIKRouter/URLRouter'`，并且调用`[ZIKRouter enableDefaultURLRouteRule]`开启 URL router。

你可以给 router 注册 url：

```swift
class NoteEditorViewRouter: ZIKViewRouter<NoteEditorViewController, ViewRouteConfig> {
    override class func registerRoutableDestination() {
        //注册 url
        registerURLPattern("app://editor/:title")
    }
}
```

<details><summary>Objective-C Sample</summary>

```objectivec
@implementation NoteEditorViewRouter

+ (void)registerRoutableDestination {
    //注册 url
    [self registerURLPattern:@"app://editor/:title"];
}

@end
```
</details>

之后就可以用相应的 url 获取 router:

```swift
ZIKAnyViewRouter.performURL("app://editor/test_note", path: .push(from: self))
```

<details><summary>Objective-C Sample</summary>

```objectivec
[ZIKAnyViewRouter performURL:@"app://editor/test_note" path:ZIKViewRoutePath.pushFrom(self)];
```
</details>

以及处理 URL Scheme:

```swift
public func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
    let urlString = url.absoluteString
    if let _ = ZIKAnyViewRouter.performURL(urlString, fromSource: self.rootViewController) {
        return true
    } else if let _ = ZIKAnyServiceRouter.performURL(urlString) {
        return true
    } else {
        return false
    }
}
```

<details><summary>Objective-C Sample</summary>

```objectivec
- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
    if ([ZIKAnyViewRouter performURL:urlString fromSource:self.rootViewController]) {
        return YES;
    } else if ([ZIKAnyServiceRouter performURL:urlString]) {
        return YES;
    } else {
        return NO;
    }
}
```
</details>

每个项目对 URL 路由的需求都不一样，你可以按照项目需求实现自己的 URL 路由。基于 ZIKRouter 强大的可扩展性，你可以使用一个自定义的 ZIKRouter 作为父类，重写方法并添加自定义的功能。参考 `ZIKRouter+URLRouter.h`。

### 其他功能

还有其他功能，可以阅读详细的文档：

* 每个 router [自定义界面跳转](PerformRoute.md#自定义路由操作)，例如首页切换 tabbar
* 支持 [storyboard](Storyboard.md)
* 界面跳转的 [AOP](AOP.md) 回调
* [自定义事件处理](PerformRoute.md#自定义事件)

### Service Router

除了界面模块，也可以用 service router 获取普通模块:

```swift
///time service 的接口
protocol TimeServiceInput {
    func currentTimeString() -> String
}
```
```swift
class TestViewController: UIViewController {
    @IBOutlet weak var timeLabel: UILabel!
    
    func callTimeService() {
        //获取 TimeServiceInput 模块
        let timeService = Router.makeDestination(to: RoutableService<TimeServiceInput>())
        //使用service
        timeLabel.text = timeService.currentTimeString()
    }
}
```

<details><summary>Objective-C Sample</summary>

```objectivec
///time service 的接口
@protocol TimeServiceInput <ZIKServiceRoutable>
- (NSString *)currentTimeString;
@end
```

```objectivec
@interface TestViewController ()
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@end

@implementation TestViewController

- (void)callTimeService {
   //获取 TimeServiceInput 模块
   id<TimeServiceInput> timeService = [ZIKRouterToService(TimeServiceInput) makeDestination];
   self.timeLabel.text = [timeService currentTimeString];    
}

```
</details>

## Demo 和实践

ZIKRouter 是为了实践 VIPER 架构而开发的，但是也能用于 MVC、MVVM，并没有任何限制。

打开 `Router.xcworkspace` 来运行 demo。Demo 中的 ZIKRouterDemo 展示了如何用 ZIKRouter 进行各种界面跳转以及模块获取，并且展示了 Swift 和OC 混编的场景，以及模块解耦的演示。

想要查看 router 是如何应用在 VIPER 架构中的，可以参考这个项目：[ZIKViper](https://github.com/Zuikyo/ZIKViper)。

## 代码模板

可以用 Xcode 的文件模板快速生成 router 和 protocol 的代码：

![File Template](../Resources/filetemplate.png)

模板`ZIKRouter.xctemplate` 可以在这里获取 [Templates](Templates/)。

把`ZIKRouter.xctemplate`拷贝到`~/Library/Developer/Xcode/Templates/ZIKRouter.xctemplate`，就可以在`Xcode -> File -> New -> File -> Templates`中直接使用了。

## License

ZIKRouter is available under the MIT license. See the LICENSE file for more info.