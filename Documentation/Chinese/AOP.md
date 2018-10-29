# AOP

ZIKViewRouter 支持界面展示和消除时的 AOP 回调。

你可以在 router 子类里重写下列方法：

```swift
override class func router(_ router: ZIKAnyViewRouter?, willPerformRouteOnDestination destination: EditorViewController, fromSource source: Any?) {
        
}
override class func router(_ router: ZIKAnyViewRouter?, didPerformRouteOnDestination destination: EditorViewController, fromSource source: Any?) {
        
}
override class func router(_ router: ZIKAnyViewRouter?, willRemoveRouteOnDestination destination: EditorViewController, fromSource source: Any?) {
        
}
override class func router(_ router: ZIKAnyViewRouter?, didRemoveRouteOnDestination destination: EditorViewController, fromSource source: Any?) {
        
}

```

<details><summary>Objective-C示例</summary>

```objectivec
//路由时的 AOP 回调
+ (void)router:(nullable ZIKViewRouter *)router willPerformRouteOnDestination:(EditorViewController *)destination fromSource:(id)source {
    
}
+ (void)router:(nullable ZIKViewRouter *)router didPerformRouteOnDestination:(EditorViewController *)destination fromSource:(id)source {
    
}
+ (void)router:(nullable ZIKViewRouter *)router willRemoveRouteOnDestination:(EditorViewController *)destination fromSource:(id)source {
    
}
+ (void)router:(nullable ZIKViewRouter *)router didRemoveRouteOnDestination:(EditorViewController *)destination fromSource:(id)source {
    
}
```
</details>

当此 router 所注册的 view 在展示和消除时，router 会收到这些回调方法，即便展示和消除并不是通过 router 执行的。你可以为特定的界面添加监听，也可以为 router 注册 UIViewController类，为所有 UIViewController 添加监听。

具体的回调时机，见对应方法的注释。

## 内存泄露检测

有了 AOP，就能快速做出一些简单工具，例如在移除路由时进行内存泄露检测。因为界面在移除之后就应该及时释放了。

ZIKRouter 中已经添加了这一功能，通过`detectMemoryLeakDelay`接口设置检测时间。例如在 2 秒之后未释放，则视为内存泄露：

```
ZIKRouter memory leak checker:⚠️ destination is not dealloced after removed, make sure there is no retain cycle:
<DetailViewController: 0x7f9512e09900>
Its parentViewController: <UINavigationController: 0x7f9513847a00>
The UIKit system may hold the object, if the view is still in view hierarchy, you can ignore this.
```
这只是非常简单的检测方式。UIKit 可能会在界面移除之后仍然持有界面。你需要检查的是释放存在循环引用。

#### 下一节：[依赖注入](DependencyInjection.md)