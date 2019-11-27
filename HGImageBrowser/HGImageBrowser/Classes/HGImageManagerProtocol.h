//
//  HGWebImageProtocol.h
//  HGPhotoBrowserDemo
//
//  Created by 黄纲 on 2019/11/15.
//

#import <UIKit/UIKit.h>
#import <SDWebImage/UIImageView+WebCache.h>

typedef void (^HGImageManagerProgressBlock)(NSInteger receivedSize, NSInteger expectedSize);

typedef void (^HGImageManagerCompletionBlock)(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * imageURL);

@protocol HGImageManager <NSObject>

- (void)setImageForImageView:(nullable UIImageView *)imageView
                     withURL:(nullable NSURL *)imageURL
                 placeholder:(nullable UIImage *)placeholder
                    progress:(nullable HGImageManagerProgressBlock)progress
                  completion:(nullable HGImageManagerCompletionBlock)completion;

- (void)cancelImageRequestForImageView:(nullable UIImageView *)imageView;

- (UIImage *_Nullable)imageFromMemoryForURL:(nullable NSURL *)url;

@end

