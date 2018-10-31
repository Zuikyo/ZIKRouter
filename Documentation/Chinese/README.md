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

一个用于模块间路由，基于接口进行模块发现和依赖注入的解耦工具，能够同时实现高度解耦和类型安全。

View router 将 UIKit / AppKit 中的所有界面跳转方式封装成一个统一的方法。

Service router 用于模块寻找，通过 protocol 寻找对应的模块，并用 protocol 进行依赖注入和模块调用。

`ZRouter`为 Swift 提供更加 Swifty、更加安全的路由方式。

---

## Features

- [x] 支持 Swift 和 Objective-C，以及两者混编
- [x] 支持 iOS、macOS、tvOS
- [x] 支持界面路由和任意模块的路由
- [x] 支持对模块进行静态依赖注入和动态依赖注入
- [x] **用 protocol 动态获取模块**
- [x] **用 protocol 向模块传递参数，基于接口进行类型安全的模块调用和参数传递**
- [x] **可以用 identifier 获取模块，和其他 URL router 兼容**
- [x] **明确声明可用于路由的 protocol，进行编译时检查和运行时检查，避免了动态特性带来的过于自由的安全问题**
- [x] **在模块和模块使用者中用不同的 protocol 指向同一个模块，因此路由时不必和某个固定的 protocol 耦合，也无需在一个公共库中集中管理所有的 protocol**
- [x] 用 adapter 对两个模块进行解耦和接口兼容
- [x] 使用泛型表明指定功能的 router
- [x] 封装 UIKit 和 AppKit 里的所有界面跳转方式（push、present modally、present as popover、present as sheet、segue、show、showDetail、addChildViewController、addSubview）以及自定义的展示方式，统一成一个方法
- [x] 用一个方法执行界面回退和模块销毁，不必区分使用pop、dismiss、removeFromParentViewController、removeFromSuperview
- [x] **支持 storyboard，可以对从 segue 中跳转的界面自动执行依赖注入**
- [x] 完备的错误检查，可以检测界面跳转时的大部分问题
- [x] 支持界面跳转过程中的 AOP 回调
- [x] 检测界面跳转和移除时的内存泄露
- [x] 发送自定义事件给 router 处理
- [x] 两种注册方式：自动注册和手动注册
- [x] 用 router 子类添加模块，也可以用 block 添加 router

## 目录

### 设计思想

[设计思想](DesignPhilosophy.md)

### Basics

1. [创建路由](RouterImplementation.md)
2. [模块注册](ModuleRegistration.md)
3. [Routable 声明](RoutableDeclaration.md)
4. [类型检查](TypeChecking.md)
5. [执行路由](PerformRoute.md)
6. [移除路由](RemoveRoute.md)
7. [获取模块](MakeDestination.md)

### Advanced Features

1. [错误检查](ErrorHandle.md)
2. [Storyboard 和自动注入](Storyboard.md)
3. [AOP](AOP.md)
4. [依赖注入](DependencyInjection.md)
5. [循环依赖问题](CircularDependencies.md)
6. [模块化和解耦](ModuleAdapter.md)

[FAQ](FAQ.md)

## Requirements

* iOS 7.0+
* Swift 3.2+
* Xcode 9.0+

## Installation

### Cocoapods

可以用 Cocoapods 安装 ZIKRouter：

```
pod 'ZIKRouter', '>= 1.0.6'
```

如果是 Swift 项目，则使用 ZRouter：

```
pod 'ZRouter', '>= 1.0.6'
```

### Carthage

添加到 Cartfile 文件：

```
github "Zuikyo/ZIKRouter" >= 1.0.6
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
protocol NoteEditorInput: class {
    weak var delegate: EditorDelegate? { get set }
    func constructForCreatingNewNote()
}

///Editor view controller
class NoteEditorViewController: UIViewController, NoteEditorInput {
    ...
}
```

<details><summary>Objective-C Sample</summary>
  
```objectivec
///Editor 模块的接口和依赖
@protocol NoteEditorInput <ZIKViewRoutable>
@property (nonatomic, weak) id<EditorDelegate> delegate;
- (void)constructForCreatingNewNote;
@end
```

```objectivec
///Editor view controller
@interface NoteEditorViewController: UIViewController <NoteEditorInput>
@end
@implementation NoteEditorViewController
@end
```

</details>

创建路由只需要2步。

### 1. 创建 Router

为你的模块创建 router 子类：

```swift
import ZIKRouter.Internal
import ZRouter

class NoteEditorViewRouter: ZIKViewRouter<NoteEditorViewController, ViewRouteConfig> {
    override class func registerRoutableDestination() {
        // 注册 class；一个 router 可以注册多个界面，一个界面也可以使用多个 router
        registerView(NoteEditorViewController.self)
        // 注册 protocol；之后就可以用这个 protocol 获取 此 router
        register(RoutableView<NoteEditorInput>())
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
    [self registerViewProtocol:ZIKRoutable(NoteEditorInput)];
}

// 创建模块
- (NoteEditorViewController *)destinationWithConfiguration:(ZIKViewRouteConfiguration *)configuration {
    NoteEditorViewController *destination = ... ///实例化 view controller
    return destination;
}

- (void)prepareDestination:(NoteEditorViewController *)destination configuration:(ZIKViewRouteConfiguration *)configuration {
    //为 destination 注入依赖
}

@end
```

</details>

关于更多可用于 override 的方法，请参考详细文档。

### 2. 声明 Routable 类型

对路由进行声明，用于编译检查和支持 storyboard。

```swift
//声明 NoteEditorViewController 为 routable
//这表明 NoteEditorViewController 至少存在一个 对应的 router
extension NoteEditorViewController: ZIKRoutableView {
}

//声明 NoteEditorInput 为 routable
//这份声明意味着我们可以用 NoteEditorInput 来获取路由
//如果获取路由时，protocol 未经过声明，将会产生编译错误
extension RoutableView where Protocol == NoteEditorInput {
    init() { self.init(declaredProtocol: Protocol.self) }
}
```

<details><summary>Objective-C Sample</summary>

```objectivec
//声明 NoteEditorViewController 为 routable
//这表明 NoteEditorViewController 至少存在一个 对应的 router
DeclareRoutableView(NoteEditorViewController, NoteEditorViewRouter)

///当 protocol 继承自 ZIKViewRoutable, 就是 routable 的
//这份声明意味着我们可以用 NoteEditorInput 来获取路由
//如果获取路由时，protocol 未经过声明，将会产生编译错误
@protocol NoteEditorInput <ZIKViewRoutable>
@property (nonatomic, weak) id<EditorDelegate> delegate;
- (void)constructForCreatingNewNote;
@end
```

</details>

现在你可以用所声明的 protocol 进行路由操作了。

### View Router

#### 直接跳转

直接跳转到 editor 界面:

```swift
class TestViewController: UIViewController {

    //直接跳转到 editor view controller
    func showEditorDirectly() {
        Router.perform(to: RoutableView<NoteEditorInput>(), path: .push(from: self))
    }
}
```

<details><summary>Objective-C Sample</summary>

```objectivec
@implementation TestViewController

- (void)showEditorDirectly {
    //直接跳转到 editor view controller
    [ZIKRouterToView(NoteEditorInput) performPath:ZIKViewRoutePath.pushFrom(self)];
}

@end
```

</details>

可以用 `routeType` 一键切换不同的跳转方式:

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

#### 跳转前进行配置

可以在跳转前配置页面，传递参数:

```swift
class TestViewController: UIViewController {

    //跳转到 editor 界面；通过 protocol 获取对应的 router 类，同时用 protocol 配置界面
    func showEditor() {
        Router.perform(
            to: RoutableView<NoteEditorInput>(),
            path: .push(from: self),
            configuring: { (config, _) in
                //路由相关的设置
                config.successHandler = { destination in
                    //跳转成功
                }
                config.errorHandler = { (action, error) in
                    //跳转失败
                }
                //跳转前配置界面
                config.prepareDestination = { [weak self] destination in
                    //destination 自动推断为 NoteEditorInput
                    destination.delegate = self
                    destination.constructForCreatingNewNote()
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
    [ZIKRouterToView(NoteEditorInput)
	     performPath:ZIKViewRoutePath.pushFrom(self)
	     configuring:^(ZIKViewRouteConfig *config) {
	         //路由相关的设置
	         //跳转前配置界面
	         config.prepareDestination = ^(id<NoteEditorInput> destination) {
	             destination.delegate = self;
	             [destination constructForCreatingNewNote];
	         };
	         config.successHandler = ^(id<NoteEditorInput> destination) {
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

#### Remove

用`removeRoute`一键移除界面，无需区分调用 pop / dismiss / removeFromParentViewController / removeFromSuperview:

```swift
class TestViewController: UIViewController {
    var router: DestinationViewRouter<NoteEditorInput>?
    
    func showEditor() {
        //持有 router
        router = Router.perform(to: RoutableView<NoteEditorInput>(), path: .push(from: self))
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
@property (nonatomic, strong) ZIKDestinationViewRouter(id<NoteEditorInput>) *router;
@end
@implementation TestViewController

- (void)showEditorDirectly {
    //持有 router
    self.router = [ZIKRouterToView(NoteEditorInput) performPath:ZIKViewRoutePath.pushFrom(self)];
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
        config.prepareDestination = ^(UIViewController<NoteEditorInput> *destination) {
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
///使用者需要用到的 editor 模块的接口
protocol RequiredNoteEditorInput: class {
    weak var delegate: EditorDelegate? { get set }
    func constructForCreatingNewNote()
}
```

<details><summary>Objective-C Sample</summary>
  
```objectivec
///使用者需要用到的 editor 模块的接口
@protocol RequiredNoteEditorInput <ZIKViewRoutable>
@property (nonatomic, weak) id<EditorDelegate> delegate;
- (void)constructForCreatingNewNote;
@end
```

</details>

使用`RequiredNoteEditorInput`获取模块：

```swift
class TestViewController: UIViewController {

    func showEditorDirectly() {
        Router.perform(to: RoutableView<RequiredNoteEditorInput>(), path: .push(from: self))
    }
}
```

<details><summary>Objective-C Sample</summary>

```objectivec
@implementation TestViewController

- (void)showEditorDirectly {
    [ZIKRouterToView(RequiredNoteEditorInput) performPath:ZIKViewRoutePath.pushFrom(self)];
}

@end
```
</details>

使用 required protocol 和 provided protocol，就可以让模块间完美解耦，并进行接口适配，同时还能用 required protocol 声明模块所需的依赖。不再需要用一个公共库来集中存放所有的 protocol 了。

使用 required protocol 需要将 required protocol 和 provided protocol 进行对接。更详细的内容，可以参考[模块化和解耦](ModuleAdapter.md)。

### URL Router

ZIKRouter 和其他 URL Router 框架兼容。

你可以给 router 注册自定义字符串：

```swift
class NoteEditorViewRouter: ZIKViewRouter<NoteEditorViewController, ViewRouteConfig> {
    override class func registerRoutableDestination() {
        //注册字符串
        registerIdentifier("myapp://noteEditor")
    }
}
```

<details><summary>Objective-C Sample</summary>

```objectivec
@implementation NoteEditorViewRouter

+ (void)registerRoutableDestination {
    //注册字符串
    [self registerIdentifier:@"myapp://noteEditor"];
}

@end
```
</details>

之后就可以用相应的字符串获取 router:

```swift
Router.to(viewIdentifier: "myapp://noteEditor")?.perform(path .push(from: self))
```

<details><summary>Objective-C Sample</summary>

```objectivec
[ZIKViewRouter.toIdentifier(@"myapp://noteEditor") performPath:ZIKViewRoutePath.pushFrom(self)];
```
</details>

以及处理 URL Scheme:

```swift
public func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        //可以使用其他的第三方 URL router 库
        let routerIdentifier = URLRouter.routerIdentifierFromURL(url)
        guard let identifier = routerIdentifier else {
            return false
        }
        guard let routerType = Router.to(viewIdentifier: identifier) else {
            return false
        }
        let params: [String : Any] = [ "url": url, "options": options ]
        routerType.perform(path: .show(from: rootViewController), configuring: { (config, _) in
            // 传递参数
            config.addUserInfo(params)
        })
        return true
    }
```

<details><summary>Objective-C Sample</summary>

```objectivec
- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
    
    //可以使用其他的第三方 URL router 库
    NSString *identifier = [URLRouter routerIdentifierFromURL:url];
    if (identifier == nil) {
        return NO;
    }
    ZIKViewRouterType *routerType = ZIKViewRouter.toIdentifier(identifier);
    if (routerType == nil) {
        return NO;
    }
    
    NSDictionary *params = @{ @"url": url,
                              @"options" : options
                              };
    [routerType performPath:ZIKViewRoutePath.showFrom(self.rootViewController)
                configuring:^(ZIKViewRouteConfiguration * _Nonnull config) {
                    //传递参数
                    [config addUserInfo:params];
                }];
    return YES;
}
```
</details>

### Make Destination & Service Router

如果不想执行界面跳转，只是想获取模块，执行自定义操作，可以使用`makeDestination`：

```swift
let destination = Router.makeDestination(to: RoutableView<NoteEditorInput>())
```

<details><summary>Objective-C Sample</summary>

```objectivec
id<NoteEditorInput> destination = [ZIKRouterToView(NoteEditorInput) makeDestination];
```
</details>

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
        let timeService = Router.makeDestination(
        	to: RoutableService<TimeServiceInput>(), 
        	preparation: { destination in
            //配置模块
        })
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

Demo 目录下的 ZIKRouterDemo 展示了如何用 ZIKRouter 进行各种界面跳转以及模块获取，并且展示了 Swift 和OC 混编的场景。

想要查看 router 是如何应用在 VIPER 架构中的，可以参考这个项目：[ZIKViper](https://github.com/Zuikyo/ZIKViper)。

## File Template

可以用 Xcode 的文件模板快速生成 router 和 protocol 的代码：

![File Template](../Resources/filetemplate.png)

模板`ZIKRouter.xctemplate` 可以在这里获取 [Templates](Templates/)。

把`ZIKRouter.xctemplate`拷贝到`~/Library/Developer/Xcode/Templates/ZIKRouter.xctemplate`，就可以在`Xcode -> File -> New -> File -> Templates`中直接使用了。

## License

ZIKRouter is available under the MIT license. See the LICENSE file for more info.