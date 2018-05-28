# Error Handle

ZIKRouter will check and log error information.

Errors can be detected:

* Wrong configuration when performing route
* The destination doesn't support the route type to perform
* The view was displayed again when it's still displaying, and produces `Unbalanced Transition` error
* Source view was not in any navigation stack when performing push
* Destination view is UINavigationController or UISplitViewController when performing push
* Source view already presents another view when performing present
* Source view was not in view hierarchy when performing present
* Segue was cancelled when performing segue
* Perform multi view routes at same time
* Destination not exists when removing (the module may be unloaded, or the view may be removed from view hierarchy)
* Circular dependency

Use `globalErrorHandler:` to log these errors:

```swift
ZIKAnyViewRouter.globalErrorHandler = { (router, action, error) in
    print("❌ZIKRouter Error: \(router)'s action \(action) catch error: \(error)!")
}
```

<details><summary>Objective-C Sample</summary>

```objectivec
[ZIKViewRouter setGlobalErrorHandler:^(ZIKViewRouter * _Nullable router,
                                           ZIKRouteAction routeAction,
                                           NSError * _Nonnull error) {
        NSLog(@"❌ZIKRouter Error: router's action (%@) catch error! code:%@, description: %@,\nrouter:(%@)", routeAction, @(error.code), error.localizedDescription,router);
    }];
```

</details>

You can handle the error when performing route:

```swift
Router.perform(
            to: RoutableView<NoteEditorInput>(),
            path: .push(from: self),
            configuring: { (config, _) in
                config.errorHandler = { (action, error) in
                    //Transition failed
                }
        })
```

<details><summary>Objective-C Sample</summary>

```objectivec
[ZIKRouterToView(NoteEditorInput)
	          performPath:ZIKViewRoutePath.pushFrom(self)
	          configuring:^(ZIKViewRouteConfiguration *config) {
	              config.errorHandler = ^(ZIKRouteAction routeAction, NSError *error) {
	                  //Transition failed
	              };
	          }];
```

</details>

---
#### Next section: [Storyboard and Auto Create](Storyboard.md)