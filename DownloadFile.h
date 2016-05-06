//
//  DownloadFile2.h
//  DownloadFile
//
//  Created by cxh on 16/5/6.
//  Copyright © 2016年 C. All rights reserved.
//


//参考
//http://www.jianshu.com/p/f65e32012f07

#import <Foundation/Foundation.h>
#import "Reachability.h"

@interface DownloadFile : NSObject<NSURLConnectionDataDelegate>

@property (nonatomic) Reachability *hostReach;//用于监听网络信息

@property(nonatomic,strong)NSFileHandle* writeHandle;//写入句柄

@property(nonatomic,strong)NSURLConnection* connection;//任务句柄


/**
 *  开始下载
 *
 *  @param URL  下载地址
 *  @param path 保存地址
 *  @param downloadingBlock 下载中的回调
 *  @param finishedBlock    下载成功的回调
 *  @param errorBlock       一些错误通知
 */

+(void)start:(NSString*)URL savePath:(NSString*)path Downloading:(void(^)(long long PresentSize,long long WholeSize))downloadingBlock Finished:(void(^)(void))finishedBlock error:(void(^)(NSString* error))errorBlock;




@end
