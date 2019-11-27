//
//  HGDownLoadManager.m
//  HGImageBrowser
//
//  Created by 黄纲 on 2019/11/22.
//

#import "HGDownLoadManager.h"

@interface  HGDownLoadManager() <NSCopying,NSMutableCopying,NSURLSessionDelegate>

@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSURLSessionDownloadTask *task;

@end

static  HGDownLoadManager *_instance = nil;

@implementation HGDownLoadManager

+ (instancetype)sharedInstance {
    return [[self alloc] init];
}

+ (id)allocWithZone:(struct _NSZone *)zone {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
                  if (!_instance) {
                  _instance = [super allocWithZone:zone];
                  }
                  });
    return _instance;
}

- (nonnull id)copyWithZone:(nullable NSZone *)zone {
    return _instance;
}

- (nonnull id)mutableCopyWithZone:(nullable NSZone *)zone {
    return _instance;
}

//1.获取NSURLSession
- (NSURLSession *)session{
    if (!_session) {
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        _session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    }
    return _session;
}

//2.开始下载任务
- (void)startDownLoad:(NSURL *)downLoadUrl
        progressBlock:(HGProgressBlock)progressBlock
         successBlock:(HGSuccessBlock)successBlock
            failBlock:(HGFailBlock)failBlock{
    self.progressBlock = progressBlock;
    self.successBlock = successBlock;
    self.failBlock = failBlock;
    
    self.task = [self.session downloadTaskWithURL:downLoadUrl];
    [self.task resume];
}

#pragma mark -- NSURLSessionDownloadDelegate
/**
 下载数据写入本地（可能会调用多次）

 @param bytesWritten 本次写入数据大小
 @param totalBytesWritten 已经写入数据大小
 @param totalBytesExpectedToWrite 总共需要写入数据大小
 */
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite{
    //获取下载进度
    double progress = (double)totalBytesWritten / totalBytesExpectedToWrite;
    self.progressBlock ? self.progressBlock(progress) : nil;
    NSLog(@"%f",progress);
}

/**
 恢复下载
 */
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didResumeAtOffset:(int64_t)fileOffset expectedTotalBytes:(int64_t)expectedTotalBytes{
    
}

/**
 下载完成调用

 @param location 写入本地临时路经（temp文件夹里面）
 */
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location{
    NSString *caches = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    //获取服务器的文件名
    NSString *fileName = downloadTask.response.suggestedFilename;
    //创建需要保存在本地的文件路径
    NSString *filePath = [caches stringByAppendingPathComponent:fileName];
    //将下载的文件剪切到上面的路径
    [[NSFileManager defaultManager] moveItemAtPath:location.path toPath:filePath error:nil];
    self.successBlock ? self.successBlock(filePath) : nil;
}
@end
