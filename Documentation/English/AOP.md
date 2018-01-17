# AOP

ZIKViewRouter will be notified when it's registered view was performed or removed.

You can override these AOP methods in router:

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

<details><summary>Objective-C Sample</summary>

```objectivec
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

When registered view's state changes, all it's routers will be notified, even the view's state change is not caused by router.

See comments in these methods for more details.