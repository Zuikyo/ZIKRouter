# Storyboard

ZIKViewRouter 支持 storyboard。

当调用`instantiateInitialViewController`和执行 segue 时，如果 view controller 遵守`ZIKRoutableView`，将会查找此 view controller 类及其父类所注册的 router，接着调用 router 的`-destinationFromExternalPrepared:`。

如果`-destinationFromExternalPrepared:`返回 NO，说明需要让源界面对目的界面做出一些配置，此时会调用源界面的`-prepareDestinationFromExternal:configuration:`方法，如果没有查找到源界面，或者源界面没有实现此方法，将会记录错误。

最后会调用 router 的`-prepareDestination:configuration:`和`-didFinishPrepareDestination:configuration:`，让 router 配置 view controller。

同理，当添加 subview 的时候，也会检查 UIView 是否遵守`ZIKRoutableView`，并按照同样的流程查找 router 进行配置。

---
#### 下一节：[AOP](AOP.md)