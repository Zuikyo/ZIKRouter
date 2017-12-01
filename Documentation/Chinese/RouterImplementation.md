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
为`EditorViewController `创建一个`ZIKViewRouter`的子类：

```swift
//EditorViewRouter.swift

//声明EditorViewController是可路由的UIViewController
extension EditorViewController: ZIKRoutableView {

}
//声明NoteEditorInput是可路由的
extension RoutableView where Protocol == NoteEditorInput {
    init() { }
}

class EditorViewRouter: ZIKViewRouter<EditorViewController, ZIKViewRouteConfiguration, ZIKViewRemoveConfiguration> {
    //注册当前Router所管理的view和protocol
    override class func registerRoutableDestination() {
        registerView(EditorViewController.self)
        Registry.register(RoutableView<NoteEditorInput>(), forRouter: self)
    }
    //检查模块内使用的外部路由依赖是否有效
    override class func _autoRegistrationDidFinished() {
        //Make sure all routable dependencies in this module is available.
        assert((Registry.router(to: RoutableService<SomeServiceInput>()) != nil))
    }
    
    //返回需要获取的目的模块
    override func destination(with configuration: ZIKViewRouteConfiguration) -> EditorViewController? {
        let sb = UIStoryboard.init(name: "Main", bundle: nil)
        let destination = sb.instantiateViewController(withIdentifier: "EditorViewController") as! EditorViewController
        return destination
    }
    
    override static func destinationPrepared(_ destination: EditorViewController) -> Bool {
        if (destination.delegate != nil) {
            return true
        }
        return false
    }
    
    //在执行路由前配置模块，执行依赖注入
    override func prepareDestination(_ destination: EditorViewController, configuration: ZIKViewRouteConfiguration) {
        if let dest = destination as? EditorViewController {
            //为EditorViewController注入依赖
        }
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
@interface EditorViewRouter : ZIKViewRouter <ZIKViewRouterProtocol>
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

//实现ZIKViewRouterProtocol的接口

//注册当前Router所管理的view和protocol
+ (void)registerRoutableDestination {
    //把EditorViewController和对应的Router子类进行注册，一个Router可以注册多个界面，一个界面也可以使用多个Router
    [self registerView:[EditorViewController class]];
    
    //注册NoteEditorInput
    [self registerViewProtocol:@protocol(NoteEditorInput)];
}

//返回需要获取的目的模块
- (nullable EditorViewController *)destinationWithConfiguration:(ZIKViewRouteConfiguration *)configuration {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    EditorViewController *destination = [sb instantiateViewControllerWithIdentifier:@"EditorViewController"];
    return destination;
}

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