# 执行路由

执行路由时，需要使用对应模块的 router 子类。ZIKRouter 提供了通过 protocol 动态获取 router 子类的方法，而且可以利用 protocol 对目的模块进行运行时的依赖注入。

ZIKRouter 是用 Objective-C 写的，在 swift 里则需要使用`ZRouter`，这是对`ZIKRouter`在swift 上的封装，提供了更加 swifty 的语法。

## Type Safe Perform

使用声明过的 protocol 执行路由，路由操作是类型安全的。

```swift
class TestViewController: UIViewController {
    func showEditorViewController() {
        Router.perform(
            to: RoutableView<EditorViewInput>(),
            path: .push(from: self),
            configuring: { (config, _) in
                //路由相关的设置
                config.successHandler = { destination in
                    //跳转成功处理
                }
                config.errorHandler = { (action, error) in
                    //跳转失败处理
                }
                //配置目的界面
                config.prepareDestination = { [weak self] destination in
                    //destination 被 swift 自动推断为 EditorViewInput 类型
                    //配置 editor 界面
                    destination.delegate = self
                    destination.constructForCreatingNewNote()
                }
        })
    }
}
```

## Switchable Perform

当某个界面跳转是从某几个界面中选择时，可以使用`Switchable`结构体。在保留了编译检查的同时，也能引入一定程度的动态性。

```swift
enum RequestError: Error {
    case invalidAccount
    case networkNotConnected
}

class TestViewController: UIViewController {
    func showViewForError(_ error: RequestError) {
        var switchableView: SwitchableView
        switch error {
        case .invalidAccount:
            switchableView = SwitchableView(RoutableView<LoginViewInput>())
        case .networkNotConnected:
            switchableView = SwitchableView(RoutableView<NetworkDisconnectedViewInput>())
        }
        Router.to(switchableView)?.perform(path: .push(from: self))
    }
}
```

## Perform in Objective-C

在 Objective-C 中也能提供编译时的类型安全检查，不过由于 OC 的动态特性，并没有像 swift 中那样严格。

```objectivec
@implementation TestViewController

- (void)showEditorViewController {
	//用 EditorViewInput 获取router类
	[ZIKRouterToView(EditorViewInput)
	          performPath:ZIKViewRoutePath.presentModallyFrom(self)
	          configuring:^(ZIKViewRouteConfiguration *config) {
	              config.animated = YES;
	              //配置目的界面
	              config.prepareDestination = ^(id<EditorViewInput> destination) {
	                  destination.delegate = self;
	                  [destination constructForCreatingNewNote];
	              };
	              config.successHandler = ^(id<EditorViewInput> destination) {
	                  //界面显示完毕
	              };
	          }];
}
```

比起`performPath:configuring:`方法，`performPath:strictConfiguring:`提供了更严格的编译检查： 

```objectivec
@implementation TestViewController

- (void)showEditorViewController {
	[ZIKRouterToView(EditorViewInput)
	          performPath:ZIKViewRoutePath.presentModallyFrom(self)
	          strictConfiguring:^(ZIKViewRouteStrictConfiguration<id<EditorViewInput>> *config,
	          					  ZIKViewRouteConfiguration *module) {
	              config.animated = YES;
	              //Type of prepareDestination block changes with the router's generic parameters.
	              config.prepareDestination = ^(id<EditorViewInput> destination){
	                  destination.delegate = self;
	                  [destination constructForCreatingNewNote];
	              };
	              config.successHandler = ^(id<EditorViewInput> destination) {
	                  //Transition completed
	              };
	          }];
}
```

`ZIKViewRouteStrictConfiguration`的类型会随着泛型值而改变，对应属性和方法的类型也会随着改变。当你改变了 protocol，编译器会帮助你进行检查。

不过 Xcode 的自动补全在这种情况下有 bug。调用`ZIKViewRouteStrictConfiguration`的方法时参数没有被正确地补全，你需要手动改成正确的参数类型。

## 获取模块

如果不想执行路由，只是想获取模块，可以使用`makeDestination`方法。在获取模块时，可以在 preparation block 里进行依赖注入。

Swift示例：

```swift
///time service 的接口
protocol TimeServiceInput {
    func currentTimeString() -> String
}
```
```swift
class TestViewController: UIViewController {
    @IBOutlet weak var timeLabel: UILabel!
    
    func callTimeService() {
        //获取 TimeServiceInput 对应的模块
        let timeService = Router.makeDestination(
            to: RoutableService<TimeServiceInput>(),
            preparation: { destination in
            //配置 service
        })
        //调用 service
        timeLabel.text = timeService.currentTimeString()
    }
}
```

<details><summary>Objective-C示例</summary>

```objectivec
///time service 的接口
@protocol TimeServiceInput <ZIKServiceRoutable>
- (NSString *)currentTimeString;
@end
```

```objectivec
@interface TestViewController ()
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@end

@implementation TestViewController

- (void)callTimeService {
   //用 protocol 获取对应的模块
   id<TimeServiceInput> timeService = [ZIKRouterToService(TimeServiceInput) makeDestination];
   self.timeLabel.text = [timeService currentTimeString];    
}

```

</details>

## 自定义路由操作

### View Router

有时候某些界面需要自定义跳转动画，或者特殊的跳转方式，例如首页 tabbar 的切换，可以在 router 中进行自定义。

如果要进行自定义的界面跳转，需要：

1. 重写`supportedRouteTypes`，添加`ZIKViewRouteTypeCustom`
2. 如果需要判断 configuration 是否正确，则重写`-validateCustomRouteConfiguration:removeConfiguration:`
3. 重写`canPerformCustomRoute`判断当前是否可以执行路由，可以则返回 true
4. 重写`performCustomRouteOnDestination:fromSource:configuration:`，执行自定义界面跳转操作，如果自定义操作是执行 segue，则在执行时需要使用`_performSegueWithIdentifier:fromSource:sender:`
5. 用`beginPerformRoute`、`endPerformRouteWithSuccess`、`endPerformRouteWithError:`改变路由状态

### Service Router

Service router 只是用于返回一个对象。如果你需要自定义 service router 的路由操作，需要：

1. 重写`-performRouteOnDestination:configuration:`
2. 在执行自定义操作前用 `prepareDestinationForPerforming`配置 destination
3. 执行完自定操作后，用 `endPerformRouteWithSuccess`、 `endPerformRouteWithError`改变路由状态

Service router 的使用和 view router 也是类似的，只是去掉了界面跳转的封装，要比 view router 更加简单和通用。而大多数 service 并不需要 view controller 那样的一个路由过程，只是需要获取某个 service 模块。此时可以使用 Make Destination。

执行路由之后，会得到一个 router 实例，你可以持有这个 router 实例，在之后移除路由，参考[Remove Route](RemoveRoute.md)。

## Perform on Destination

如果你从其他地方得到了一个 destination 对象，你可以用对应的 router 在这个 destination 上执行路由。

例如，某个 UIViewController 支持 3D touch，实现了`UIViewControllerPreviewingDelegate`：

```swift
class SourceViewController: UIViewController, UIViewControllerPreviewingDelegate {
	func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
	     //返回 destination UIViewController， 让系统执行预览
        let destination = Router.makeDestination(to: RoutableView<DestinationViewInput>())
        return destination
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        guard let destination = viewControllerToCommit as? DestinationViewInput else {
            return
        }
        //跳转到 destination
        Router.to(RoutableView<DestinationViewInput>())?.perform(onDestination: destination, path: .presentModally(from: self))
}

```

<details><summary>Objective-C Sample</summary>

```objectivec
@implementation SourceViewController

- (nullable UIViewController *)previewingContext:(id <UIViewControllerPreviewing>)previewingContext viewControllerForLocation:(CGPoint)location {
    //返回 destination UIViewController， 让系统执行预览
    UIViewController<DestinationViewInput> *destination = [ZIKRouterToView(DestinationViewInput) makeDestination];
    return destination;
}

- (void)previewingContext:(id <UIViewControllerPreviewing>)previewingContext commitViewController:(UIViewController *)viewControllerToCommit {
    //跳转到 destination
    UIViewController<DestinationViewInput> *destination;
    if ([viewControllerToCommit conformsToProtocol:@protocol(DestinationViewInput)]) {
        destination = viewControllerToCommit;
    } else {
        return;
    }
    [ZIKRouterToView(DestinationViewInput) performOnDestination:destination path:ZIKViewRoutePath.presentModallyFrom(self)];
}

@end
```

</details>

## Prepare on Destination

如果你并不想执行路由，而只是想配置某个 destination 对象，可以用 router 执行 prepare 操作。这样， router 内部对 destination 对象执行的所有依赖注入操作就都会生效，destination 就被正确地配置好了。

```swift
var destination: DestinationViewInput = ...
Router.to(RoutableView<DestinationViewInput>())?.prepare(destination: destination, configuring: { (config, _) in
            config.prepareDestination = { destination in
                // Prepare
            }
        })

```

<details><summary>Objective-C Sample</summary>

```objectivec
UIViewController<DestinationViewInput> *destination = ...
[ZIKRouterToView(DestinationViewInput) prepareDestination:destination configuring:^(ZIKViewRouteConfiguration *config) {
            config.prepareDestination = ^(id<DestinationViewInput> destination) {
                // Prepare
            };
        }];
```

</details>

## URL Router

如果你的 app 要支持 URL scheme，你可以用 url 来查找 router，执行界面跳转。

```swift
ZIKAnyViewRouter.performURL("app://editor/test_note", path: .push(from: self))
```

<details><summary>Objective-C Sample</summary>

```objectivec
[ZIKAnyViewRouter performURL:@"app://editor/test_note" path:ZIKViewRoutePath.pushFrom(self)];
```

</details>

以及处理 URL Scheme:

```swift
// 在你的 app 内部，或者在其他 app 内执行 openURL
func openURL(_ url: NSURL) {
    // app://editor/test_note
    UIApplication.shared.openURL(url)
}

public func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
    let urlString = url.absoluteString
    if let _ = ZIKAnyViewRouter.performURL(urlString, fromSource: self.rootViewController) {
        return true
    } else if let _ = ZIKAnyServiceRouter.performURL(urlString) {
        return true
    } else {
        return false
    }
}
```

<details><summary>Objective-C Sample</summary>

```objectivec
// 在你的 app 内部，或者在其他 app 内执行 openURL
- (void)openURL:(NSURL *)url {
    // app://editor/test_note
    [[UIApplication sharedApplication] openURL: url];
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
    if ([ZIKAnyViewRouter performURL:urlString fromSource:self.rootViewController]) {
        return YES;
    } else if ([ZIKAnyServiceRouter performURL:urlString]) {
        return YES;
    } else {
        return NO;
    }
}
```

</details>

## 自定义事件

如果想让模块处理自定义事件，可以遍历所有的 router 类发送事件：

```swift
func applicationDidEnterBackground(_ application: UIApplication) {
        // 发送自定义事件
        Router.enumerateAllViewRouters { (routerType) in
            if routerType.responds(to: #selector(applicationDidEnterBackground(_:))) {
                routerType.perform(#selector(applicationDidEnterBackground(_:)), with: application)
            }
        }
        Router.enumerateAllServiceRouters { (routerType) in
            if routerType.responds(to: #selector(applicationDidEnterBackground(_:))) {
                routerType.perform(#selector(applicationDidEnterBackground(_:)), with: application)
            }
        }
    }
```
<details><summary>Objective-C Sample</summary>

```objectivec
- (void)applicationDidEnterBackground:(UIApplication *)application {
    // 发送自定义事件
    [ZIKAnyViewRouter enumerateAllViewRouters:^(Class  _Nonnull __unsafe_unretained routerClass) {
        if ([routerClass respondsToSelector:@selector(applicationDidEnterBackground:)]) {
            [routerClass applicationDidEnterBackground:application];
        }
    }];
    [ZIKAnyServiceRouter enumerateAllServiceRouters:^(Class  _Nonnull __unsafe_unretained routerClass) {
        if ([routerClass respondsToSelector:@selector(applicationDidEnterBackground:)]) {
            [routerClass applicationDidEnterBackground:application];
        }
    }];
}
```

</details>

如果模块需要处理自定义事件，只需要在 router 中实现即可：

```swift
class EditorViewRouter: ZIKViewRouter<EditorViewController, ViewRouteConfig> {
    ...
    @objc class func applicationDidEnterBackground(_ application: UIApplication) {
        // 处理自定义事件
    }
```
<details><summary>Objective-C Sample</summary>

```objectivec
@implementation EditorViewRouter
...
+ (void)applicationDidEnterBackground:(UIApplication *)application {
	// 处理自定义事件
}

@end
```

</details>

---
#### 下一节：[移除路由](RemoveRoute.md)