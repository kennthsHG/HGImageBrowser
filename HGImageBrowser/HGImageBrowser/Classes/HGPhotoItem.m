//
//  HGPhotoItem.m
//  HGPhotoBrowser
//
//  Created by gang on 2017/11/30.
//  Copyright © 2016 DaShang. All rights reserved.
//

#import "HGPhotoItem.h"

@interface HGPhotoItem ()

@property (nonatomic, strong, readwrite) UIView *sourceView;
@property (nonatomic, strong, readwrite) UIImage *thumbImage;
@property (nonatomic, strong, readwrite) NSURL *imageUrl;
@property (nonatomic, strong, readwrite) PHAsset *imageAsset;

@property (nonatomic, strong, readwrite) PHAsset *videoAsset;
@property (nonatomic, strong, readwrite) NSURL *videoUrl;
@property (nonatomic, strong, readwrite) UIImage *videoImage;

@property (nonatomic, assign, readwrite) BOOL isImageShower;
@end

@implementation HGPhotoItem

- (instancetype)initWithSourceView:(nullable UIView *)view
                             image:(nullable UIImage *)image
                        thumbImage:(nullable UIImage *)thumbImage
                          imageUrl:(nullable NSURL *)url{
    self = [super init];
    if (self) {
        _sourceView = view;
        _thumbImage = thumbImage;
        if (url.absoluteString) {
            _imageUrl = [self translateIllegalCharacterWtihUrlStr:url.absoluteString];
        }
        _image = image;
    }
    return self;
}

- (instancetype)initWithSourceView:(nullable UIView *)view
                        imageAsset:(nullable PHAsset *)imageAsset{
    self = [super init];
    if (self) {
        _sourceView = view;
        _imageAsset = imageAsset;
    }
    return self;
}

- (instancetype)initWithSourceView:(nullable UIView *)view
                         imagePath:(nullable NSString *)imagePath{
    self = [super init];
    if (self) {
        _sourceView = view;
        _imagePath = imagePath;
    }
    return self;
}

- (instancetype)initWithSourceView:(nullable UIView *)view
                        videoAsset:(nullable PHAsset *)videoAsset
                        videoImage:(nullable UIImage *)videoImage{
    self = [super init];
    if (self) {
        _sourceView = view;
        _videoAsset = videoAsset;
        _videoImage = videoImage;
    }
    return self;
}

- (instancetype)initWithSourceView:(nullable UIView *)view
                        videoImage:(nullable UIImage *)videoImage
                          videoUrl:(nullable NSURL *)videoUrl{
    self = [super init];
    if (self) {
        _sourceView = view;
        _videoImage = videoImage;
        if (videoUrl.absoluteString) {
             _videoUrl = [self translateIllegalCharacterWtihUrlStr:videoUrl.absoluteString];
         }
    }
    return self;
}

- (instancetype)initWithSourceView:(nullable UIView *)view
                        videoImage:(nullable UIImage *)videoImage
                         videoPath:(nullable NSString *)videoPath{
    self = [super init];
    if (self) {
        _sourceView = view;
        _videoImage = videoImage;
        _videoPath = videoPath;
    }
    return self;
}

- (BOOL)isImageShower{
    return (self.imageAsset || self.imageUrl || self.image || self.imagePath);
}

- (void)resetVideoImage:(UIImage *)videoImage{
    self.videoImage = videoImage;
}

- (NSURL *)translateIllegalCharacterWtihUrlStr:(NSString *)yourUrl{
    //如果链接中存在中文或某些特殊字符，需要通过以下代码转译
    yourUrl = [yourUrl stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSString *encodedString = [yourUrl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    return [NSURL URLWithString:encodedString];
}

@end

