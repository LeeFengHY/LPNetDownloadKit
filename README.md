# LPNetDownloadKit
## 知识点NSOperation和NSRunLoop结合使用,主要是笔者做了个小demo用于工作中并发操作

> LPDownloaderOperation 继承NSOperation,根据需求重新实现

```objc

#pragma mark - NSOperation Methods
- (void)cancel
{
    if (![self isExecuting]) {
        return;
    }
    [super cancel];
}
/**
 支持并发

 @return BOOL
 */
- (BOOL)isConcurrent
{
    return YES;
}

- (BOOL)isFinished
{
    return self.state = LPRequestStateFinished;
}

- (BOOL)isExecuting
{
    return self.state = LPRequestStateExecuting;
}

/**
 重新构造NSOperation start 方法
 */
- (void)start
{
    if (self.isCancelled) {
        [self finish];
        return;
    }
    [self willChangeValueForKey:@"isExecuting"];
    self.state = LPRequestStateExecuting;
    [self didChangeValueForKey:@"isExecuting"];
    self.connection = [[NSURLConnection alloc] initWithRequest:self.request delegate:self startImmediately:NO];
    
    NSOperationQueue *currentQueue = [NSOperationQueue currentQueue];
    BOOL backgroundQueue = (currentQueue != nil && currentQueue !=[NSOperationQueue mainQueue]);
    NSRunLoop *targetRunLoop = backgroundQueue?[NSRunLoop currentRunLoop]:[NSRunLoop mainRunLoop];
    [self.connection scheduleInRunLoop:targetRunLoop forMode:NSRunLoopCommonModes];
    [self.connection start];
    if (backgroundQueue) {
        self.operationRunLoop = CFRunLoopGetCurrent();
        CFRunLoopRun();
    }
}

```

## NSURLConnection 用于异步请求数据,推荐使用NSURLSession替代


## NSRunLoop 将当前的connection添加一个runLoop

## 实例代码

```objc

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    _operationQueue = [[NSOperationQueue alloc] init];
    _operationQueue.maxConcurrentOperationCount = 3;
   
    
}


- (IBAction)downloaderFile:(UIButton *)sender {
    [sender setTitle:@"下载中...." forState:UIControlStateNormal];
    _progressSlider.value = 0.0;
    LPDownloaderOperation *operation = [[LPDownloaderOperation alloc] initWithRequestURL:URL progress:^(CGFloat percent) {
        dispatch_async(dispatch_get_main_queue(), ^{
            _progressSlider.value = percent;
        });
    } fileName:^(NSString *name) {
        dispatch_async(dispatch_get_main_queue(), ^{
            _fileNameLabel.text = name;
        });
    } completion:^(id response, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            UIImage *image = [UIImage imageWithData:response];
            _fileImageView.image = image;
            [sender setTitle:@"下载完成" forState:UIControlStateNormal];
        });
    }];
    [_operationQueue addOperation:operation];
    [_operationQueue addOperationWithBlock:^{
        NSLog(@"next operation");
    }];
}

```
