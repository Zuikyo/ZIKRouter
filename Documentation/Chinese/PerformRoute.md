# 执行路由

执行路由时，需要使用对应模块的router子类。ZIKRouter提供了通过protocol动态获取router子类的方法，而且可以利用protocol对目的模块进行运行时的依赖注入。

ZIKRouter是用Objective-C写的，在Swift里则需要使用`ZRouter`，这是对`ZIKRouter`在Swift上的封装，提供了更加Swifty的语法。

## Type Safe Perform

使用声明过的protocol执行路由，路由操作是类型安全的。

```swift
class TestViewController: UIViewController {
    func showEditorViewController() {
        Router.perform(
            to: RoutableView<NoteEditorInput>(),
            from: self,
            configuring: { (config, prepareDestiantion, _) in
                //路由相关的设置
                //设置跳转方式，支持push、present、show、showDetail、custom等多种方式
                config.routeType = ViewRouteType.push
                config.routeCompletion = { destination in
                    //跳转结束处理
                }
                config.errorHandler = { (action, error) in
                    //跳转失败处理
                }
                //配置目的界面
                prepareDestination({ destination in
                    //destination被Swift自动推断为NoteEditorInput类型
                    //配置editor界面
                    destination.delegate = self
                    destination.constructForCreatingNewNote()
                })
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
        case invalidAccount:
            switchableView = SwitchableView(RoutableView<LoginViewInput>())
        case networkNotConnected:
            switchableView = SwitchableView(RoutableView<NetworkDisconnectedViewInput>())
        }
        Router.to(switchableView)?.perform(from: self, routeType: .push)
    }
}
```

## Dynamic Perform

针对一些需要完全动态路由的场景，可以使用protocol的字符串名字来执行路由：

```swift
func handleOpenURLWithViewName(_ viewName: String) {
    Router.to(dynamicView: viewName)?.perform(from: self, routeType: .push)
    }

```
你应该只在必要的时候才使用这个API，因为当传入错误的字符串时，将不会执行路由。

## Perform in Objective-C

在Objective-C中，由于OC的动态特性，无法为router做到完美的安全。

```objectivec
@implementation TestViewController

- (void)showEditorViewController {
	//用EditorViewInput获取router类
	[ZIKRouterToView(NoteEditorInput)
	          performFromSource:self
	          configuring:^(ZIKViewRouteConfiguration *config) {
	              config.routeType = ZIKViewRouteTypePresentModally;
	              config.animated = YES;
	              //配置目的界面
	              config.prepareDestination = ^(id<NoteEditorInput> destination) {
	                  destination.delegate = self;
	                  [destination constructForCreatingNewNote];
	              };
	              config.routeCompletion = ^(id<NoteEditorInput> destination) {
	                  //界面显示完毕
	              };
	              config.errorHandler = ^(ZIKRouteAction routeAction, NSError *error) {
	                  //界面显示失败
	              };
	          }];
}
```

用`prepareDest` 或者 `prepareModule` block 来配置destination更加安全： 

```objectivec
@implementation TestViewController

- (void)showEditorViewController {
	[ZIKRouterToView(NoteEditorInput)
	          performFromSource:self
	          routeConfiguring:^(ZIKViewRouteConfiguration *config,
	          					  void (^prepareDest)(void (^)(id<NoteEditorInput>)),
                        		  void (^prepareModule)(void (^)(ZIKViewRouteConfig *))) {
	              config.routeType = ZIKViewRouteTypePresentModally;
	              config.animated = YES;
	              //Type of prepareDest block changes with the router's generic parameters.
	              prepareDest(^(id<NoteEditorInput> destination){
	                  destination.delegate = self;
	                  [destination constructForCreatingNewNote];
	              });
	              config.routeCompletion = ^(id<NoteEditorInput> destination) {
	                  //Transition completed
	              };
	              config.errorHandler = ^(ZIKRouteAction routeAction, NSError *error) {
	                  //Transition failed
	              };
	          }];
}
```

`prepareDest` 和 `prepareModule` block 的类型会随着router的泛型值而改变。当你改变了protocol，编译器会帮助你进行检查。

不过Xcode的自动补全在这种情况下有bug。`prepareDest` 和 `prepareModule`里的参数没有被正确地补全，你需要手动改成正确的参数类型。

## Lazy Perform

你可以先创建router，再稍后执行路由。这样可以把路由的提供者和执行者分开。

需要注意的是，router可能会执行失败（比如当前已经执行了路由，不能再重复执行），因此在执行路由前需要先检查状态。

```swift
class TestViewController: UIViewController {
    var router: DestinationViewRouter<EditorViewInput>?
    func viewDidLoad() {
        super.viewDidLoad()
        router = Router.to(RoutableView<EditorViewInput>())
    }
    
    func showEditor() {
        guard let router = self.router, router.canPerform else {
            return
        }
        router?.perform(from: self, routeType: .push)
    }
}
```

<details><summary>Objective-C示例</summary>

```objectivec
@implementation ZIKTestPushViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.router = [[ZIKViewRouter.classToView(ZIKRoutableProtocol(EditorViewInput)) alloc]
                           initWithConfiguring:^(ZIKViewRouteConfiguration *config) {
                               config.source = self;
                               config.routeType = ZIKViewRouteTypePush;
                           }
                           removing:nil];
}
- (void)showEditor {
    if (![self.router canPerform]) {
        NSLog(@"Can't perform route now:%@",self.router);
        return;
    }
    [self.router performRouteWithSuccessHandler:^{
        NSLog(@"did show editor");
    } errorHandler:^(SEL routeAction, NSError *error) {
        NSLog(@"failed to show editor with error: %@",error);
    }];
}
@end
```

</details>

## 自定义路由操作

### View Router

如果要进行自定义的界面跳转，需要：

1. 重写`supportedRouteTypes`，添加`ZIKViewRouteTypeCustom`
2. 如果需要判断configuration是否正确，则重写`-validateCustomRouteConfiguration:removeConfiguration:`
3. 重写`canPerformCustomRoute`判断当前是否可以执行路由，可以则返回true
4. 重写`performCustomRouteOnDestination:fromSource:configuration:`，执行自定义界面跳转操作，如果自定义操作是执行segue，则在执行时需要使用`_performSegueWithIdentifier:fromSource:sender:`
5. 用`beginPerformRoute`、`endPerformRouteWithSuccess`、`endPerformRouteWithError:`改变路由状态

### Service Router

Service router只是用于返回一个对象。如果你需要自定义service router的路由，可以重写`-performRouteOnDestination:configuration:`。

Service router的使用和view router也是类似的，只是去掉了界面跳转的封装，要比view router更加简单和通用。而大多数service并不需要view controller那样的一个路由过程，只是需要获取某个service模块。此时可以使用[Make Destination](MakeDestination.md)。

执行路由之后，会得到一个router实例，你可以持有这个router实例，在之后移除路由，参考[Remove Route](RemoveRoute.md)。