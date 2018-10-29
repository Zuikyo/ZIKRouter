# Perform Route

You need get a router subclass for your destination module to perform route. You can use protocol to get router class.

ZIKRouter is written in Objective-C. If your project is in Swift, use `ZRouter`.

## Type Safe Perform

It's safe to perform route with routable protocol.

```swift
class TestViewController: UIViewController {
    func showEditorViewController() {
        Router.perform(
            to: RoutableView<NoteEditorInput>(),
            path: .push(from: self),
            configuring: { (config, _) in
                //Config the route
                config.successHandler = { destination in
                    //Transition succeed
                }
                config.errorHandler = { (action, error) in
                    //Transition failed
                }
                //Config the destination before performing route
                config.prepareDestination = { destination in
                    //destination is inferred as NoteEditorInput
                    //Config editor view
                    destination.delegate = self
                    destination.constructForCreatingNewNote()
                }
        })
    }
}
```

## Switchable Perform

When a route is for showing views from a limited list, you can use `Switchable`.

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
        Router.to(switchableView)?.perform(path: .push(from: self))
    }
}
```

## Perform in Objective-C

```objectivec
@implementation TestViewController

- (void)showEditorViewController {
	[ZIKRouterToView(NoteEditorInput)
	          performPath:ZIKViewRoutePath.presentModallyFrom(self)
	          configuring:^(ZIKViewRouteConfiguration *config) {
	              config.animated = YES;
	              config.prepareDestination = ^(id<NoteEditorInput> destination) {
	                  destination.delegate = self;
	                  [destination constructForCreatingNewNote];
	              };
	              config.succeeHandler = ^(id<NoteEditorInput> destination) {
	                  //Transition completed
	              };
	              config.errorHandler = ^(ZIKRouteAction routeAction, NSError *error) {
	                  //Transition failed
	              };
	          }];
}
```

Comparing to `performPath:configuring:` method, `performPath:strictConfiguring:` method can give much strict compiler checking:

```objectivec
@implementation TestViewController

- (void)showEditorViewController {
	[ZIKRouterToView(NoteEditorInput)
	          performPath:ZIKViewRoutePath.presentModallyFrom(self)
	          strictConfiguring:^(ZIKViewRouteStrictConfiguration<id<NoteEditorInput>> *config,
	          					   ZIKViewRouteConfiguration *module) {
	              config.animated = YES;
	              //Type of prepareDest block changes with the router's generic parameters.
	              config.prepareDestination = ^(id<NoteEditorInput> destination){
	                  destination.delegate = self;
	                  [destination constructForCreatingNewNote];
	              };
	              config.routeCompletion = ^(id<NoteEditorInput> destination) {
	                  //Transition completed
	              };
	              config.errorHandler = ^(ZIKRouteAction routeAction, NSError *error) {
	                  //Transition failed
	              };
	          }];
}
```

Type of `ZIKViewRouteStrictConfiguration` changes with it's generic parameter. So there will be compile checking when you configuring the configuration.

But there is bug in Xcode auto completions. Parameters in `ZIKViewRouteStrictConfiguration`'s methods are not correctly completed, you have to manually fix the type.

## Lazy Perform

You can create the router, then perform it later. This let you separate the router's provider and performer.

When performer performs the router, it may fail. The router may be performed already and can't be performed unless it's removed. So the performer needs to check the router's state.

```swift
class TestViewController: UIViewController {
    var routerType: ViewRouterType<EditorViewInput, ViewRouteConfig>?
    func viewDidLoad() {
        super.viewDidLoad()
        routerType = Router.to(RoutableView<EditorViewInput>())
    }
    
    func showEditor() {
        guard let routerType = self. routerType else {
            return
        }
        routerType.perform(path: .push(from: self))
    }
}
```

<details><summary>Objective-C Sample</summary>

```objectivec
@implementation ZIKTestPushViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.routerType = ZIKRouterToView(EditorViewInput);
}
- (void)showEditor {
    [self.routerType performPath:ZIKViewRoutePath.pushFrom(self)];
}
@end
```

</details>

## Custom Transition

### View Router

Steps to support custom transition:

1. Override `supportedRouteTypes`, add`ZIKViewRouteTypeCustom`
2. If the router needs to validate the configuration, override `-validateCustomRouteConfiguration:removeConfiguration:`
3. Override `canPerformCustomRoute` to check whether the router can perform route now because the default return value is false
4. Override `performCustomRouteOnDestination:fromSource:configuration:` to do custom transition. If the transition is performing a segue, use `_performSegueWithIdentifier:fromSource:sender:`
5. Manage router's state with `beginPerformRoute`、`endPerformRouteWithSuccess`、`endPerformRouteWithError:`

### Service Router

If you want to do custom route action, override `-performRouteOnDestination:configuration:`.

Most service routers are just for getting a service object. You can use [Make Destination](MakeDestination.md).

After performing, you will get a router instance. You can hold the router and remove route later. See [Remove Route](RemoveRoute.md).

## Perform on Destination

If you get a destination from other place, you can perform on the destination with its router.

For example, an UIViewController supports 3D touch, and implments `UIViewControllerPreviewingDelegate`:

```swift
class SourceViewController: UIViewController, UIViewControllerPreviewingDelegate {
	func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
	     //Return the destination UIViewController to let system preview it
        let destination = Router.makeDestination(to: RoutableView<DestinationViewInput>())
        return destination
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        guard let destination = viewControllerToCommit as? DestinationViewInput else {
            return
        }
        //Show the destination
        Router.to(RoutableView<DestinationViewInput>())?.perform(onDestination: destination, path: .presentModally(from: self))
}

```

<details><summary>Objective-C Sample</summary>

```objectivec
@implementation SourceViewController

- (nullable UIViewController *)previewingContext:(id <UIViewControllerPreviewing>)previewingContext viewControllerForLocation:(CGPoint)location {
    //Return the destination UIViewController to let system preview it
    UIViewController<DestinationViewInput> *destination = [ZIKRouterToView(DestinationViewInput) makeDestination];
    return destination;
}

- (void)previewingContext:(id <UIViewControllerPreviewing>)previewingContext commitViewController:(UIViewController *)viewControllerToCommit {
    //Show the destination
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

If you don't want to show the destination, but just want to prepare an existing destination, you can prepare the destination with router.

If the router injects dependencies inside it, this can properly setting the destination instance.

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

## URL router

If your app needs to support URL scheme, you can use identifier to perofrm route.

```swift
// openURL inside your app or from other app
func openURL(_ url: NSURL) {
    // your-app-scheme://listView/settingView?item=1
    UIApplication.shared.openURL(url)
}

class AppDelegate: UIResponder, UIApplicationDelegate {
    ...
    override func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
    
        //You can use other url router framework to handle the url
        let identifier: String = // route identifier from the url
        let routerType = Router.to(viewIdentifier: identifier)
        if routerType == nil {
            return false
        }
        let params: [String : Any] = // parameters from the url
        let rootViewController = // get rootViewController
        routerType?.perform(path: .show(from: rootViewController), configuring: { (config, _) in
            config.addUserInfo(params)
        })
        
    }
}
```

<details><summary>Objective-C Sample</summary>

```objectivec
// openURL inside your app or from other app
- (void)openURL:(NSURL *)url {
    // your-app-scheme://listView/settingView?item=1
    [[UIApplication sharedApplication] openURL: url];
}

@implementation AppDelegate

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
    
    //You can use other URL router framework to handle the url
    NSString *identifier = // route identifier from the url
    ZIKViewRouterType *routerType = ZIKViewRouter.toIdentifier(identifier);
    if (routerType == nil) {
        return NO;
    }
    UISplitViewController *splitViewController = (UISplitViewController *)self.window.rootViewController;
    UINavigationController *navigationController = [splitViewController.viewControllers lastObject];
    
    NSDictionary *params = // parameters from the url
    [routerType performPath:ZIKViewRoutePath.showFrom(navigationController)
                configuring:^(ZIKViewRouteConfiguration *config) {
                    [config addUserInfo:params];
                }];
    return YES;
}
@end
```

</details>

You can use other URL router framework to handle the url, the URL router needs to set and get the identifier for router.

## Custom Event

If you want to send custom event to module, you can enumerate all router classes and perform event:

```swift
func applicationDidEnterBackground(_ notification: Notification) {
        // Send custom event
        Router.enumerateAllViewRouters { (routerType) in
            if routerType.responds(to: #selector(applicationDidEnterBackground(_:))) {
                routerType.perform(#selector(applicationDidEnterBackground(_:)), with: notification)
            }
        }
        Router.enumerateAllServiceRouters { (routerType) in
            if routerType.responds(to: #selector(applicationDidEnterBackground(_:))) {
                routerType.perform(#selector(applicationDidEnterBackground(_:)), with: notification)
            }
        }
    }
```
<details><summary>Objective-C Sample</summary>

```objectivec
- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Send custom event
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

If the module want to handle event, just implements class method in router:

```swift
class EditorViewRouter: ZIKViewRouter<EditorViewController, ViewRouteConfig> {
    ...
    @objc class func applicationDidEnterBackground(_ notification: Notification) {
        // Handle custom event
    }
```
<details><summary>Objective-C Sample</summary>

```objectivec
@implementation EditorViewRouter
...
- (void)applicationDidEnterBackground:(UIApplication *)application {
	// Handle custom event
}

@end
```

</details>

---
#### Next section: [Remove Route](RemoveRoute.md)