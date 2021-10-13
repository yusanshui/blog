### lib/process
1. tech.geekcity.blackhole.lib.process.CommandBoxTest 
    * 这里的standardInputStream()被注解@Nullable修饰，表示可以为null,所以可以不需要初始化
    * 对于返回类型为Map的方法，在@FreeBuilder的注解下会自动生成clearmap和putmap等方法。
    * testEnv()方法还测试了commandBox类中EnvironmentVariableMap自己手动添加值能否生效。
2. tech.geekcity.blackhole.lib.process.SafeCommandBoxTest
    * 这里我们要mock CommandBox的原因是SafeCommandBox里调用了CommandBox里的call()方法，但call方法执行需要使用系统环境，会影响测试的可靠性，在我们验证过commandBox的情况下，我们就可以完全信任CommandBox类，从而可以mock CommandBox。
    * SafeCommandBox类在Builder()方法里默认的构造参数设置了expectedExitValue的值，测试的时候要分为default和nonDefault的两种情况
    * SafeComandBox调用run方法，run方法里应该调用mock的CommandBox类的call方法，所以我们可以通过verify(command).call()来验证run方法是否执行了CommandBox的call方法。
### lib/render
1. tech.geekcity.blackhole.render.TextRenderEngineTest
    * 尽量使用范围小的接口，比如使用Map<String,Object> map = ImmutableMap.of(...)
    * 格式问题：
        * 链式编程，每个方法的（.）进行换行，类属性可以不用不换行
        * 方法含有多个参数，每个参数占一行，给git修改时可以清楚的看到哪个地方被修改
        * 使用try-with-resources语法，形如try(...){...},对于实现Closeable接口的类，无论是否异常，可以自动关闭。
        * 使用String.format("%s",variable)
### lib/ssh
1. tech.geekcity.blackhole.lib.ssh.SimpleScpTest
    * RandomStringUtils.randomAlphanumeric(count)：生成随机字符串
    * 对于常量使用private static final 进行修饰
    * Mockito.argThat(ArgumentMatcher<Class T>) variable -> ......)
        * ArgumentMathcer<class T> 验证参数类型
        * 使用lambda表达式
    * Mockito.mockStatic
        * try (MockedStatic<ScpClientCreator> mocked = Mockito.mockStatic(ScpClientCreator.class)){...}
        * 使用try-with-resources形式可以保证mock的静态方法是临时的
        * 有的类必须具有静态的instance方法或builder内部类，才能在其他函数调用该类的静态实例化方法mock该类的对象
        * 写类的时候要注意需不需要被人mock来添加静态实例化的方式
    * ScpTester是个抽象类，使用抽象类进行封装，测试方法使用抽象类作为入参，可以将需要检查的公共部分抽取出来，避免代码的重复，将不同的部分利用在抽象方法里重载，使代码结构更清晰。
        * 模板方法定义了算法的步骤，并把这些步骤的具体实现延迟到子类中。，模板方法可以使得子类不在改算法结构的情况下，重新定义算法中的某些步骤
        * 模板方法的抽象类可以定义具体方法、抽象方法和钩子。
            + 具体方法被定义在抽象类中，可以将它声明为final
            + 抽象方法为子类必须重写
            + 钩子是一种方法，在抽象类中为空或者默认的实现，它在抽象类中不做事或者做默认的事，子类可以选择要不要去覆盖它
    * 在setUp 中赋值的属性，尽量使用 transient 修饰，在setUp 中处理的变量一定要想一想是否需要“释放资源”。如果需要，别忘了tearDown 方法
    * 推荐在 setUp 方法中预先对“公共的”Mock 对象进行处理，并使用 参数注释@Mock 等方法注入mock 对象
    * 尽早 verify，尽量不穿插无用代码
    * 使用 Mockito.argThat 对invoke 的参数进行更加详细的检测
    * setScpTransferEventListener 部分的代码对设置的listener 也进行了检查，用来确保 SimpleScp 内对此进行了正确的处理
2. tech.geekcity.blackhole.lib.ssh.wrap.SshClientWrapTest
    * 使用spy监控一个真实对象
        + 它依赖了一个真实对象，默认行为是调用真实对象。我们希望更多的行为通过真实对象执行
        + 但也有不能执行的行为（需要环境）。所幸它也是一个mock 对象，可以通过doAnswer...when... 等方式改变某些行为
    * 使用try-with-resources的方式，可以在try代码块之后验证close方法是否执行
    * AuthVerifier 类似于tech.geekcity.blackhole.lib.ssh.SimpleScpTest的ScpTester
    * strictCheck 的验证，是因为我们相信我们mock的依赖库的行为是绝对正确的，所有我们只要验证SshClientWrap的代码正确使用了依赖库就可以。在SshClientWrap执行方法的过程中，会调用set方法，所以我们需要查看调用时设置是否正确，我们通过SshClientWrap的strictCheck()的返回值和set方法的入参即realSshclient的setServerKeyVerifier的入参中strict值是否一致来验证
    * knownHostsFile 的验证方式与StringCheck相似，是通过SshClientWrap的hostFile()的返回值和realSshclient的setServerKeyVerifier的入参中knowHostsFile()值是否一致来验证,但knoHostsFile是在入参的父类中的getpath()返回值来实现的。
    * SshClientWrap 是已经被测试的，完全可以直接使用或直接mock（要相信SshClientWrap 的正确性，否则就是你没测好SshClientWrap，要加强SshClientWrap 的测试）。千万不要出现，重复测试 SshClientWrap 的情况。
3. tech.geekcity.blackhole.lib.ssh.SshCommanderTest
    * Mockito.lenient()，可以跳过stub严格检验，因为有的mock方法不一定被调用，框架会对没有用的stub进行报错
    * thenAnswer(Answer<class T>)可以进行stub，return的类型为class T
    * RunTester类似于tech.geekcity.blackhole.lib.ssh.SimpleScpTest的ScpTester
    * 要注意到 mock 的 clientSession 的能力
        + 借助 MockCommand 在test case 中可以更方便地定制 clientSession 的能力（超时）
        + SshCommander 的超时功能通过利用MockCommand对象，MockCommand里可以设置命令执行所需要的时间，将MockCommand对象转成字符串传入，利用answer从中解析出命令需要执行的时间，通过与timeOut的对比，可以判断是否返回超时。
        + clientChannel 的超时功能是通过传入的参数超时限制和构造clientChannel的MockCommand对象的timeConsumed()进行对比，得出需要返回的结果。
4. tech.geekcity.blackhole.lib.ssh.wrap.RsaKeyPairWrapTest
    * 注意tech/geekcity/blackhole/lib/ssh/wrap/OpenSshRsaReader利用二进制编码的方式从输入流中读取Rsa密钥
    * 对于公钥和私钥，人可以读是OpenSsh的格式，而Rsa生成的密钥是二进制流
5. tech.geekcity.blackhole.lib.ssh.SshConnectorTest
    * mock的类对于每个方法都有一个默认的实现，所以不用对mock类的所有调用方法进行mock
    * 对sshConnector.configure()调用多次，是为了验证configured，效果与调用一次一样。
    * RegisterRsaKeyPair()要用带有password但rsaKeyPairWrap为null的SshConnector进行验证
    * 这里采用spy的原因是mock的类默认返回值是null，对于Builder使用的是链式编程，中间返回过程不能为null。
### lib/docker
1. tech.geekcity.blackhole.lib.docker.DockerProxyOverwriteMethodTest
    * 这是一个典型的使用Mockito 解耦合的例子
    * 对于代码执行过程中产生的目录采用FileUtils.forceDelete(dockerBuildDirectory)进行删除。
    * 注意下参数比较器的用法和verify的Mockito.times的设置
    * 使用dockerProxy = Mockito.spy(DockerProxy.class)的原因是DockerProxy的类中有些方法我们需要mock，比如重载的方法imagePull(BUSYBOX_IMAGE_REPOSITORY, BUSYBOX_IMAGE_TAG)是调用了imagePull(BUSYBOX_IMAGE_IDENTIFY)，我们只需要mock后面这一个方法，来看它是否被调用过即可，而imagePull(BUSYBOX_IMAGE_IDENTIFY)我们在DockerProxyTest中进行验证
2. tech.geekcity.blackhole.lib.docker.DockerProxyTest
    * DockerProxyTest主要是用来对docker常用命令的封装
    * DockerProxyTest是运行在本机上的测试，不需要mock
    * windows上的docker需要在settings/General中打开Expose daemon on tcp://localhost:2375 without TLS
    * 在原来的DockerProxy中dockerClientConfig中使用的默认的DefalutDockerConfig,现在重新构造代码，使用DefaultDockerClientConfig.Builder来代替，这样就可以使用builder的withDockerHost(dockerHost)来创建DockerConfig,默认的new DefaultDockerConfig是在linux上使用的dockerHost，利用builder我们就可以在DockerProxy类中添加一个dockerHost()属性，从而在构造dockerProxy对象的时候就可以传入不同环境下的dockerHost。
    * dockerProxy是一个实例资源，在结束后需要释放，添加了一个tearDown()方法
    * image pull/exists/delete 是一组相关联的测试
        + 通过if判断镜像是否存在，如果存在，则删除，这是为了保证环境的干净，不受以前程序运行结果的干扰，防止影响对pull方法的测试。
        + 三个方法的逻辑关系：拉取镜像->镜像是否存在->删除镜像->镜像是否存在