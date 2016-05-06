//
//  DownloadFile.h
//  DownloadFile
//
//  Created by C on 16/4/2.
//  Copyright © 2016年 C. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Reachability.h"
@interface DownloadFile : NSObject<NSURLSessionDownloadDelegate>
@property (nonatomic) Reachability *hostReach;

//该任务的名字
@property(nonatomic,strong)NSString* name;
//下载属性
@property(nonatomic,strong)NSURLSession* session;

/**
 *  纪录上次暂停下载返回的纪录
 */
@property(nonatomic,strong)NSData* resumeData;
/**
 *  下载任务
 */
@property(nonatomic,strong)NSURLSessionDownloadTask* task;


/**
*  开始下载
*
*  @param URL  下载地址
*  @param path 保存地址
*  @param downloadingBlock 下载中的回调
*  @param finishedBlock    下载成功的回调
*  @param name             下载任务的名字用来暂停时使用
*/

+(void)start:(NSString*)URL savePath:(NSString*)path Downloading:(void(^)(long long PresentSize,long long WholeSize))downloadingBlock Finished:(void(^)(void))finishedBlock name:(NSString*)name;

/**
 *  暂停全部下载任务并保存断点下载的数据
 */
+(void)pause;

/**
 *  暂停一个任务
 *
 *  @param name 该任务的名字
 */
+(void)pause:(NSString*)name;






/**
 *  继续下载全部下载任务并保存断点下载的数据
 */
+(void)resume;

/**
 *  继续下载一个任务
 *
 *  @param name 该任务的名字
 */
+(void)resume:(NSString*)name;


@end
