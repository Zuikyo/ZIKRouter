# 模块适配器

如果你不想让模块的调用者和模块都使用同一个 protocol，可以用模块适配彻底把两个模块解耦。

## `Provided protocol`和`Required protocol`

你可以为同一个 router 注册多个 protocol。模块本身提供的接口是`provided protocol`，模块的调用者使用的接口是`required protocol`。

在 UML 的[组件图](http://www.uml-diagrams.org/component-diagrams.html)中，就很明确地表现出了这两者的概念。下图中的半圆就是`Required Interface`，框外的圆圈就是`Provided Interface`：

![组件图](http://upload-images.jianshu.io/upload_images/5879294-6309bffe07ebf178.png?imageMogr2/auto-orient/strip%7CimageView2/2)

那么如何实施`Required Interface`和`Provided Interface`？在我的这篇文章[iOS VIPER架构实践(二)：VIPER详解与实现](http://www.jianshu.com/p/de96a056b66a)里有详细讲解过，应该由 App Context 在一个 adapter 里进行接口适配，从而使得调用者可以继续在内部使用`Required Interface`，adapter 负责把`Required Interface`和修改后的`Provided Interface`进行适配。

## 为`Provided`模块添加`Required Interface`

用 category、extension、proxy 类为模块添加`required protocol`，工作全部由模块的使用和装配者 App Context 完成。

例如，某个界面A需要展示一个登陆界面，而且这个登陆界面可以显示一段自定义的提示语。

调用者模块示例：

```swift
protocol ModuleARequiredLoginViewInput {
  var message: String? { get set } //显示在登陆界面上的自定义提示语
}
//Module A中调用Login模块
Router.perform(
    to RoutableView<ModuleARequiredLoginViewInput>(),
    path: .presentModally(from: self)
    configuring { (config, _) in
        config.prepareDestination = { destination in
            destination.message = "请登录查看笔记详情"
        }
    })
```
<details><summary>Objective-C示例</summary>

```objectivec
@protocol ModuleARequiredLoginViewInput <ZIKViewRoutable>
@property (nonatomic, copy) NSString *message;
@end

//Module A 中调用 Login 模块
[ZIKRouterToView(ModuleARequiredLoginViewInput)
	          performPath:ZIKViewRoutePath.presentModallyFrom(self)
	          configuring:^(ZIKViewRouteConfiguration *config) {
	              //配置目的界面
	              config.prepareDestination = ^(id<ModuleARequiredLoginViewInput> destination) {
	                  destination.message = @"请登录查看笔记详情";
	              };
	          }];
```
</details>

`ZIKViewAdapter`和`ZIKServiceAdapter`专门负责为其他router添加protocol。

在 App Context 中让登陆模块支持`ModuleARequiredLoginViewInput`：

```swift
//登陆界面提供的接口
protocol ProvidedLoginViewInput {
   var notifyString: String? { get set }
}
```
```swift
//由App Context 实现，让登陆界面支持 ModuleARequiredLoginViewInput
class LoginViewAdapter: ZIKViewRouteAdapter {
    override class func registerRoutableDestination() {
        //如果可以获取到 router 类，可以直接为 router 添加 ModuleARequiredLoginViewInput
        ZIKEditorViewRouter.register(RoutableView<ModuleARequiredLoginViewInput>())
        //如果不能得到对应模块的 router，可以注册 adapter
        register(adapter: RoutableView<ModuleARequiredLoginViewInput>(), forAdaptee: RoutableView<ProvidedLoginViewInput>())
    }
}

extension LoginViewController: ModuleARequiredLoginViewInput {
    var message: String? {
        get {
            return notifyString
        }
        set {
            notifyString = newValue
        }
    }
}
```
<details><summary>Objective-C示例</summary>

```objectivec
//Login Module Provided Interface
@protocol ProvidedLoginViewInput <NSObject>
@property (nonatomic, copy) NSString *notifyString;
@end
```
```objectivec
//LoginViewAdapter.h，ZIKViewRouteAdapter 的子类
@interface LoginViewAdapter : ZIKViewRouteAdapter
@end

//LoginViewAdapter.m
@implementation LoginViewAdapter

+ (void)registerRoutableDestination {
	//如果可以获取到 router 类，可以直接为 router 添加 ModuleARequiredLoginViewInput
	[ZIKEditorViewRouter registerViewProtocol:ZIKRoutable(ModuleARequiredLoginViewInput)];
	//如果不能得到对应模块的 router，可以注册 adapter
	[self registerDestinationAdapter:ZIKRoutable(ModuleARequiredLoginViewInput) forAdaptee:ZIKRoutable(ProvidedLoginViewInput)];
}

@end

//用Objective-C的 category、Swift 的 extension 进行接口适配
@interface LoginViewController (ModuleAAdapter) <ModuleARequiredLoginViewInput>
@property (nonatomic, copy) NSString *message;
@end
@implementation LoginViewController (ModuleAAdapter)
- (void)setMessage:(NSString *)message {
	self.notifyString = message;
}
- (NSString *)message {
	return self.notifyString;
}
@end
```
</details>

## 用中介者转发接口

如果不能直接为模块添加`required protocol`，比如 protocol 里的一些 delegate 需要兼容：

```swift
protocol ModuleARequiredLoginViewDelegate {
    func didFinishLogin() -> Void
}
protocol ModuleARequiredLoginViewInput {
  var message: String? { get set }
  var delegate: ModuleARequiredLoginViewDelegate { get set }
}
```
<details><summary>Objective-C示例</summary>

```objectivec
@protocol ModuleARequiredLoginViewDelegate <NSObject>
- (void)didFinishLogin;
@end

@protocol ModuleARequiredLoginViewInput <ZIKViewRoutable>
@property (nonatomic, copy) NSString *message;
@property (nonatomic, weak) id<ModuleARequiredLoginViewDelegate> delegate;
@end
```
</details>

而模块里的 delegate 接口不一样：

```swift
protocol ProvidedLoginViewDelegate {
    func didLogin() -> Void
}
protocol ProvidedLoginViewInput {
  var notifyString: String? { get set }
  var delegate: ProvidedLoginViewDelegate { get set }
}
```
<details><summary>Objective-C示例</summary>

```objectivec
@protocol ProvidedLoginViewDelegate <NSObject>
- (void)didLogin;
@end

@protocol ProvidedLoginViewInput <NSObject>
@property (nonatomic, copy) NSString *notifyString;
@property (nonatomic, weak) id<ProvidedLoginViewDelegate> delegate;
@end
```
</details>

相同方法有不同参数类型时，可以用一个新的 router 代替真正的 router，在新的 router 里插入一个中介者，负责转发接口：

```swift
class ModuleAReqiredEditorViewRouter: ZIKViewRouter {
   override class func registerRoutableDestination() {
       registerView(/* proxy 类*/);
       register(RoutableView<ModuleARequiredLoginViewInput>())
   }
   override func destination(with configuration: ZIKViewRouteConfiguration) -> ModuleARequiredLoginViewInput? {
       let realDestination: ProvidedLoginViewInput = ZIKEditorViewRouter.makeDestination()
       //proxy 负责把 ModuleARequiredLoginViewInput 转发为 ProvidedLoginViewInput
       let proxy: ModuleARequiredLoginViewInput = ProxyForDestination(realDestination)
       return proxy
   }
}

```
<details><summary>Objective-C示例</summary>

```objectivec
@implementation ZIKModuleARequiredEditorViewRouter
+ (void)registerRoutableDestination {
	//注册 ModuleARequiredLoginViewInput，和新的ZIKModuleARequiredEditorViewRouter 配对，而不是目的模块中的 ZIKEditorViewRouter
	[self registerView:/* proxy 类*/];
	[self registerViewProtocol:ZIKRoutable(NoteListRequiredNoteEditorProtocol)];
}
- (id)destinationWithConfiguration:(ZIKViewRouteConfiguration *)configuration {
   //用 ZIKEditorViewRouter 获取真正的 destination
   id<ProvidedLoginViewInput> realDestination = [ZIKEditorViewRouter makeDestination];
    //proxy 负责把 ModuleARequiredLoginViewInput 转发为 ProvidedLoginViewInput
    id<ModuleARequiredLoginViewInput> proxy = ProxyForDestination(realDestination);
    return mediator;
}
@end
```
</details>

对于普通类，proxy 可以用 NSProxy 来实现。对于 UIKit 中的那些复杂的 UI 类，可以用子类，然后在子类中重写方法，进行模块适配。

一般来说，并不需要立即把所有的 protocol 都分离为`requiredProtocol`和`providedProtocol`。调用模块和目的模块可以暂时共用 protocol，或者只是简单地改个名字，在第一次需要替换模块的时候再对 protocol 进行分离。

通过`requiredProtocol`和`providedProtocol`，就可以实现模块间的完全解耦。