<p align="center">
  <img src="../Resources/icon.png" width="33%">
</p>

# ZIKRouter

![](https://img.shields.io/cocoapods/p/ZIKRouter.svg?style=flat)
![](https://img.shields.io/badge/language-objectivec-blue.svg)
![ZIKRouter](https://img.shields.io/cocoapods/v/ZIKRouter.svg?style=flat)
![](https://img.shields.io/badge/language-swift-orange.svg)
![ZRouter](https://img.shields.io/cocoapods/v/ZRouter.svg?style=flat)
![license](https://img.shields.io/github/license/mashape/apistatus.svg)

一个用于模块间路由，基于接口进行模块发现和依赖注入的Router，能够同时实现高度解耦和类型安全。

View router将UIKit中的所有界面跳转方式封装成一个统一的方法。

Service router用于模块寻找，通过protocol寻找对应的模块，并用protocol进行依赖注入和模块调用。

`ZRouter`为Swift提供更加Swifty、更加安全的路由方式。

---

## Features

- [x] 支持Swift和Objective-C，以及两者混编
- [x] 支持界面路由和任意模块的路由
- [x] 支持对模块进行静态依赖注入和动态依赖注入
- [x] 用protocol动态获取界面和模块，隐藏具体类
- [x] 用protocol向模块传递参数，基于接口进行类型安全的模块调用和参数传递
- [x] 明确声明可用于路由的public protocol，进行编译时检查和运行时检查，避免了动态特性带来的过于自由的安全问题
- [x] 使用泛型表明指定功能的router
- [x] 用adapter对两个模块进行解耦和接口兼容
- [x] 封装UIKit里的所有界面跳转方式（push、present modally、present as popover、segue、show、showDetail、addChildViewController、addSubview）以及自定义的展示方式，封装成一个统一的方法
- [x] 支持用一个方法执行界面回退和模块销毁，不必区分使用pop、dismiss、removeFromParentViewController、removeFromSuperview
- [x] 支持storyboard，可以对从segue中跳转的界面执行依赖注入
- [x] 完备的错误检查，可以检测界面跳转时的大部分问题
- [x] 支持界面跳转过程中的AOP回调
- [ ] 增加支持Mac OS和tv OS
- [ ] 可以选择自定义注册时机，不必在启动时一次性注册
- [ ] 支持swift中的value类型
- [ ] 支持用block添加router，而不是router子类

## Table of Contents

### Basics

1. [创建路由](RouterImplementation.md)
2. [模块注册](ModuleRegistration.md)
3. [Routable声明](RoutableDeclaration.md)
4. [类型检查](TypeChecking.md)
5. [执行路由](PerformRoute.md)
6. [移除路由](RemoveRoute.md)
7. [获取模块](MakeDestination.md)

### Advanced Features

1. [错误检查](ErrorHandle.md)
2. [Storyboard](Storyboard.md)
3. [AOP](AOP.md)
4. [依赖注入](DependencyInjection.md)
5. [循环依赖问题](CircularDependencies.md)
6. [模块化和解耦](ModuleAdapter.md)

## 示例代码

下面演示router的基本使用。

### View Router

演示用的界面和protocol。

```swift
///Editor模块的接口和依赖
protocol NoteEditorInput {
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
///Editor模块的接口和依赖
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

#### 直接跳转

直接跳转到editor界面:

```swift
class TestViewController: UIViewController {

    //直接跳转到editor view controller
    func showEditorDirectly() {
        Router.perform(to: RoutableView<NoteEditorInput>(), from: self, routeType: .push)
        })
    }
}
```

<details><summary>Objective-C Sample</summary>

```objectivec
@implementation TestViewController

- (void)showEditorDirectly {
    //直接跳转到editor view controller
    [ZIKViewRouterToView(NoteEditorInput) performFromSource:self routeType:ZIKViewRouteTypePush];
}

@end
```

</details>

可以用 `routeType` 一键切换不同的跳转方式:

```swift
enum ZIKViewRouteType : Int {
    case push
    case presentModally
    case presentAsPopover
    case performSegue
    case show
    case showDetail
    case addAsChildViewController
    case addAsSubview
    case custom
    case getDestination
}
```

#### 跳转前进行配置

可以在跳转前配置页面，传递参数:

```swift
class TestViewController: UIViewController {

    //跳转到editor界面；通过protocol获取对应的router类，再通过protocol配置界面
    func showEditor() {
        Router.perform(
            to: RoutableView<NoteEditorInput>(),
            from: self,
            configuring: { (config, prepareDestination, _) in
                //路由相关的设置
                //设置跳转方式
                config.routeType = .push
                config.routeCompletion = { destination in
                    //跳转结束
                }
                config.errorHandler = { (action, error) in
                    //跳转失败
                }
                //跳转前配置界面
                prepareDestination({ destination in
                    //destination 自动推断为 NoteEditorInput
                    destination.delegate = self
                    destination.constructForCreatingNewNote()
                })
        })
    }
}
```

<details><summary>Objective-C Sample</summary>

```objectivec
@implementation TestViewController

- (void)showEditor {
    //跳转到editor界面；通过protocol获取对应的router类，再通过protocol配置界面
    [ZIKViewRouterToView(NoteEditorInput)
	     performFromSource:self
	     configuring:^(ZIKViewRouteConfig *config) {
	         //路由相关的设置
	         //设置跳转方式
	         config.routeType = ZIKViewRouteTypePush;
	         //跳转前配置界面
	         config.prepareDestination = ^(id<NoteEditorInput> destination) {
	             destination.delegate = self;
	             [destination constructForCreatingNewNote];
	         };
	         config.routeCompletion = ^(id<NoteEditorInput> destination) {
	             //跳转结束
	         };
	         config.performerErrorHandler = ^(SEL routeAction, NSError * error) {
	             //跳转失败
	         };
	     }];
}

@end
```

</details>

#### Remove

用`removeRoute`一键移除界面，无需区分调用 pop / dismiss / removeFromParentViewController / removeFromSuperview:

```swift
class TestViewController: UIViewController {
    var router: DestinationViewRouter<NoteEditorInput>?
    
    func showEditor() {
        //持有router
        router = Router.perform(to: RoutableView<NoteEditorInput>(), from: self, routeType: .push)
        })
    }
    
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
            print("remove failed, error:%@",error)
        })
        router = nil
    }
    
    func removeEditorAndPrepare() {
        guard let router = router, router.canRemove else {
            return
        }
        router.removeRoute(configuring: { (config, prepareDestination) in
	            config.animated = true
	            prepareDestination({ destination in
	                //在消除界面之前调用界面的方法
	            })
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
    //持有router
    self.router = [ZIKViewRouterToView(NoteEditorInput)
	     performFromSource:self routeType:ZIKViewRouteTypePush];
}

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

### Service Router

获取模块:

```swift
///time service的接口
protocol TimeServiceInput {
    func currentTimeString() -> String
}
```
```swift
class TestViewController: UIViewController {
    @IBOutlet weak var timeLabel: UILabel!
    
    func callTimeService() {
        //获取TimeServiceInput模块
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

<details><summary>Objective-C示例</summary>

```objectivec
///time service的接口
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
   //获取TimeServiceInput模块
   id<TimeServiceInput> timeService = [ZIKServiceRouterToService(TimeServiceInput) makeDestination];
   self.timeLabel.text = [timeService currentTimeString];    
}

```
</details>

## Demo和实践

ZIKRouter是为了实践VIPER架构而开发的，但是也能用于MVC、MVVM，并没有任何限制。

Demo目录下的ZIKRouterDemo展示了如何用ZIKRouter进行各种界面跳转以及模块获取，并且展示了Swift和OC混编的场景。

想要查看router是如何应用在VIPER架构中的，可以参考这个项目：[ZIKViper](https://github.com/Zuikyo/ZIKViper)。

## Installation

### Cocoapods

可以用Cocoapods安装ZIKRouter：

```
pod 'ZIKRouter', '0.12.1'
```

如果是Swift项目，则使用ZRouter：

```
pod 'ZRouter', '0.8.0'
```

## How to use

简单演示如何使用ZIKRouter创建路由。

### 1.创建Router

为你的模块创建 router 子类：

```swift
import ZIKRouter.Internal
import ZRouter

class NoteEditorViewRouter: ZIKViewRouter<NoteEditorViewController, ViewRouteConfig> {
    override class func registerRoutableDestination() {
        registerView(NoteEditorViewController.self)
        register(RoutableView<NoteEditorInput>())
    }
    
    override func destination(with configuration: ViewRouteConfig) -> NoteEditorViewController? {
        let destination: SwiftSampleViewController? = ... ///实例化view controller
        return destination
    }
    
    override func prepareDestination(_ destination: NoteEditorViewController, configuration: ViewRouteConfig) {
        //为destination注入依赖
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
    [self registerView:[NoteEditorViewRouter class]];
    [self registerViewProtocol:ZIKRoutableProtocol(NoteEditorInput)];
}

- (NoteEditorViewRouter *)destinationWithConfiguration:(ZIKViewRouteConfiguration *)configuration {
    NoteEditorViewRouter *destination = ... ///实例化view controller
    return destination;
}

- (void)prepareDestination:(NoteEditorViewRouter *)destination configuration:(ZIKViewRouteConfiguration *)configuration {
    //为destination注入依赖
}
```

</details>

关于更多可用于override的方法，请参考详细文档。

### 2.声明 Routable 类型

```swift
//声明 NoteEditorViewController is routable
extension NoteEditorViewController: ZIKRoutableView {
}

//声明 NoteEditorInput is routable
extension RoutableView where Protocol == NoteEditorInput {
    init() { }
}
```

<details><summary>Objective-C Sample</summary>

```objectivec
//声明 NoteEditorViewController is routable
DeclareRoutableView(MasterViewController, MasterViewRouter)

///当 protocol 继承自 ZIKViewRoutable, 就是 routable 的
@protocol NoteEditorInput <ZIKViewRoutable>
@property (nonatomic, weak) id<EditorDelegate> delegate;
- (void)constructForCreatingNewNote;
@end
```

</details>

### 3.Use

```swift
class TestViewController: UIViewController {

    //直接跳转
    func showEditorDirectly() {
        Router.perform(to: RoutableView<NoteEditorInput>(), from: self, routeType: .push)
        })
    }
    
    //跳转到editor界面；通过protocol获取对应的router类，再通过protocol配置界面
    func showEditor() {
        Router.perform(
            to: RoutableView<NoteEditorInput>(),
            from: self,
            configuring: { (config, prepareDestination, _) in
                config.routeType = .push
                //跳转前配置destination
                prepareDestination({ destination in
                    //destination 自动推断为 NoteEditorInput 类型
                    destination.delegate = self
                    destination.constructForCreatingNewNote()
                })
        })
    }
}
```

<details><summary>Objective-C Sample</summary>

```objectivec
@implementation TestViewController

//直接跳转
- (void)showEditorDirectly {
    //Transition to editor view directly
    [ZIKViewRouterToView(NoteEditorInput) performFromSource:self routeType:ZIKViewRouteTypePush];
}

//跳转到editor界面；通过protocol获取对应的router类，再通过protocol配置界面
- (void)showEditor {
    [ZIKViewRouterToView(NoteEditorInput)
	     performFromSource:self
	     configuring:^(ZIKViewRouteConfig *config) {
	         config.routeType = ZIKViewRouteTypePush;
	         //跳转前配置destination
	         config.prepareDestination = ^(id<NoteEditorInput> destination) {
	             destination.delegate = self;
	             [destination constructForCreatingNewNote];
	         };
	     }];
}

@end
```

</details>

## License

ZIKRouter is available under the MIT license. See the LICENSE file for more info.