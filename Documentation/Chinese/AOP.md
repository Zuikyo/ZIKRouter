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

#### 下一节：[依赖注入](DependencyInjection.md)