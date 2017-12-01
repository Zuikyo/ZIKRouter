# 移除路由

执行路由之后，可以使用返回的router一键移除路由，例如消除已经显示的界面、销毁模块等操作。

Swift示例：

```swift
class TestViewController: UIViewController {
    var editorRouter: DestinationViewRouter<NoteEditorInput>?
    
    func showEditor() {
        //保存执行路由后的router实例
        editorRouter = Router.perform(
            to: RoutableView<NoteEditorInput>(),
            from: self,
            configuring: { $0.routeType = .push }
            )
    }
    
    func removeEditor() {
        guard let router = editorRouter, router.canRemove else {
            return
        }
        //使用之前保存的router移除界面
        router.removeRoute(configuring: { (config, prepareDestination, _) in
            prepareDestination({ destination in
                //移除路由前的操作destination
            })
            config.successHandler = {
                print("remove editor success")
            }
            config.errorHandler = {
                print("remove failed, error:%@",error)
            }
        })
    }
}
```

<details><summary>Objecive-C示例</summary>

```objectivec
@interface TestViewController()
@property (nonatomic, strong) ZIKViewRouter *editorRouter;
@end
@implementation TestViewController: UIViewController

- (void)showEditor {
  self.editorRouter = [ZIKViewRouter.toView(@protocol(NoteEditorInput)) performFromSource:self routeType:ZIKViewRouteTypePush];
}

- (void)removeEditor {
  if ([self.editorRouter canRemove] == NO) {
      return;
  }
  [self.editorRouter removeRouteWithConfiguring:^{
      NSLog(@"remove editor success");
  } errorHandler:^(SEL routeAction, NSError *error) {
      NSLog(@"remove failed, error:%@",error);
  }];  
}

@end
```

</details>

对于service router，你可以在router内部的remove接口里进行模块销毁的操作。例如停止工作、释放资源等。