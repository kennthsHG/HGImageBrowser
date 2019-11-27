//
//  HGImageManager.h
//  HGImageBrowser
//
//  Created by 黄纲 on 2019/11/15.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

@interface HGImageManager : NSObject

+ (instancetype)sharedInstance;

- (PHImageRequestID)getPhotoWithAsset:(PHAsset *)asset
                           completion:(void (^)(UIImage *, NSDictionary *, BOOL isDegraded))completion;

- (void)getVideoWithAsset:(PHAsset *)asset
               completion:(void (^)(AVPlayerItem *, NSDictionary *))completion;

- (void)savePhotoWithImage:(UIImage *)image
                completion:(void (^)(PHAsset *asset, NSError *error))completion;

- (void)saveVideoWithAsset:(PHAsset *)asset
              completion:(void (^)(NSError *error))completion;

- (void)saveVideoWithUrl:(NSURL *)url
              completion:(void (^)(PHAsset *asset, NSError *error))completion;
@end

NS_ASSUME_NONNULL_END
