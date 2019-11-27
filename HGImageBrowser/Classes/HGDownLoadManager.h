//
//  HGDownLoadManager.h
//  HGImageBrowser
//
//  Created by 黄纲 on 2019/11/22.
//


#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^HGProgressBlock)(CGFloat nowProgress);
typedef void(^HGSuccessBlock)(NSString *path);
typedef void(^HGFailBlock)(void);

@interface HGDownLoadManager : NSObject

+ (instancetype)sharedInstance;

@property (nonatomic, copy) HGProgressBlock progressBlock;
@property (nonatomic, copy) HGSuccessBlock successBlock;
@property (nonatomic, copy) HGFailBlock failBlock;

- (void)startDownLoad:(NSURL *)downLoadUrl
        progressBlock:(HGProgressBlock)progressBlock
         successBlock:(HGSuccessBlock)successBlock
            failBlock:(HGFailBlock)failBlock;

@end

NS_ASSUME_NONNULL_END
