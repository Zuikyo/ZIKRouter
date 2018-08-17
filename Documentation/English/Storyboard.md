# Storyboard and Auto Create

ZIKViewRouter supports storyboard.

When using `instantiateInitialViewController` and performing segue, if the UIViewController conforms to `ZIKRoutableView`, ZIKRouter will search and create router for this UIViewController, and call router's `-destinationFromExternalPrepared:`.

If `-destinationFromExternalPrepared:` returns NO, means the source view controller has to config the destination. Segue's sourceViewController's `-prepareDestinationFromExternal:configuration:` will be called. If source doesn't implement this method, there will be an error.

After that, router will call its `-prepareDestination:configuration:` and `-didFinishPrepareDestination:configuration:` to prepare the destination.

When you show destination without router, such as use `[source presentViewController:destination animated:NO completion:nil]`, the routers can get AOP callback, but can't search source view controller to prepare the destination. So the router won't be auto created. If you use a router as a dependency injector for preparing the UIViewController, you should always  display the UIViewController instance with router.

## UIView

When`-addSubview:` is called, and the UIView conforms to `ZIKRoutableView`, ZIKRouter will search and create router for the UIView, and call router's `-destinationFromExternalPrepared:`.

If `-destinationFromExternalPrepared:` returns NO, means the source view controller has to config the destination. We need to search soruce view controller of the UIView  with`nextResponder`. We get this UIView's view controller and parent view controller, choose this closest custom view controller. It's a custom UIViewController created by your own, and not container type like `UINavigationController`,`UITabBarController`,`UISplitViewController`.

But when the UIView is not in window hierarchy, we can't get its view controller with `nextResponder`. Then the preparation will be delayed to `-willMoveToSuperview:`,`-didMoveToSuperview`,`willMoveToWindow:`,`didMoveToWindow`.

If the UIView didn't find the source view controller until it's removed from superview, that means it's never properly prepared, then there will be assert failure. Such as:

* UIView was added to a superview, but superview was never be added to any superview
* UIView is added to a UIWindow

It's recommanded to always getting your view with its router.

---
#### Next section: [AOP](AOP.md)