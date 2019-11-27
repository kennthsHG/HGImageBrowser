//
//  HGSDWebImage.m
//  HGPhotoBrowserDemo
//
//  Created by gang on 2017/11/30.
//  Copyright © 2016 DaShang. All rights reserved.
//

#import "HGSDImageManager.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import <SDWebImage/SDWebImageManager.h>
#import <SDWebImage/SDWebImageDownloader.h>


@implementation HGSDImageManager

- (void)setImageForImageView:(UIImageView *)imageView
                     withURL:(NSURL *)imageURL
                 placeholder:(UIImage *)placeholder
                    progress:(HGImageManagerProgressBlock)progress
                  completion:(HGImageManagerCompletionBlock)completion
{
    SDWebImageDownloaderProgressBlock progressBlock = ^(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL) {
        if (progress) {
            progress(receivedSize, expectedSize);
        }
    };
    SDExternalCompletionBlock completionBlock = ^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
        if (completion) {
            completion(image, imageURL, !error, error);
        }
    };
    
    [imageView sd_setImageWithURL:imageURL placeholderImage:placeholder options:SDWebImageRetryFailed context:nil progress:progressBlock completed:completionBlock];
}

- (void)cancelImageRequestForImageView:(UIImageView *)imageView {
//    [imageView sd_cancelCurrentImageLoad];
}

- (UIImage *)imageFromMemoryForURL:(NSURL *)url {
    return nil;
}

@end

