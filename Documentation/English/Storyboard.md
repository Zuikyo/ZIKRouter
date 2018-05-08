# Storyboard

ZIKViewRouter supports storyboard.

When using `instantiateInitialViewController` and performing segue, if the UIViewController conforms to `ZIKRoutableView`, ZIKRouter will search router for this UIViewController, and call router's `-destinationFromExternalPrepared:`.

If `-destinationFromExternalPrepared:` returns NO, means the source view controller have to config the destination. Source view controller's `-prepareDestinationFromExternal:configuration:` will be called. If source was not found or source didn't implements this methods, there will be an error.

After that, router will call it's `-prepareDestination:configuration:` and `-didFinishPrepareDestination:configuration:` to prepare the destination.

When adding subview, ZIKRouter will also check whether the UIView conforms to `ZIKRoutableView`, and prepare it with the same procedure.