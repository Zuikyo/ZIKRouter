# 创建路由

将一个类模块化时，你需要为模块创建对应的 router 子类，然后在子类中实现 router 的接口即可。整个过程无需对模块本身做出任何修改，因此能够最大程度地减少模块化改造的成本。

例如，要为`EditorViewController`创建路由。

Swift示例：

```swift
protocol EditorViewInput {
    weak var delegate: EditorDelegate? { get set }
    func constructForCreatingNewNote()
}

class EditorViewController: UIViewController, EditorViewInput {
    ...
}
```
## Router 子类

为`EditorViewController`创建一个`ZIKViewRouter`的子类：

```swift
//EditorViewRouter.swift

//声明 EditorViewController 是可路由的 UIViewController
extension EditorViewController: ZIKRoutableView {

}
//声明 EditorViewInput 是可路由的
extension RoutableView where Protocol == EditorViewInput {
    init() { self.init(declaredProtocol: Protocol.self) }
}

class EditorViewRouter: ZIKViewRouter<EditorViewController, ZIKViewRouteConfiguration> {
    //注册当前 Router 所管理的 view 和 protocol
    override class func registerRoutableDestination() {
        //把 EditorViewController 和对应的 Router 子类进行注册，一个 Router 可以注册多个界面，一个界面也可以使用多个 Router
        registerView(EditorViewController.self)
        
        //注册 EditorViewInput，注册后就可以用此 protocol 获取此 router
        register(RoutableView<EditorViewInput>())
    }
    
    //返回需要获取的目的模块
    override func destination(with configuration: ZIKViewRouteConfiguration) -> EditorViewController? {
        let sb = UIStoryboard.init(name: "Main", bundle: nil)
        let destination = sb.instantiateViewController(withIdentifier: "EditorViewController") as! EditorViewController
        return destination
    }
    
    //来自 storyboard 的 destination，是否需要让 source view controller 进行配置
    override func destinationFromExternalPrepared(destination: EditorViewController) -> Bool {
        if (destination.delegate != nil) {
            return true
        }
        return false
    }
    
    //在执行路由前配置模块，执行依赖注入
    override func prepareDestination(_ destination: EditorViewController, configuration: ZIKViewRouteConfiguration) {
        //为EditorViewController注入依赖
    }
    
    //配置完毕，检查是否配置正确
    override func didFinishPrepareDestination(_ destination: EditorViewController, configuration: ZIKViewRouteConfiguration) {
        
    }
    
    //View Router 的 AOP 回调
    override class func router(_ router: ZIKAnyViewRouter?, willPerformRouteOnDestination destination: EditorViewController, fromSource source: Any?) {
        
    }
    override class func router(_ router: ZIKAnyViewRouter?, didPerformRouteOnDestination destination: EditorViewController, fromSource source: Any?) {
        
    }
    override class func router(_ router: ZIKAnyViewRouter?, willRemoveRouteOnDestination destination: EditorViewController, fromSource source: Any?) {
        
    }
    override class func router(_ router: ZIKAnyViewRouter?, didRemoveRouteOnDestination destination: EditorViewController, fromSource source: Any?) {
        
    }
}
```

<details><summary>Objective-C示例</summary>

```objectivec
//EditorViewInput.h
//声明EditorViewInput是可路由的
@protocol EditorViewInput: ZIKViewRoutable
@property (nonatomic, weak) id<EditorDelegate> delegate;
- (void)constructForCreatingNewNote;
@end
```
```objectivec
@interface EditorViewController: UIViewController <EditorViewInput>
@end
```

为`EditorViewController`创建一个`ZIKViewRouter`的子类：

```objectivec
//EditorViewRouter.h
@interface EditorViewRouter : ZIKViewRouter
@end
```
```objectivec
//EditorViewRouter.m

//声明 EditorViewController 是可路由的 UIViewController
@interface EditorViewController (EditorViewRouter) <ZIKRoutableView>
@end
@implementation EditorViewController (EditorViewRouter)
@end

@implementation EditorViewRouter

//注册当前 Router 所管理的 view 和 protocol
+ (void)registerRoutableDestination {
    //把 EditorViewController 和对应的 Router 子类进行注册，一个 Router 可以注册多个界面，一个界面也可以使用多个 Router
    [self registerView:[EditorViewController class]];
    
    //注册 EditorViewInput，注册后就可以用此 protocol 获取此 router
    [self registerViewProtocol:ZIKRoutable(EditorViewInput)];
}

//返回需要获取的目的模块
- (nullable EditorViewController *)destinationWithConfiguration:(ZIKViewRouteConfiguration *)configuration {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    EditorViewController *destination = [sb instantiateViewControllerWithIdentifier:@"EditorViewController"];
    return destination;
}

//来自 storyboard 的 destination，是否需要让 source view controller 进行配置
- (BOOL)destinationFromExternalPrepared:(EditorViewController *)destination {
    if (destination.delegate != nil) {
        return YES;
    }
    return NO;
}

//在执行路由前配置模块，执行依赖注入
- (void)prepareDestination:(EditorViewController *)destination configuration:(ZIKViewRouteConfiguration *)configuration {
    //为 EditorViewController 注入依赖
}

//配置完毕，检查是否配置正确
- (void)didFinishPrepareDestination:(EditorViewController *)destination configuration:(ZIKViewRouteConfiguration *)configuration {
    
}

//路由时的 AOP 回调
+ (void)router:(nullable ZIKViewRouter *)router willPerformRouteOnDestination:(EditorViewController *)destination fromSource:(id)source {
    
}
+ (void)router:(nullable ZIKViewRouter *)router didPerformRouteOnDestination:(EditorViewController *)destination fromSource:(id)source {
    
}
+ (void)router:(nullable ZIKViewRouter *)router willRemoveRouteOnDestination:(EditorViewController *)destination fromSource:(id)source {
    
}
+ (void)router:(nullable ZIKViewRouter *)router didRemoveRouteOnDestination:(EditorViewController *)destination fromSource:(id)source {
    
}

@end
```
</details>

在继承时可以指定泛型参数，参考[Type Checking](TypeChecking.md#泛型)。

## Router 子类的优点

* 离散式管理，让每个模块自由管理路由过程
* 每个模块可以自定义界面跳转的方式，例如首页 tabbar 的切换
* 极强的可扩展性，可以进行非常多的自定义功能扩展
* 支持多个 protocol
* 支持多种类型的对象，例如可以根据不同系统版本，返回不同的控件
* 支持自定义操作，例如自定义跳转方式
* 支持处理界面跳转的 AOP
* 支持自定义事件

## 非 router 子类

如果你的类很简单，并不需要用到 router 子类，直接注册类即可：

```swift
ZIKAnyViewRouter.register(RoutableView<EditorViewInput>(), forMakingView: EditorViewController.self)
```

<details><summary>Objective-C Sample</summary>

```objectivec
[ZIKViewRouter registerViewProtocol:ZIKRoutable(EditorViewInput) forMakingView:[EditorViewController class]];
```

</details>

在使用时会直接用`[[RegisteredClass alloc] init]`创建对象。

**注意：如果你注册的是 Swift 类，而且有自定义 init 方法，则不能直接注册类，否则在使用时会 crash，因为此时不能直接用 OC runtime 创建对象**。

或者用 block 自定义创建对象的方式：

```swift
ZIKAnyViewRouter.register(RoutableView<EditorViewInput>(), 
                 forMakingView: EditorViewController.self) { (config, router) -> EditorViewInput? in
                     EditorViewController *destination = ... // 实例化 view controller
                     return destination;
        }

```

<details><summary>Objective-C Sample</summary>

```objectivec
[ZIKViewRouter
    registerViewProtocol:ZIKRoutable(EditorViewInput)
    forMakingView:[EditorViewController class]
    making:^id _Nullable(ZIKViewRouteConfiguration *config, ZIKViewRouter *router) {
        EditorViewController *destination = ... // 实例化 view controller
        return destination;
 }];
```

</details>

或者用指定 C 函数创建对象：

```swift
function makeEditorViewController(config: ViewRouteConfig) -> EditorViewInput? {
    NoteEditorViewController *destination = ... // 实例化 view controller
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

或者使用其他更复杂的 block 创建：

```swift
ZIKViewRoute<EditorViewController, ViewRouteConfig>
    .make(withDestination: EditorViewController.self,
          makeDestination: { (config, router) -> EditorViewController? in
            return EditorViewController()
    })
    .register(RoutableView<EditorViewInput>())
```

<details><summary>Objective-C Sample</summary>

```objectivec
[ZIKViewRoute<EditorViewController *, ZIKViewRouteConfig *> 
	makeRouteWithDestination:[EditorViewController class] 
	makeDestination:^ EditorViewController * _Nullable(ZIKViewRouteConfig * _Nonnull config, __kindof ZIKRouter<EditorViewController *,ZIKViewRouteConfig *,ZIKViewRemoveConfiguration *> * _Nonnull router) {
        return [[EditorViewController alloc] init];
    }];
```
</details>

---
#### 下一节：[模块注册](ModuleRegistration.md)