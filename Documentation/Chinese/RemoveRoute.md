# 移除路由

执行路由之后，可以使用返回的 router 一键移除路由，例如消除已经显示的界面、销毁模块等操作。

Swift示例：

```swift
class TestViewController: UIViewController {
    var editorRouter: DestinationViewRouter<EditorViewInput>?
    
    func showEditor() {
        //保存执行路由后的 router 实例
        editorRouter = Router.perform(to: RoutableView<EditorViewInput>(), path: .push(from: self))
    }
    
    func removeEditor() {
        guard let router = editorRouter, router.canRemove else {
            return
        }
        //使用之前保存的 router 移除界面
        router.removeRoute(configuring: { (config) in
            config.prepareDestination = { destination in
                //移除路由前的操作 destination
            }
            config.successHandler = {
                print("remove editor success")
            }
            config.errorHandler = {
                print("remove failed, error:%@",error)
            }
        })
        editorRouter = nil
    }
}
```

<details><summary>Objective-C示例</summary>

```objectivec
@interface TestViewController()
@property (nonatomic, strong) ZIKViewRouter *editorRouter;
@end
@implementation TestViewController: UIViewController

- (void)showEditor {
  self.editorRouter = [ZIKRouterToView(EditorViewInput) performPath:ZIKViewRoutePath.pushFrom(self)];
}

- (void)removeEditor {
  if ([self.editorRouter canRemove] == NO) {
      return;
  }
  [self.editorRouter removeRouteWithSuccessHandler:^{
      NSLog(@"remove editor success");
  } errorHandler:^(ZIKRouteAction routeAction, NSError *error) {
      NSLog(@"remove failed, error:%@",error);
  }];
  self.editorRouter = nil
}

@end
```

</details>

对于 service router，你可以在 router 内部的 remove 接口里进行模块销毁的操作。例如停止工作、释放资源等。

# 自定义移除路由

## View Router

如果要自定义移除界面操作，则需要：

1. 重写`supportedRouteTypes`，添加`ZIKViewRouteTypeCustom`
2. 重写`removeCustomRouteOnDestination:fromSource:removeConfiguration:configuration:`，进行自定义移除操作
3. 用`beginRemoveRouteFromSource:`、`endRemoveRouteWithSuccessOnDestination:fromSource:`、`endRemoveRouteWithError:`改变路由状态

另外，还可以重写`-canRemoveCustomRoute`判断当前是否能执行移除操作。

## Service Router

Service router 默认不支持移除操作。如果要用自定义移除操作来销毁模块，则：

1. 重写`canRemove`或者`canRemoveCustomRoute`，如果当前可以销毁模块，则返回 true
2. 重写`-removeDestination:removeConfiguration:`，判断 destination 是否存在，执行销毁操作
3. 在销毁操作前，调用`-prepareDestinationBeforeRemoving`通知使用者即将销毁
4. 在销毁模块后，调用`endRemoveRouteWithSuccess`、`endRemoveRouteWithError:`改变路由状态

---
#### 下一节：[自定义 configuration 传参](CustomConfiguration.md)