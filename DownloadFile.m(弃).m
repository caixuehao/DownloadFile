//
//  DownloadFile.m
//  DownloadFile
//
//  Created by C on 16/4/2.
//  Copyright © 2016年 C. All rights reserved.
//

#import "DownloadFile.h"


#define PauseDownloadFileData @"cai_PauseDownloadFileData.plist"//保存暂停数据的文件

typedef void (^Downloading)(long long PresentSize,long long WholeSize);
typedef void (^Finished)(void);



NSMutableDictionary* downloadFileTask_dic;//保存下载任务字典;


@implementation DownloadFile{
    //下载属性
//    NSURLSession* _session;
    //下载任务
//    NSURLSessionDownloadTask* _task;
    //下载中的回调
    Downloading _downloadingBlock;
    //下载成功的回调
    Finished _finishedBlock;
    //文件保存地址
    NSString* _savePath;
    //文件下载地址
    NSString* _URL;
    //该任务的名字
//    NSString* _name;
    //暂停时的数据
//    NSData* _resumeData;
    //记录网络状态
    int _netStatus;//0-2
}






/**
 *  开始下载
 *
 *  @param URL  下载地址
 *  @param path 保存地址
 *  @param downloadingBlock 下载中的回调
 *  @param finishedBlock    下载成功的回调
 *  @param name             下载任务的名字用来暂停时使用
 */
+(void)start:(NSString*)URL savePath:(NSString*)path Downloading:(void(^)(long long PresentSize,long long WholeSize))downloadingBlock Finished:(void(^)(void))finishedBlock name:(NSString *)name{
    
  
    DownloadFile* downloadFile = [[DownloadFile alloc] init];
    [downloadFile startDownloadFile:URL savePath:path Downloading:downloadingBlock Finished:finishedBlock name:name];
//    //保存句柄
    if(!downloadFileTask_dic)downloadFileTask_dic = [[NSMutableDictionary alloc] init];
    [downloadFileTask_dic setObject:downloadFile forKey:name];
}





/**
 *  暂停全部下载任务并保存断点下载的数据
 */
+(void)pause{
    
    for (NSString* key in downloadFileTask_dic) {
        DownloadFile* downloadFile = [downloadFileTask_dic objectForKey:key];
        [downloadFile pauseDownloadFile];
    }
    
}


/**
 *  暂停一个任务
 *
 *  @param name 该任务的名字
 */
+(void)pause:(NSString*)name{

    DownloadFile* downloadFile = [downloadFileTask_dic objectForKey:name];
    
    if (downloadFile) {
          [downloadFile pauseDownloadFile];
    }
}



/**
 *  继续下载全部下载任务并保存断点下载的数据
 */
+(void)resume{
    for (NSString* key in downloadFileTask_dic) {
         DownloadFile* downloadFile = [downloadFileTask_dic objectForKey:key];
        [downloadFile resumeDownloadFile];
    }
}


/**
 *  继续下载一个任务
 *
 *  @param name 该任务的名字
 */
+(void)resume:(NSString*)name{
    
    DownloadFile* downloadFile = [downloadFileTask_dic objectForKey:name];
    
    if (downloadFile) {
        [downloadFile resumeDownloadFile];
    }
}



//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++













/**
 *  开始下载
 *
 *  @param URL  下载地址
 *  @param path 保存地址
 *  @param downloadingBlock 下载中的回调
 *  @param finishedBlock    下载成功的回调
 */
-(void)startDownloadFile:(NSString*)URL savePath:(NSString*)path Downloading:(void(^)(long long PresentSize,long long WholeSize))downloadingBlock Finished:(void(^)(void))finishedBlock name:(NSString*)name{
    
    
    _downloadingBlock = downloadingBlock;
    _finishedBlock = finishedBlock;
    _savePath = path;
    _name = name;
    _URL = URL;
    _netStatus = -1;

//    //监听是否触发home键挂起程序.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive) name:NSExtensionHostDidBecomeActiveNotification object:nil];
//     //监听是否重新进入程序程序.
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive)
//                                                 name:NSExtensionHostDidBecomeActiveNotification object:nil];
    
    //开启网络状况的监听
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
    
    _hostReach =[Reachability reachabilityForInternetConnection];
//    [Reachability reachabilityWithHostName:@"wwww.baidu.com"];//可以以多种形式初始化
    [_hostReach startNotifier]; //开始监听,会启动一个run loop
    [self updateInterfaceWithReachability: _hostReach];
    
    
    

    
    //路径检查
    NSString* fileDirPath = [path substringToIndex:path.length - [path lastPathComponent].length-1];
    NSLog(@"%@",fileDirPath);
    BOOL bo = [[NSFileManager defaultManager] createDirectoryAtPath:fileDirPath withIntermediateDirectories:YES attributes:nil error:nil];
    if (bo==NO) {
        NSLog(@"创建目录失败");
    }
    
    //创建下载任务属性
    NSURLSessionConfiguration* configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    _session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:[NSOperationQueue mainQueue]];
   
    //判断是否断点下载
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *plistPath1 = [paths objectAtIndex:0];
    NSString *filename =[plistPath1 stringByAppendingPathComponent:PauseDownloadFileData];
    NSMutableDictionary* dic = [[NSMutableDictionary alloc] initWithContentsOfFile:filename];
    
    NSData* resumeData = [dic objectForKey:_name];
    if (resumeData.length)
    //创建下载任务
    {
        //断点续传
        _task = [_session downloadTaskWithResumeData:resumeData];
        //把文件清空
        [dic removeObjectForKey:_name];
        [dic writeToFile:filename atomically:YES];
    }
    else
    {
        //新的下载任务
      _task = [_session downloadTaskWithURL:[NSURL URLWithString:_URL]];
    
    }
    

    //开始下载任务
    [_task resume];
}












/**
 *  暂停下载
 */
-(void)pauseDownloadFile{
//    __weak typeof (self)df = self;
    
    if(_task){
        NSLog(@"%@暂停下载。",_name);
         __weak typeof (self) th = self;
        [_task cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
            NSLog(@"resumeData:%lu",resumeData.length);
            th.resumeData = resumeData;
            
            if (resumeData) {
                NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                NSString *plistPath1 = [paths objectAtIndex:0];
                NSString *filename =[plistPath1 stringByAppendingPathComponent:PauseDownloadFileData];
                
                
                NSMutableDictionary* dic = [[NSMutableDictionary alloc] initWithContentsOfFile:filename];
                if (!dic)dic = [[NSMutableDictionary alloc] init];
                [dic setValue:resumeData forKey:th.name];
                
                
                [dic writeToFile:filename atomically:YES];
            }
        }];
        th.task = nil;
    }

}




/**
 *  继续下载
 */
-(void)resumeDownloadFile{

    if (_resumeData.length == 0) {
        //新的下载任务
        _task = [_session downloadTaskWithURL:[NSURL URLWithString:_URL]];
        [_task resume];
        return;
    }
    
    
    if (_resumeData&&_session) {
        NSLog(@"%@继续下载。",_name);
        _task = [_session downloadTaskWithResumeData:_resumeData];
        [_task resume];
//        _resumeData = nil;
    }
}





#pragma mark------监听

//监听是否触发home键挂起程序.
-(void)applicationWillResignActive{
    [self pauseDownloadFile];
}




//监听是否重新进入程序程
-(void)applicationDidBecomeActive{
    [self resumeDownloadFile];
}






#pragma mark------NSURLSessionDownloadDelegate代理方法

//下载成功的代理方法
-(void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location{
    NSFileManager* fm = [NSFileManager defaultManager];
    [fm moveItemAtPath:location.path toPath:_savePath error:nil];
//    NSLog(@"%@",location.path);
    //删除引用
    [downloadFileTask_dic removeObjectForKey:_name];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    _finishedBlock();
}

//下载中的代理方法
-(void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite{
    _downloadingBlock(totalBytesWritten,totalBytesExpectedToWrite);
}

// 连接改变
- (void)reachabilityChanged: (NSNotification*)note
{
    Reachability* curReach = [note object];
    NSParameterAssert([curReach isKindOfClass:[Reachability class]]);
    [self updateInterfaceWithReachability:curReach];
}

- (void)updateInterfaceWithReachability:(Reachability *)reachability
{
    NetworkStatus netStatus = [reachability currentReachabilityStatus];
    if (_netStatus == -1) {
        _netStatus = netStatus;
        return;
    }
     else if (netStatus ==  _netStatus) {
        return;
     } else if (netStatus && _netStatus){
         _netStatus = netStatus;
         return;
     }
    
    _netStatus = netStatus;
    switch (netStatus) {
        case NotReachable:
            NSLog(@"====当前网络状态不可用=======");
            [self pauseDownloadFile];//暂停下载
            break;
        case ReachableViaWiFi:
            NSLog(@"====当前网络状态为Wifi=======");
            [self resumeDownloadFile];//继续下载
            break;
        case ReachableViaWWAN:
            NSLog(@"====当前网络状态为手机网络=======");
            [self resumeDownloadFile];//继续下载
            break;
    }
}
#pragma mark-----
-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
