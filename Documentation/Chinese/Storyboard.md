# Storyboard 和 自动注入

ZIKViewRouter 支持 storyboard。

## UIViewController

当调用`instantiateInitialViewController`和执行 segue 时，如果 view controller 遵守`ZIKRoutableView`，将会查找并创建此 view controller 类及其父类所注册的 router，接着调用 router 的`-destinationFromExternalPrepared:`。

如果`-destinationFromExternalPrepared:`返回 NO，说明需要让源界面对目的界面做出一些配置，此时会调用 segue 的 sourceViewController 的`-prepareDestinationFromExternal:configuration:`方法，如果 sourceViewController 没有实现此方法，将会记录错误。

最后会调用 router 的`-prepareDestination:configuration:`和`-didFinishPrepareDestination:configuration:`，让 router 配置 view controller。

当你直接使用 destination 进行跳转时，例如直接调用`[source presentViewController:destination animated:NO completion:nil]`，虽然也可以检测到界面跳转时的 AOP 回调，但是却无法像 segue 一样，查找源界面，因此也就不会创建 router。因此如果一个界面需要用 router 进行依赖注入和固定配置，就应该避免使用直接跳转的方式。

## UIView

同理，当调用`-addSubview:` 时，也会检查 UIView 是否遵守`ZIKRoutableView`，查找并创建此 UIView 类及其父类所注册的 router。

如果 router 的`-destinationFromExternalPrepared:`返回 NO，说明需要让源界面对目的界面做出一些配置。这时需要在 UIView 上查找源界面，会使用`nextResponder`查找 UIView 的 view controller 及其 parent view controller，取层级最近的一个自定义 view controller。这个自定义 view controller 是一个自定义的 UIViewController 类，并且不是 `UINavigationController`,`UITabBarController`,`UISplitViewController`这些容器类型。

但是当 UIView 不显示在视图界面上时，是无法用`nextResponder`获取 view controller 的，此时会延迟到`-willMoveToSuperview:`,`-didMoveToSuperview`,`willMoveToWindow:`,`didMoveToWindow`里查找源界面并执行配置。

如果 UIView 在从父 view 上移除之前，一直没有显示在界面上，因此一直没有得到配置，会给出断言错误。例如：

* UIView 添加到了某个父 view，但是父 view 一直没有被添加到其他父 view 上
* UIView 添加到了 UIWindow 上

建议总是使用 router 来获取对应的 view。

---
#### 下一节：[AOP](AOP.md)