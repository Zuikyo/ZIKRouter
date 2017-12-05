# Documentation

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
- [ ] 增加支持Mac OS和TV OS
- [ ] 可以选择自定义注册
- [ ] 支持swift中的value类型
- [ ] 支持用block添加router，而不是router子类

## Table of Contents

### Basics

1. [添加路由](RouterImplementation.md)
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

下面简单演示router的使用。

### View Router

界面跳转：

```swift
///editor模块的接口和依赖
protocol NoteEditorInput {
    weak var delegate: EditorDelegate? { get set }
    func constructForCreatingNewNote()
}

///Editor界面
class NoteEditorViewController: UIViewController, NoteEditorInput {
    ...
}
```

```swift
class TestViewController: UIViewController {
    //跳转到editor界面；通过protocol获取对应的router类，再通过protocol配置界面
    func showEditor() {
        Router.perform(
            to: RoutableView<NoteEditorInput>(),
            from: self,
            configuring: { (config, prepareDestination, _) in
                //路由相关的设置
                //跳转方式
                config.routeType = ViewRouteType.push
                config.routeCompletion = { destination in
                    //跳转结束
                }
                config.errorHandler = { (action, error) in
                    //跳转失败
                }
                //跳转前配置界面
                prepareDestination({ destination in
                    //destination 自动推断为 NoteEditorInput 类型
                    destination.delegate = self
                    destination.constructForCreatingNewNote()
                })
        })
    }
}
```

<details><summary>Objective-C示例</summary>
  
```objectivec
///editor模块的接口和依赖
@protocol NoteEditorInput <ZIKViewRoutable>
@property (nonatomic, weak) id<EditorDelegate> delegate;
- (void)constructForCreatingNewNote;
@end

```
```objectivec
///Editor界面
@interface NoteEditorViewController: UIViewController <NoteEditorInput>
@end
@implementation NoteEditorViewController
@end
```
```objectivec
@implementation TestViewController

- (void)showEditor {
    //跳转到editor界面；通过protocol获取对应的router类，再通过protocol配置界面
    [ZIKViewRouter.toView(@protocol(NoteEditorInput))
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

### Service Router

获取模块:

```swift
///time service的接口
protocol TimeServiceInput {
    func currentTimeString() -> String
}
```
```
class TestViewController: UIViewController {
    @IBOutlet weak var timeLabel: UILabel!
    
    func callTimeService() {
        //获取TimeServiceInput模块
        let timeService = Router.makeDestination(to: RoutableService<TimeServiceInput>(), preparation: { destination in
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
   id<TimeServiceInput> timeService = [ZIKServiceRouter.toService(TimeServiceInput) makeDestination];
   self.timeLabel.text = [timeService currentTimeString];    
}

```
</details>

## Demo和实践

ZIKRouter是为了实践VIPER架构而开发的，但是也能用于MVC、MVVM，并没有任何限制。

Demo目录下的ZIKRouterDemo展示了如何用ZIKRouter进行各种界面跳转以及模块获取，并且展示了Swift和OC混编的场景。

想要查看router是如何应用在VIPER架构中的，可以参考这个项目：[ZIKViper](https://github.com/Zuikyo/ZIKViper)。

## Cocoapods

可以用Cocoapods安装ZIKRouter：

```
pod "ZIKRouter"
```

如果是Swift项目，则使用ZRouter：

```
pod "ZRouter"
```

## License

ZIKRouter is available under the MIT license. See the LICENSE file for more info.