# AOP

ZIKViewRouter will be notified when it's registered view was performed or removed.

You can override these AOP methods in router:

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

When registered view's state changes, all its routers will be notified, even the view's state change is not caused by router.

See comments in these methods for more details.

## Detect Memorey Leak

With AOP, we can write some debug tools easily, such as memory leak detector in `didRemove`. UIViewController and UIView should be dealloced after it's removed.

ZIKRouter already has this feature. You can use `detectMemoryLeakDelay` to set delay time that destination should be dealloced after removed. For example, if the view is not dealloced after 2 second, it's considered leaked:

```
ZIKRouter memory leak checker:⚠️ destination is not dealloced after removed, make sure there is no retain cycle:
<DetailViewController: 0x7f9512e09900>
Its parentViewController: <UINavigationController: 0x7f9513847a00>
The UIKit system may hold the object, if the view is still in view hierarchy, you can ignore this.
```
This is a very simple implementation. You should make sure there is no retain cycle.

---
#### Next section: [Dependency Injection](DependencyInjection.md)