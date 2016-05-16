//
//  DownloadFile2.m
//  DownloadFile
//
//  Created by cxh on 16/5/6.
//  Copyright © 2016年 C. All rights reserved.
//



#import "DownloadFile.h"

typedef void (^Downloading)(long long PresentSize,long long WholeSize);
typedef void (^Finished)(void);
typedef void (^ErrorMsg)(NSString* str);

NSMutableDictionary* downloadFileTask_dic;//保存下载任务字典;

@implementation DownloadFile
{
    //下载中的回调
    Downloading _downloadingBlock;
    //下载成功的回调
    Finished _finishedBlock;
    //一些错误通知
    ErrorMsg _errorBlock;
    //文件保存地址
    NSString* _savePath;
    //文件下载地址
    NSString* _URL;
    
    
    //文件的总长度
    long long _totalLength;
    //已下载的长度
    long long _currentLength;
    
    //防止重复尝试下载
    NSInteger _i;
}
/**
 *  开始下载
 *
 *  @param URL  下载地址
 *  @param path 保存地址
 *  @param downloadingBlock 下载中的回调
 *  @param finishedBlock    下载成功的回调
 *  @param errorBlock       一些错误通知
 */

+(void)start:(NSString*)URL savePath:(NSString*)path Downloading:(void(^)(long long PresentSize,long long WholeSize))downloadingBlock Finished:(void(^)(void))finishedBlock error:(void(^)(NSString* error))errorBlock{
    
    DownloadFile* downloadFile = [[DownloadFile alloc] init];
    [downloadFile start:URL savePath:path Downloading:downloadingBlock Finished:finishedBlock error:errorBlock];
    
    //保存句柄防止提前被删了
    if(!downloadFileTask_dic)downloadFileTask_dic = [[NSMutableDictionary alloc] init];
    [downloadFileTask_dic setObject:downloadFile forKey:path];
}

/**
 *  开始下载
 *
 *  @param URL  下载地址
 *  @param path 保存地址
 *  @param downloadingBlock 下载中的回调
 *  @param finishedBlock    下载成功的回调
 *  @param errorBlock       一些错误通知
 */

-(void)start:(NSString*)URL savePath:(NSString*)path Downloading:(void(^)(long long PresentSize,long long WholeSize))downloadingBlock Finished:(void(^)(void))finishedBlock error:(void(^)(NSString* error))errorBlock{
    
    _URL = URL;
    _savePath = path;
    _downloadingBlock = downloadingBlock;
    _finishedBlock = finishedBlock;
    _errorBlock = errorBlock;
    
    //路径检查
    NSString* fileDirPath = [path substringToIndex:path.length - [path lastPathComponent].length-1];
    NSLog(@"%@",fileDirPath);
    BOOL bo = [[NSFileManager defaultManager] createDirectoryAtPath:fileDirPath withIntermediateDirectories:YES attributes:nil error:nil];
    if (bo==NO) {
        _errorBlock(@"创建目录失败");
    }
    
  
    
    NSURL* userInfo_url = [NSURL URLWithString:_URL];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:userInfo_url];
    request.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;//忽略本地缓存数据，直接请求服务端.
    
    
    //如果做成通用方法还需要多判断一下，继续下载的文件是否是这个。
    NSFileManager* mgr = [NSFileManager defaultManager];
    //查看文件是否存在
    if([mgr fileExistsAtPath:_savePath] == NO){
        // 创建一个空的文件到沙盒中
        [mgr createFileAtPath:_savePath contents:nil attributes:nil];
    }else
    //创建一个用来写数据的文件句柄对象
    _writeHandle = [NSFileHandle fileHandleForWritingAtPath:_savePath];
    
    
    _currentLength = [_writeHandle seekToEndOfFile];
    // 设置请求头
    NSString *range = [NSString stringWithFormat:@"bytes=%lld-",_currentLength];
    [request setValue:range forHTTPHeaderField:@"Range"];

    // 发送请求去下载 (发起一个异步请求)
    _connection = [NSURLConnection connectionWithRequest:request delegate:self];
    
    
    
    //开启网络状况的监听
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
    
    _hostReach =[Reachability reachabilityForInternetConnection];
    //    [Reachability reachabilityWithHostName:@"wwww.baidu.com"];//可以以多种形式初始化
    [_hostReach startNotifier]; //开始监听,会启动一个run loop
    
}



/**
 *  继续下载
 */
-(void)resumeDownloadFile{
    
    if(_connection==nil){
        //继续下载
        NSLog(@"继续下载");
        NSURL* userInfo_url = [NSURL URLWithString:_URL];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:userInfo_url];
        request.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;//忽略本地缓存数据，直接请求服务端.
        //设置请求头
        NSString *range = [NSString stringWithFormat:@"bytes=%lld-", _currentLength];
        [request setValue:range forHTTPHeaderField:@"Range"];
        
        //下载
        self.connection = [NSURLConnection connectionWithRequest:request delegate:self];
    }
}


-(void)reachabilityChanged:(NSNotification *)note

{
    
    Reachability *currReach = [note object];
    
    NSParameterAssert([currReach isKindOfClass:[Reachability class]]);
    
    //对连接改变做出响应处理动作
    
    NetworkStatus status = [currReach currentReachabilityStatus];
    
    //没有连接到网络
//    if(status == NotReachable){}
    
    //如果网络变化
    if (status==ReachableViaWiFi||status==ReachableViaWWAN) {
        [self resumeDownloadFile];
    }
    
}














#pragma mark  NSURLConnectionDataDelegate---
/**
 *  请求失败时调用（请求超时、网络异常）
 *
 *  @param error      错误原因
 */
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
//    NSLog(@"%@",[error localizedDescription]);
    NSLog(@"取消下载");
    //取消下载
    [self.connection cancel];
    self.connection = nil;
    
    if(_errorBlock)_errorBlock([error localizedDescription]);
    //尝试一下再次下载
    if (_i) {
        _i = 0;
        [self resumeDownloadFile];
    }
   
}

/**
 *  1.接收到服务器的响应就会调用
 *
 *  @param response   响应
 */
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    _i = 1;
    //获得文件的总大小
    _totalLength = response.expectedContentLength+_currentLength;
    if (_currentLength >= _totalLength) {
        if (_errorBlock) _errorBlock(@"该文件已经下载成功,请勿重复下载");
        [self.connection cancel];
    }
}


/**
 *  2.当接收到服务器返回的实体数据时调用（具体内容，这个方法可能会被调用多次）
 *
 *  @param data       这次返回的数据
 */
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
     if (data) {
        // 移动到文件的最后面
        [_writeHandle seekToEndOfFile];
        // 将数据写入沙盒
        [_writeHandle writeData:data];
        //调用回调
        _currentLength += data.length;
        
        if(_downloadingBlock)_downloadingBlock(_currentLength,_totalLength);
    }
  
}



/**
 *  3.加载完毕后调用（服务器的数据已经完全返回后）
 */
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    //删除引用
    [downloadFileTask_dic removeObjectForKey:_savePath];
    //移除通知
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    if(_finishedBlock)_finishedBlock();
    
}
#pragma mark-----
-(void)dealloc{
    NSLog(@"dealloc");
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
