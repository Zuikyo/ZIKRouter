# Storyboard

ZIKViewRouter支持storyboard。

当调用`instantiateInitialViewController`和执行segue时，如果view controller遵守`ZIKRoutableView`，将会查找此view controller类及其父类所注册的router，接着调用router的`+destinationPrepared:`。

如果`+destinationPrepared:`返回NO，说明需要让源界面对目的界面做出一些配置，此时会调用源界面的`-prepareDestinationFromExternal:configuration:`方法，如果没有查找到源界面，或者源界面没有实现此方法，将会记录错误。

最后会调用router的`-prepareDestination:configuration:`和`didFinishPrepareDestination:configuration:`，让router配置view controller。

同理，当添加subview的时候，也会检查UIView是否遵守`ZIKRoutableView`，并按照同样的流程查找router进行配置。