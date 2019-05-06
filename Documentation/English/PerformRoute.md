# Perform Route

You need get a router subclass for your destination module to perform route. You can use protocol to get router class.

ZIKRouter is written in Objective-C. If your project is in Swift, use `ZRouter`.

## Type Safe Perform

It's safe to perform route with routable protocol.

```swift
class TestViewController: UIViewController {
    func showEditorViewController() {
        Router.perform(
            to: RoutableView<EditorViewInput>(),
            path: .push(from: self),
            configuring: { (config, _) in
                // Config the route
                config.successHandler = { destination in
                    // Transition succeed
                }
                config.errorHandler = { (action, error) in
                    // Transition failed
                }
                // Config the destination before performing route
                config.prepareDestination = { destination in
                    // destination is inferred as EditorViewInput
                    // Config editor view
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

```objectivec
@implementation TestViewController

- (void)showEditorViewController {
	[ZIKRouterToView(EditorViewInput)
	          performPath:ZIKViewRoutePath.presentModallyFrom(self)
	          configuring:^(ZIKViewRouteConfiguration *config) {
	              config.animated = YES;
	              config.prepareDestination = ^(id<EditorViewInput> destination) {
	                  destination.delegate = self;
	                  [destination constructForCreatingNewNote];
	              };
	              config.succeeHandler = ^(id<EditorViewInput> destination) {
	                  // Transition completed
	              };
	              config.errorHandler = ^(ZIKRouteAction routeAction, NSError *error) {
	                  // Transition failed
	              };
	          }];
}
```

Comparing to `performPath:configuring:` method, `performPath:strictConfiguring:` method can give much strict compiler checking:

```objectivec
@implementation TestViewController

- (void)showEditorViewController {
	[ZIKRouterToView(EditorViewInput)
	          performPath:ZIKViewRoutePath.presentModallyFrom(self)
	          strictConfiguring:^(ZIKViewRouteStrictConfiguration<id<EditorViewInput>> *config,
	          					   ZIKViewRouteConfiguration *module) {
	              config.animated = YES;
	              // Type of prepareDestination block changes with the router's generic parameters.
	              config.prepareDestination = ^(id<EditorViewInput> destination){
	                  destination.delegate = self;
	                  [destination constructForCreatingNewNote];
	              };
	              config.successHandler = ^(id<EditorViewInput> destination) {
	                  // Transition completed
	              };
	          }];
}
```

Type of `ZIKViewRouteStrictConfiguration` changes with it's generic parameter. So there will be compile checking when you configuring the configuration.

But there is bug in Xcode auto completions. Parameters in `ZIKViewRouteStrictConfiguration`'s methods are not correctly completed, you have to manually fix the type.

## Make Destination

If you only want to get the destination, use `makeDestination`, and prepare the destination in block.

Swift Sample:

```swift
/// time service's interface
protocol TimeServiceInput {
    func currentTimeString() -> String
}
```
```swift
class TestViewController: UIViewController {
    @IBOutlet weak var timeLabel: UILabel!
    
    func callTimeService() {
        // Get service for TimeServiceInput
        let timeService = Router.makeDestination(
            to: RoutableService<TimeServiceInput>(),
            preparation: { destination in
            // Prepare the service
        })
        // Call service
        timeLabel.text = timeService.currentTimeString()
    }
}
```

<details><summary>Objective-C Sample</summary>

```objectivec
/// time service's interface
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
   // Get service for TimeServiceInput
   id<TimeServiceInput> timeService = [ZIKRouterToService(TimeServiceInput) makeDestination];
   // Call service
   self.timeLabel.text = [timeService currentTimeString];    
}

```

</details>

## Custom Transition

### View Router

Steps to support custom transition:

1. Override `supportedRouteTypes`, add`ZIKViewRouteTypeCustom`
2. If the router needs to validate the configuration, override `-validateCustomRouteConfiguration:removeConfiguration:`
3. Override `canPerformCustomRoute` to check whether the router can perform route now because the default return value is false
4. Override `performCustomRouteOnDestination:fromSource:configuration:` to do custom transition. If the transition is performing a segue, use `_performSegueWithIdentifier:fromSource:sender:`
5. Manage router's state with `beginPerformRoute`,  `endPerformRouteWithSuccess` , `endPerformRouteWithError:`

### Service Router

If you want to do custom route action:

1. Override `-performRouteOnDestination:configuration:`
2. Before performing custom action, call `prepareDestinationForPerforming` to prepare the destination
3. After performing custom action, call `endPerformRouteWithSuccess` or `endPerformRouteWithError` to change router's state

Most service routers are just for getting a service object. You can use Make Destination.

After performing, you will get a router instance. You can hold the router and remove route later. See [Remove Route](RemoveRoute.md).

## Perform on Destination

If you get a destination from other place, you can perform on the destination with its router.

For example, an UIViewController supports 3D touch, and implments `UIViewControllerPreviewingDelegate`:

```swift
class SourceViewController: UIViewController, UIViewControllerPreviewingDelegate {
	func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
	     // Return the destination UIViewController to let system preview it
        let destination = Router.makeDestination(to: RoutableView<DestinationViewInput>())
        return destination
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        guard let destination = viewControllerToCommit as? DestinationViewInput else {
            return
        }
        // Show the destination
        Router.to(RoutableView<DestinationViewInput>())?.perform(onDestination: destination, path: .presentModally(from: self))
}

```

<details><summary>Objective-C Sample</summary>

```objectivec
@implementation SourceViewController

- (nullable UIViewController *)previewingContext:(id <UIViewControllerPreviewing>)previewingContext viewControllerForLocation:(CGPoint)location {
    // Return the destination UIViewController to let system preview it
    UIViewController<DestinationViewInput> *destination = [ZIKRouterToView(DestinationViewInput) makeDestination];
    return destination;
}

- (void)previewingContext:(id <UIViewControllerPreviewing>)previewingContext commitViewController:(UIViewController *)viewControllerToCommit {
    // Show the destination
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

If you don't want to show the destination, but just want to prepare an existing destination, you can prepare the destination with its router.

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

## URL Router

If your app needs to support URL scheme, you can use URL Router.

```swift
ZIKAnyViewRouter.performURL("app://editor/test_note", path: .push(from: self))
```

<details><summary>Objective-C Sample</summary>

```objectivec
[ZIKAnyViewRouter performURL:@"app://editor/test_note" path:ZIKViewRoutePath.pushFrom(self)];
```

</details>

And handle URL Scheme:

```swift
// openURL inside your app or from other app
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
// openURL inside your app or from other app
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

## Custom Event

If you want to send custom event to module, you can enumerate all router classes and perform event:

```swift
func applicationDidEnterBackground(_ application: UIApplication) {
        // Send custom event
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
    @objc class func applicationDidEnterBackground(_ application: UIApplication) {
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