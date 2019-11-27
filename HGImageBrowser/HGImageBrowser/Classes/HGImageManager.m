//
//  HGImageManager.m
//  HGImageBrowser
//
//  Created by 黄纲 on 2019/11/15.
//

#import "HGImageManager.h"

@interface  HGImageManager() <NSCopying,NSMutableCopying>

@property (nonatomic, assign) CGFloat photoPreviewMaxWidth;

@end

static  HGImageManager *_instance = nil;

CGSize  HGAssetGridThumbnailSize;
CGFloat HGScreenWidth;
CGFloat HGScreenScale;

@implementation HGImageManager

+ (instancetype)sharedInstance {
    return [[self alloc] init];
}

+ (id)allocWithZone:(struct _NSZone *)zone {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!_instance) {
            _instance = [super allocWithZone:zone];
            [_instance configObject];
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

- (void)configObject{
    HGScreenWidth = [UIScreen mainScreen].bounds.size.width;
    HGScreenScale = 2.0;
    if (HGScreenWidth > 700) {
        HGScreenScale = 1.5;
    }
    
    CGFloat margin = 4;
    CGFloat itemWH = (HGScreenWidth - 2 * margin - 4) - margin;
    HGAssetGridThumbnailSize = CGSizeMake(itemWH * HGScreenScale, itemWH * HGScreenScale);
    self.photoPreviewMaxWidth = 800;
}


- (PHImageRequestID)getPhotoWithAsset:(PHAsset *)asset
                           completion:(void (^)(UIImage *, NSDictionary *, BOOL isDegraded))completion {
    CGFloat fullScreenWidth = HGScreenWidth;
    if (fullScreenWidth > _photoPreviewMaxWidth) {
        fullScreenWidth = _photoPreviewMaxWidth;
    }
    return [self getPhotoWithAsset:asset photoWidth:fullScreenWidth completion:completion progressHandler:nil networkAccessAllowed:YES];
}

- (PHImageRequestID)getPhotoWithAsset:(PHAsset *)asset
                           photoWidth:(CGFloat)photoWidth
                           completion:(void (^)(UIImage *photo,NSDictionary *info,BOOL isDegraded))completion
                      progressHandler:(void (^)(double progress, NSError *error, BOOL *stop, NSDictionary *info))progressHandler networkAccessAllowed:(BOOL)networkAccessAllowed {
    CGSize imageSize;
    if (photoWidth < HGScreenWidth && photoWidth < _photoPreviewMaxWidth) {
        imageSize = HGAssetGridThumbnailSize;
    } else {
        PHAsset *phAsset = (PHAsset *)asset;
        CGFloat aspectRatio = phAsset.pixelWidth / (CGFloat)phAsset.pixelHeight;
        CGFloat pixelWidth = photoWidth * HGScreenScale;
        // 超宽图片
        if (aspectRatio > 1.8) {
            pixelWidth = pixelWidth * aspectRatio;
        }
        // 超高图片
        if (aspectRatio < 0.2) {
            pixelWidth = pixelWidth * 0.5;
        }
        CGFloat pixelHeight = pixelWidth / aspectRatio;
        imageSize = CGSizeMake(pixelWidth, pixelHeight);
    }
    
    __block UIImage *image;
    PHImageRequestOptions *option = [[PHImageRequestOptions alloc] init];
    option.resizeMode = PHImageRequestOptionsResizeModeFast;
    int32_t imageRequestID = [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:imageSize contentMode:PHImageContentModeAspectFill options:option resultHandler:^(UIImage *result, NSDictionary *info) {
        if (result) {
            image = result;
        }
        BOOL downloadFinined = (![[info objectForKey:PHImageCancelledKey] boolValue] && ![info objectForKey:PHImageErrorKey]);
        if (downloadFinined && result) {
            if (completion) completion(result,info,[[info objectForKey:PHImageResultIsDegradedKey] boolValue]);
        }
        // Download image from iCloud / 从iCloud下载图片
        if ([info objectForKey:PHImageResultIsInCloudKey] && !result && networkAccessAllowed) {
            PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
            options.progressHandler = ^(double progress, NSError *error, BOOL *stop, NSDictionary *info) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (progressHandler) {
                        progressHandler(progress, error, stop, info);
                    }
                });
            };
            options.networkAccessAllowed = YES;
            options.resizeMode = PHImageRequestOptionsResizeModeFast;
            [[PHImageManager defaultManager] requestImageDataForAsset:asset options:options resultHandler:^(NSData *imageData, NSString *dataUTI, UIImageOrientation orientation, NSDictionary *info) {
                UIImage *resultImage = [UIImage imageWithData:imageData];
                if (completion) completion(resultImage,info,NO);
            }];
        }
    }];
    return imageRequestID;
}

/// Get Video / 获取视频
- (void)getVideoWithAsset:(PHAsset *)asset
               completion:(void (^)(AVPlayerItem *, NSDictionary *))completion {
    [self getVideoWithAsset:asset progressHandler:nil completion:completion];
}

- (void)getVideoWithAsset:(PHAsset *)asset
          progressHandler:(void (^)(double progress, NSError *error, BOOL *stop, NSDictionary *info))progressHandler completion:(void (^)(AVPlayerItem *, NSDictionary *))completion {
    PHVideoRequestOptions *option = [[PHVideoRequestOptions alloc] init];
    option.networkAccessAllowed = YES;
    option.progressHandler = ^(double progress, NSError *error, BOOL *stop, NSDictionary *info) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (progressHandler) {
                progressHandler(progress, error, stop, info);
            }
        });
    };
    [[PHImageManager defaultManager] requestPlayerItemForVideo:asset options:option resultHandler:^(AVPlayerItem *playerItem, NSDictionary *info) {
        if (completion) completion(playerItem,info);
    }];
}

- (void)savePhotoWithImage:(UIImage *)image
                completion:(void (^)(PHAsset *asset, NSError *error))completion {
    __block NSString *localIdentifier = nil;
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        PHAssetChangeRequest *request = [PHAssetChangeRequest creationRequestForAssetFromImage:image];
        localIdentifier = request.placeholderForCreatedAsset.localIdentifier;
        request.creationDate = [NSDate date];
    } completionHandler:^(BOOL success, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success && completion) {
                PHAsset *asset = [[PHAsset fetchAssetsWithLocalIdentifiers:@[localIdentifier] options:nil] firstObject];
                completion(asset, nil);
            } else if (error) {
                NSLog(@"保存照片出错:%@",error.localizedDescription);
                if (completion) {
                    completion(nil, error);
                }
            }
        });
    }];
}

- (void)saveVideoWithAsset:(PHAsset *)asset
                 completion:(void (^)(NSError *error))completion {
    
    [self getVideoWithAsset:asset completion:^(AVPlayerItem * _Nonnull item, NSDictionary * _Nonnull info) {
        AVURLAsset *videoasset = (AVURLAsset *)item.asset;
        NSURL *videoUrl = videoasset.URL;
        
        __block NSString *localIdentifier = nil;
           [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
               PHAssetChangeRequest *request = [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:videoUrl];
               localIdentifier = request.placeholderForCreatedAsset.localIdentifier;
               request.creationDate = [NSDate date];
           } completionHandler:^(BOOL success, NSError *error) {
               dispatch_async(dispatch_get_main_queue(), ^{
                   if (success && completion) {
                       completion(nil);
                   } else if (error) {
                       NSLog(@"保存视频出错:%@",error.localizedDescription);
                       if (completion) {
                           completion(error);
                       }
                   }
               });
           }];
    }];
}

- (void)saveVideoWithUrl:(NSURL *)url
              completion:(void (^)(PHAsset *asset, NSError *error))completion{
    __block NSString *localIdentifier = nil;
       [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
           PHAssetChangeRequest *request = [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:url];
           localIdentifier = request.placeholderForCreatedAsset.localIdentifier;
           request.creationDate = [NSDate date];
       } completionHandler:^(BOOL success, NSError *error) {
           dispatch_async(dispatch_get_main_queue(), ^{
               if (success && completion) {
                   PHAsset *asset = [[PHAsset fetchAssetsWithLocalIdentifiers:@[localIdentifier] options:nil] firstObject];
                   completion(asset, nil);
               } else if (error) {
                   NSLog(@"保存视频出错:%@",error.localizedDescription);
                   if (completion) {
                       completion(nil, error);
                   }
               }
           });
       }];
}

@end
