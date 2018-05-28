# 错误处理

ZIKRouter 对路由时会产生的错误进行了详细的识别和记录。

可以识别的错误有：

* 执行路由时，设置的参数不符合要求
* 跳转的界面不支持指定的跳转方式
* 在界面跳转的同时执行了第二次界面跳转，从而产生`Unbalanced Transition`错误
* 执行 push 界面时，源界面没有在任何 navigation 界面栈上
* 执行 push 界面时，被 push 的界面是 UINavigationController 或者 UISplitViewController
* 执行 present 界面时，源界面已经 present 了其他的界面
* 执行 present 界面时，源界面没有添加到视图树上
* 执行 segue 时，segue 在代理方法里被取消，导致没有执行界面跳转
* 同时执行了多次界面跳转
* 消除模块时，模块已经被释放，或者界面已经从视图树上移除
* 依赖注入时，发生了循环依赖导致无限递归

可以用`globalErrorHandler:`记录全局的错误记录：

```swift
ZIKAnyViewRouter.globalErrorHandler = { (router, action, error) in
    print("❌ZIKRouter Error: \(router)'s action \(action) catch error: \(error)!")
}
```

<details><summary>Objective-C示例</summary>

```objectivec
[ZIKViewRouter setGlobalErrorHandler:^(ZIKViewRouter * _Nullable router,
                                           ZIKRouteAction routeAction,
                                           NSError * _Nonnull error) {
        NSLog(@"❌ZIKRouter Error: router's action (%@) catch error! code:%@, description: %@,\nrouter:(%@)", routeAction, @(error.code), error.localizedDescription,router);
    }];
```

</details>

也可以在执行路由和移除路由时处理错误：

```swift
Router.perform(
            to: RoutableView<NoteEditorInput>(),
            path: .push(from: self),
            configuring: { (config, _) in
                config.errorHandler = { (action, error) in
                    //跳转失败处理
                }
        })
```

<details><summary>Objective-C示例</summary>

```objectivec
[ZIKRouterToView(NoteEditorInput)
	          performPath:ZIKViewRoutePath.pushFrom(self)
	          configuring:^(ZIKViewRouteConfiguration *config) {
	              config.errorHandler = ^(ZIKRouteAction routeAction, NSError *error) {
	                  //跳转失败处理
	              };
	          }];
```

</details>

---
#### 下一节：[Storyboard 和自动注入](Storyboard.md)