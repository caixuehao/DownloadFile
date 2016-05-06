//
//  ViewController.m
//  DownloadFile
//
//  Created by C on 16/3/31.
//  Copyright © 2016年 C. All rights reserved.
//
#import "DownloadFile.h"

#import "ViewController.h"

#import "AFNetworking.h"
#define FileURL1 @"http://cn-zjjh13-dx.acgvideo.com/183.131.156.4/vg11/f/f4/7238001-1.flv?expires=1462532700&ssig=4bYGkHWZW0vK7MbO_icXDw&oi=1944850178&player=1&or=1034170279&rate=0"

@interface ViewController ()

@end

@implementation ViewController{
    long long fileSize;
}

-(NSURLSession*)session{
    if (!_session) {
        NSURLSessionConfiguration* configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        self.session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    }
    return _session;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setSliderValue:0];
    
    // Do any additional setup after loading the view, typically from a nib.
}



- (IBAction)btn:(id)sender {
    

    
    
    
    
    
    
  /*
    NSString* savepath = [[self getSavePath] stringByAppendingPathComponent:@"111/1.flv"];
    //路径检查
    NSString* fileDirPath = [savepath substringToIndex:savepath.length - [savepath lastPathComponent].length-1];
    NSLog(@"%@",fileDirPath);
    BOOL bo = [[NSFileManager defaultManager] createDirectoryAtPath:fileDirPath withIntermediateDirectories:YES attributes:nil error:nil];
    if (bo==NO) {
        NSLog(@"创建目录失败");
    }
    NSMutableURLRequest* request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:FileURL1]];
     [request setHTTPMethod:@"GET"];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc]initWithRequest:request];
    [operation setOutputStream:[NSOutputStream outputStreamToFileAtPath:savepath append:NO]];
    [operation setDownloadProgressBlock:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
        NSLog(@"download：%f", (float)totalBytesRead / totalBytesExpectedToRead);
        
    }];
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
       
        NSLog(@"下载成功");
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"%@",[error localizedDescription]);
        
        NSLog(@"下载失败");
        
    }];
    
    [operation start];
    */

    
    
//    return;
    NSString* savepath = [[self getSavePath] stringByAppendingPathComponent:@"111/1.flv"];
    NSLog(@"%@",savepath);
    [DownloadFile start:FileURL1 savePath:savepath Downloading:^(long long PresentSize, long long WholeSize) {
//        NSLog(@"%lld",PresentSize);
        [self setSliderValue:(float)PresentSize/WholeSize];
    } Finished:^{
        NSLog(@"下载完成");
    } error:^(NSString *error) {
        NSLog(@"%@",error);
    }];
    
    return;
    
    //创建下载任务
    NSURL* url = [NSURL URLWithString:FileURL1];
    self.task = [self.session downloadTaskWithURL:url];
    //开始下载任务
    [self.task resume];
    NSLog(@"开始");
    
}


- (IBAction)btn2:(id)sender {
    //在调用pause这个方法时，存在着一定的风险，因为self对task进行了强引用，task又对block进行了引用，block又对self进行引用，这就形成了循环使用
    //对self进行弱引用 __weak typedef(self)   vc=self
    
//    [DownloadFile2 pause];
    
    return;
    
    __weak typeof (self) vc = self;
    [self.task cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
        vc.resumData = resumeData;
    }];

}


//继续

- (IBAction)btn3:(id)sender {
    self.task = [self.session downloadTaskWithResumeData:self.resumData];
    [self.task resume];
    
}








/**
 *  设置进度条
 *
 *  @param value 进度条的值
 */
-(void)setSliderValue:(float)value{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        //主线程中更新进度UI操作。。。。
        [_slider setValue:value animated:YES];
    }];
  
}












/**
 *  获取保存地址
 *
 *  @return 保存地址
 */
-(NSString*)getSavePath{
    //判断路径是否正确
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
    NSString *plistPath1 = [paths objectAtIndex:0];
    //得到完整的文件名
//    NSString *filename=[plistPath1 stringByAppendingPathComponent:@"狂三2.plist"];
    
    return plistPath1;
}




#pragma mark------NSURLSessionDownloadDelegate代理方法
-(void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location{
    NSLog(@"%@",location);
    //下载完成
    NSString* savepath = [[self getSavePath] stringByAppendingPathComponent:[location.path lastPathComponent]];
    NSLog(@"%@",savepath);
    
    NSFileManager* fm = [NSFileManager defaultManager];
    [fm moveItemAtPath:location.path toPath:savepath error:nil];
  
    
    _imageView.image = [[UIImage alloc] initWithContentsOfFile:savepath];
}

-(void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite{
    float f = (float)totalBytesWritten/totalBytesExpectedToWrite;
    [self setSliderValue:f];
    float i1 = totalBytesWritten;
    float i2 = totalBytesExpectedToWrite;
    float num = i1/i2;
    NSLog(@"%f / %f = %f ",i1,i2,num*100);
}


























- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
