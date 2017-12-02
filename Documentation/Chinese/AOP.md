# AOP

ZIKViewRouter支持界面展示和消除时的AOP。

你可以在router子类里重写下列方法：

```swift
override class func router(_ router: DefaultViewRouter?, willPerformRouteOnDestination destination: EditorViewController, fromSource source: Any?) {
        
}
override class func router(_ router: DefaultViewRouter?, didPerformRouteOnDestination destination: EditorViewController, fromSource source: Any?) {
        
}
override class func router(_ router: DefaultViewRouter?, willRemoveRouteOnDestination destination: EditorViewController, fromSource source: Any?) {
        
}
override class func router(_ router: DefaultViewRouter?, didRemoveRouteOnDestination destination: EditorViewController, fromSource source: Any?) {
        
}

```

<details><summary>Objecive-C示例</summary>

```objectivec
//路由时的AOP回调
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

当此router所注册的view在展示和消除时，router会收到这些回调方法，即便展示和消除并不是通过router执行的。你可以为特定的界面添加监听，也可以为router注册UIViewController类，为所有UIViewController添加监听。

具体的回调时机，见对应方法的注释。