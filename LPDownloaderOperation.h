//
//  LPDownloaderOperation.h
//  LPNetDownloadKit
//
//  Created by QFWangLP on 16/10/24.
//  Copyright © 2016年 lpdownloader. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class LPDownloaderOperation;

@protocol LPDownloaderOperationDelegate <NSObject,NSURLConnectionDelegate>

@optional

- (void)downloaderOpeation:(LPDownloaderOperation *)operation downloadProgress:(CGFloat)progress fileName:(NSString *)fileName;
- (void)downloaderOpeation:(LPDownloaderOperation *)operation didFinishWithData:(NSData *)data;
- (void)downloaderOpeation:(LPDownloaderOperation *)operation didFailWithError:(NSError *)error;

@end

@interface LPDownloaderOperation : NSOperation

- (instancetype)initWithRequestURL:(NSURL *)url delegate:(nullable id<LPDownloaderOperationDelegate>)delegate;

- (instancetype)initWithRequestURL:(NSString *)url
                          progress:(void (^)(CGFloat percent))progress
                          fileName:(void (^)(NSString *name))fileName
                        completion:(void (^)(id response, NSError *error))completion;
@end
