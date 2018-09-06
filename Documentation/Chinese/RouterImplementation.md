# 创建路由

ZIKRouter 的设计使用了抽象工厂模式，你需要为模块（产品）创建对应的 router 子类（工厂子类），然后在子类中实现 router 的接口即可，而无需对模块本身做出修改。

例如，要为`EditorViewController`创建路由。

Swift示例：

```swift
protocol NoteEditorInput {
    weak var delegate: EditorDelegate? { get set }
    func constructForCreatingNewNote()
}

class EditorViewController: UIViewController, NoteEditorInput {
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
//声明 NoteEditorInput 是可路由的
extension RoutableView where Protocol == NoteEditorInput {
    init() { self.init(declaredProtocol: Protocol.self) }
}

class EditorViewRouter: ZIKViewRouter<EditorViewController, ZIKViewRouteConfiguration> {
    //注册当前 Router 所管理的 view 和 protocol
    override class func registerRoutableDestination() {
        //把 EditorViewController 和对应的 Router 子类进行注册，一个 Router 可以注册多个界面，一个界面也可以使用多个 Router
        registerView(EditorViewController.self)
        
        //注册 NoteEditorInput，注册后就可以用此 protocol 获取此 router
        register(RoutableView<NoteEditorInput>())
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
//NoteEditorInput.h
//声明NoteEditorInput是可路由的
@protocol NoteEditorInput: ZIKViewRoutable
@property (nonatomic, weak) id<EditorDelegate> delegate;
- (void)constructForCreatingNewNote;
@end
```
```objectivec
@interface EditorViewController: UIViewController <NoteEditorInput>
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
    
    //注册 NoteEditorInput，注册后就可以用此 protocol 获取此 router
    [self registerViewProtocol:ZIKRoutable(NoteEditorInput)];
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

## 通过 Block 创建

如果不想使用 router 子类来添加路由，也可以用轻量化的 block 来注册：

```swift
ZIKViewRoute<EditorViewController, ViewRouteConfig>
    .make(withDestination: EditorViewController.self,
          makeDestination: { (config, router) -> EditorViewController? in
            return EditorViewController()
    })
    .register(RoutableView<NoteEditorInput>())
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