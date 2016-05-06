//
//  ViewController.h
//  DownloadFile
//
//  Created by C on 16/3/31.
//  Copyright © 2016年 C. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController <NSURLSessionDelegate,NSURLSessionDownloadDelegate>
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@property (weak, nonatomic) IBOutlet UISlider *slider;
/**
 *  下载任务
 */
@property(nonatomic,strong)NSURLSessionDownloadTask* task;

/**
 *  纪录上次暂停下载返回的纪录
 */
@property(nonatomic,strong)NSData* resumData;
/**
 *  创建下载任务属性
 */
@property(nonatomic,strong)NSURLSession* session;




@end

