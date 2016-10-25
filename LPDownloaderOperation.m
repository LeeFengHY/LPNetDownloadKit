//
//  LPDownloaderOperation.m
//  LPNetDownloadKit
//
//  Created by QFWangLP on 16/10/24.
//  Copyright © 2016年 lpdownloader. All rights reserved.
//

#import "LPDownloaderOperation.h"

typedef NS_OPTIONS(NSInteger , LPRequestState) {
    LPRequestStateReady     =  1 << 0,
    LPRequestStateExecuting =  1 << 1,
    LPRequestStateFinished  =  1 << 2,
};
static const NSTimeInterval kRequestTimeout = 30.f;

@interface LPDownloaderOperation()

@property (nonatomic, strong) NSMutableData *fileData;
@property (nonatomic, strong) NSMutableURLRequest *request;
@property (nonatomic, strong) NSURLConnection *connection;
@property (nonatomic, assign) CGFloat expectedLength;
@property (nonatomic, assign) CGFloat receivedLength;
@property (nonatomic, copy)   NSString *fileName;
@property (nonatomic, assign) LPRequestState state;
@property (nonatomic, assign) CFRunLoopRef operationRunLoop;
@property (nonatomic, weak)   id<LPDownloaderOperationDelegate> delegate;
@property (nonatomic, copy)   void (^completion)(id response, NSError *error);
@property (nonatomic, copy)   void (^progress)(CGFloat percent);
@property (nonatomic, copy)   void (^fileNameString)(NSString *name);

@end

@implementation LPDownloaderOperation
@synthesize state = _state;

- (instancetype)initWithRequestURL:(NSString *)url delegate:(id<LPDownloaderOperationDelegate>)delegate
{
    return  [self initWithRequestURL:url delegate:delegate progress:nil fileName:nil completion:nil];
}

- (instancetype)initWithRequestURL:(NSString *)url
                          progress:(void (^)(CGFloat percent))progress
                          fileName:(void (^)(NSString *name))fileName
                        completion:(void (^)(id response, NSError *error))completion
{
    return [self initWithRequestURL:url delegate:nil progress:progress fileName:fileName completion:completion];
}
- (instancetype)initWithRequestURL:(NSString *)url
                          delegate:(id<LPDownloaderOperationDelegate>)delegate
                          progress:(void (^)(CGFloat percent))progress
                          fileName:(void (^)(NSString *name))fileName
                        completion:(void (^)(id response, NSError *error))completion
{
    self = [super init];
    if (self) {
        self.delegate = delegate;
        self.progress = progress;
        self.completion = completion;
        self.fileNameString = fileName;
        NSString * newUrl = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                                                                  (CFStringRef)url,
                                                                                                  (CFStringRef)@"!$&'()*-,-./:;=?@_~%#[]",
                                                                                                  NULL,
                                                                                                  kCFStringEncodingUTF8));
        //NSString *newUrl = [url stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet characterSetWithCharactersInString:@"!$&'()*-,-./:;=?@_~%#[]"]];
        NSURL *httpURL = [NSURL URLWithString:newUrl];
        self.request = [NSMutableURLRequest requestWithURL:httpURL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:kRequestTimeout];
    }
    return self;
}
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
#pragma mark priviate method
- (void)finish
{
    [self.connection cancel];
    self.connection = nil;
    
    [self willChangeValueForKey:@"isExecuting"];
    [self willChangeValueForKey:@"isFinished"];
    self.state = LPRequestStateFinished;
    [self didChangeValueForKey:@"isExecuting"];
    [self didChangeValueForKey:@"isFinished"];
}
- (LPRequestState)state
{
    @synchronized (self) {
        return _state;
    }
}
- (void)setState:(LPRequestState)newstate
{
    @synchronized (self) {
        [self willChangeValueForKey:@"state"];
        _state = newstate;
        [self didChangeValueForKey:@"state"];
    }
}

- (void)downloadFinishWithResponse:(id)response error:(NSError *)error
{
    if (_operationRunLoop) {
        CFRunLoopStop(_operationRunLoop);
    }
    if (self.isCancelled) {
        return;
    }
    if (_completion) {
        _completion(response,error);
    }
    if (response && _delegate && [_delegate respondsToSelector:@selector(downloaderOpeation:didFinishWithData:)]) {
        [_delegate downloaderOpeation:self didFinishWithData:_fileData];
    }else if (!response && [_delegate respondsToSelector:@selector(downloadFinishWithResponse:error:)]){
        [_delegate downloaderOpeation:self didFailWithError:error];
    }
    [self finish];
}
#pragma mark - NSURLConnectionDelegate
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    _expectedLength = response.expectedContentLength;
    _receivedLength = 0;
    _fileName = response.suggestedFilename;
    if (_fileNameString) {
        _fileNameString(_fileName);
    }
    _fileData = [NSMutableData data];
    
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [_fileData appendData:data];
    _receivedLength += data.length;
    CGFloat percent = _receivedLength/_expectedLength;
    if (_progress) {
        _progress(percent);
    }
    if (_delegate && [_delegate respondsToSelector:@selector(downloaderOpeation:downloadProgress: fileName:)]) {
        [_delegate downloaderOpeation:self downloadProgress:percent fileName:_fileName];
    }
    
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    [self downloadFinishWithResponse:self.fileData error:nil];
   
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [self downloadFinishWithResponse:nil error:error];
}
@end
