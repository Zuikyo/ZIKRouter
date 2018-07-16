# Remove Route

After performing a route, you can remove the route with the router for dismissing a view or unloading a module.

Swift Sample

```swift
class TestViewController: UIViewController {
    var editorRouter: DestinationViewRouter<NoteEditorInput>?
    
    func showEditor() {
        //Hold router for this routing
        editorRouter = Router.perform(to: RoutableView<NoteEditorInput>(), path: .push(from: self))
    }
    
    func removeEditor() {
        guard let router = editorRouter, router.canRemove else {
            return
        }
        //Remove the view with the router
        router.removeRoute(configuring: { (config) in
            config.prepareDestination = { destination in
                //Prepare the destination before removing
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

<details><summary>Objective-C Sample</summary>

```objectivec
@interface TestViewController()
@property (nonatomic, strong) ZIKViewRouter *editorRouter;
@end
@implementation TestViewController: UIViewController

- (void)showEditor {
  self.editorRouter = [ZIKRouterToView(NoteEditorInput) performPath:ZIKViewRoutePath.pushFrom(self)];
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

For service router, you can unload the module in router's remove interface, such as stop some processing and release resources.

# Custom Remove

## View Router

Steps to support custom transition for removing a view:

1. Override `supportedRouteTypes`, add`ZIKViewRouteTypeCustom`
2. Override `removeCustomRouteOnDestination:fromSource:removeConfiguration:configuration:` to do custom transition
3. Manage router's state with `beginRemoveRouteFromSource:`、`endRemoveRouteWithSuccessOnDestination:fromSource:`、`endRemoveRouteWithError:`

You can also override `-canRemoveCustomRoute` to check whether the view can be removed now.

## Service Router

Service router do nothing when removing in default.

Steps to support removing a service:

1. Override `canRemove` or `canRemoveCustomRoute`, if the service can be removed, return true
2. Override `-removeDestination:removeConfiguration:`, check whether the destination exists, and do unload action
3. Call `-prepareDestinationBeforeRemoving` to let the performer prepare the destination before unloading
4. Manage the router's state with `beginRemoveRoute`、`endRemoveRouteWithSuccess`、`endRemoveRouteWithError:`

---
#### Next section: [Make Destination](MakeDestination.md)