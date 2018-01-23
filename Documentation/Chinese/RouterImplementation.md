# 创建路由

ZIKRouter的设计使用了抽象工厂模式，你需要为模块（产品）创建对应的router子类（工厂子类），然后在子类中实现router的接口即可，而无需对模块本身做出修改。

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
为`EditorViewController`创建一个`ZIKViewRouter`的子类：

```swift
//EditorViewRouter.swift

//声明EditorViewController是可路由的UIViewController
extension EditorViewController: ZIKRoutableView {

}
//声明NoteEditorInput是可路由的
extension RoutableView where Protocol == NoteEditorInput {
    init() { }
}

class EditorViewRouter: ZIKViewRouter<EditorViewController, ZIKViewRouteConfiguration> {
    //注册当前Router所管理的view和protocol
    override class func registerRoutableDestination() {
        //把EditorViewController和对应的Router子类进行注册，一个Router可以注册多个界面，一个界面也可以使用多个Router
        registerView(EditorViewController.self)
        
        //注册NoteEditorInput，注册后就可以用此protocol获取此router
        register(RoutableView<NoteEditorInput>())
    }
    //检查模块内使用的外部路由依赖是否有效
    override class func _registrationDidFinished() {
        //Make sure all routable dependencies in this module is available.
        assert(Router.to(RoutableService<SomeServiceInput>()) != nil)
    }
    
    //返回需要获取的目的模块
    override func destination(with configuration: ZIKViewRouteConfiguration) -> EditorViewController? {
        let sb = UIStoryboard.init(name: "Main", bundle: nil)
        let destination = sb.instantiateViewController(withIdentifier: "EditorViewController") as! EditorViewController
        return destination
    }
    
    //来自storyboard的destination，是否需要让source view controller进行配置
    override static func destinationPrepared(_ destination: EditorViewController) -> Bool {
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
    
    //View Router的AOP回调
    override class func router(_ router: DefaultViewRouter?, willPerformRouteOnDestination destination: EditorViewController, fromSource source: Any?) {
        
    }
    override class func router(_ router: DefaultViewRouter?, didPerformRouteOnDestination destination: EditorViewController, fromSource source: Any?) {
        
    }
    override class func router(_ router: DefaultViewRouter?, willRemoveRouteOnDestination destination: EditorViewController, fromSource source: Any?) {
        
    }
    override class func router(_ router: DefaultViewRouter?, didRemoveRouteOnDestination destination: EditorViewController, fromSource source: Any?) {
        
    }
}
```

<details><summary>Objecive-C示例</summary>

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

//声明EditorViewController是可路由的UIViewController
@interface EditorViewController (EditorViewRouter) <ZIKRoutableView>
@end
@implementation EditorViewController (EditorViewRouter)
@end

@implementation EditorViewRouter

//注册当前Router所管理的view和protocol
+ (void)registerRoutableDestination {
    //把EditorViewController和对应的Router子类进行注册，一个Router可以注册多个界面，一个界面也可以使用多个Router
    [self registerView:[EditorViewController class]];
    
    //注册NoteEditorInput，注册后就可以用此protocol获取此router
    [self registerViewProtocol:ZIKRoutableProtocol(NoteEditorInput)];
}

//返回需要获取的目的模块
- (nullable EditorViewController *)destinationWithConfiguration:(ZIKViewRouteConfiguration *)configuration {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    EditorViewController *destination = [sb instantiateViewControllerWithIdentifier:@"EditorViewController"];
    return destination;
}

//来自storyboard的destination，是否需要让source view controller进行配置
+ (BOOL)destinationPrepared:(EditorViewController *)destination {
    if (destination.delegate != nil) {
        return YES;
    }
    return NO;
}

//在执行路由前配置模块，执行依赖注入
- (void)prepareDestination:(EditorViewController *)destination configuration:(ZIKViewRouteConfiguration *)configuration {
    //为EditorViewController注入依赖
}

//配置完毕，检查是否配置正确
- (void)didFinishPrepareDestination:(EditorViewController *)destination configuration:(ZIKViewRouteConfiguration *)configuration {
    
}

//路由时的AOP回调
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

如果不想使用router子类来添加路由，也可以用轻量化的block来注册：

```swift
Registry.register(destination: EditorViewController.self, routableProtocol: NoteEditorInput.self)
	.makeDestination({ config in
		return EditorViewController()
	})
	.prepareDestination({ destination in
		
	})
```

不过这个特性目前暂时还未发布。