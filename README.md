# LPNetDownloadKit
## 知识点NSOperation和NSRunLoop结合使用,主要是笔者做了个小demo用于工作中并发操作
* LPDownloaderOperation 继承NSOperation,根据需求重新实现
> - (BOOL)isConcurrent
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
## NSURLConnection 用于异步请求数据,推荐使用NSURLSession替代
* 请求成功和失败的回调,用于进度下载显示

## NSRunLoop 将当前的connection添加一个runLoop

