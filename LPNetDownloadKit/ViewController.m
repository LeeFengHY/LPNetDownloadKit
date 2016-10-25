//
//  ViewController.m
//  LPNetDownloadKit
//
//  Created by QFWangLP on 16/10/24.
//  Copyright © 2016年 lpdownloader. All rights reserved.
//

#import "ViewController.h"
#import "LPDownloaderOperation.h"

#define URL @"http://s200.qfangimg.com/beijing/api/2016/9/18/7e46c48c-4d52-43cd-8448-3cc5d810e3f5.pdf"
@interface ViewController ()

@property (weak, nonatomic) IBOutlet UISlider *progressSlider;
@property (weak, nonatomic) IBOutlet UILabel *fileNameLabel;
@property (weak, nonatomic) IBOutlet UIImageView *fileImageView;
@property (nonatomic, strong) NSOperationQueue *operationQueue;

@end

@implementation ViewController

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

@end
