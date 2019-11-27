//
//  HGPhotoView.m
//  HGPhotoBrowser
//
//  Created by gang on 2017/11/30.
//  Copyright © 2016 DaShang. All rights reserved.
//

#import "HGPhotoView.h"
#import "HGPhotoItem.h"
#import "HGProgressLayer.h"
#import "HGImageManagerProtocol.h"
#import <Photos/PHImageManager.h>
#import <MediaPlayer/MediaPlayer.h>
#import "HGImageManager.h"
#import "UIImage+UIImage_BlurDark.h"

@interface HGPhotoView ()<UIScrollViewDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, strong, readwrite) UIImageView *imageView;
@property (nonatomic, strong, readwrite) HGProgressLayer *progressLayer;
@property (nonatomic, strong, readwrite) HGPhotoItem *item;
@property (nonatomic, copy) id<HGImageManager> imageManager;

@property (nonatomic, strong) UIButton *playerButton;

@end

@implementation HGPhotoView

- (instancetype)initWithFrame:(CGRect)frame imageManager:(id<HGImageManager>)imageManager {
    self = [super initWithFrame:frame];
    if (self) {
        self.bouncesZoom = YES;
        self.maximumZoomScale = kHGPhotoViewMaxScale;
        self.multipleTouchEnabled = YES;
        self.showsHorizontalScrollIndicator = YES;
        self.showsVerticalScrollIndicator = YES;
        self.delegate = self;
        if (@available(iOS 11.0, *)) {
            self.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
        
        _videoView = [[HGPlayerView alloc]initWithFrame:self.bounds imageManager:imageManager];
        _videoView.hidden = YES;
        [self addSubview:_videoView];
        
        _imageView = [[UIImageView alloc] init];
        _imageView.backgroundColor = [UIColor blackColor];
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
        _imageView.clipsToBounds = YES;
        _imageView.hidden = NO;
        [self addSubview:_imageView];
        [self resizingImageView];
        
        _progressLayer = [[HGProgressLayer alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
        _progressLayer.position = CGPointMake(frame.size.width/2, frame.size.height/2);
        _progressLayer.hidden = YES;
        [self.layer addSublayer:_progressLayer];
        
        _imageManager = imageManager;
    }
    return self;
}

- (void)setItem:(HGPhotoItem *)item determinate:(BOOL)determinate{
    _item = item;
    if (item.isImageShower) {
        self.imageView.hidden = NO;
        [self setImageItem:item determinate:determinate];
    }
    else{
        self.videoView.hidden = NO;
        self.imageView.hidden = YES;
        [self.videoView setMovieItem:item determinate:determinate];
    }
}

- (void)setImageItem:(HGPhotoItem *)item determinate:(BOOL)determinate{
    self.videoView.hidden = YES;
    self.imageView.hidden = NO;
    [_imageManager cancelImageRequestForImageView:_imageView];
       if (item) {
           if (item.image) {
               _imageView.image = item.image;
               _item.finished = YES;
               [_progressLayer stopSpin];
               _progressLayer.hidden = YES;
               [self resizeImageView];
               return;
           }
           if (item.imagePath) {
               _imageView.image = [UIImage imageWithContentsOfFile:item.imagePath];
               _item.finished = YES;
               [_progressLayer stopSpin];
               _progressLayer.hidden = YES;
               [self resizeImageView];
               return;
           }
           __weak typeof(self) wself = self;
           if (item.imageAsset) {
               [[HGImageManager sharedInstance]getPhotoWithAsset:item.imageAsset completion:^(UIImage * image, NSDictionary * dictionary, BOOL isDegraded) {
                   __strong typeof(wself) sself = wself;
                   sself.imageView.image = image;
                   sself.item.finished = YES;
                   [sself.progressLayer stopSpin];
                   sself.progressLayer.hidden = YES;
                   [sself resizeImageView];
               }];
               return;
           }
           if (item.thumbImage) {
               _imageView.image = item.image;
               [self resizeImageView];
           }

           HGImageManagerProgressBlock progressBlock = nil;
           if (determinate) {
               progressBlock = ^(NSInteger receivedSize, NSInteger expectedSize) {
                   __strong typeof(wself) sself = wself;
                   double progress = (double)receivedSize / expectedSize;
                   sself.progressLayer.hidden = NO;
                   sself.progressLayer.strokeEnd = MAX(progress, 0.01);
               };
           } else {
               [_progressLayer startSpin];
           }
           _progressLayer.hidden = NO;
           
           _imageView.image = item.thumbImage;
           [_imageManager setImageForImageView:_imageView withURL:item.imageUrl placeholder:item.thumbImage progress:progressBlock completion:^(UIImage * _Nullable image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                   __strong typeof(wself) sself = wself;
                   [sself resizeImageView];
                   [sself.progressLayer stopSpin];
                   sself.progressLayer.hidden = YES;
                   sself.item.finished = YES;
           }];
       } else {
           [_progressLayer stopSpin];
           _progressLayer.hidden = YES;
           _imageView.image = nil;
       }
       [self resizeImageView];
}

- (void)resizeImageView {
    if (_imageView.image) {
        CGSize imageSize = _imageView.image.size;
        CGFloat width = _imageView.frame.size.width;
        CGFloat height = width * (imageSize.height / imageSize.width);
        CGRect rect = CGRectMake(0, 0, width, height);
        _imageView.frame = rect;
        
        // If image is very high, show top content.
        if (height <= self.bounds.size.height) {
            _imageView.center = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
        } else {
            _imageView.center = CGPointMake(self.bounds.size.width/2, height/2);
        }
        
        // If image is very wide, make sure user can zoom to fullscreen.
        if (width / height > 2) {
            self.maximumZoomScale = self.bounds.size.height / height;
        }
    } else {
        CGFloat width = self.frame.size.width - 2 * kHGPhotoViewHGadding;
        _imageView.frame = CGRectMake(0, 0, width, width * 2.0 / 3);
        _imageView.center = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
    }
    self.contentSize = _imageView.frame.size;
}

- (void)resizingImageView{
    
    _imageView.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
    _imageView.center = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
    self.contentSize = _imageView.frame.size;
}

- (void)cancelCurrentImageLoad {
    [_imageManager cancelImageRequestForImageView:_imageView];
    [_progressLayer stopSpin];
}

- (BOOL)isScrollViewOnTopOrBottom {
    CGPoint translation = [self.panGestureRecognizer translationInView:self];
    if (translation.y > 0 && self.contentOffset.y <= 0) {
        return YES;
    }
    CGFloat maxOffsetY = floor(self.contentSize.height - self.bounds.size.height);
    if (translation.y < 0 && self.contentOffset.y >= maxOffsetY) {
        return YES;
    }
    return NO;
}

#pragma mark - ScrollViewDelegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    if (self.item.isImageShower) {
        return _imageView;
    }
    else{
        return self.videoView.playerView;
    }
    
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    CGFloat offsetX = (scrollView.bounds.size.width > scrollView.contentSize.width)?
    (scrollView.bounds.size.width - scrollView.contentSize.width) * 0.5 : 0.0;
    
    CGFloat offsetY = (scrollView.bounds.size.height > scrollView.contentSize.height)?
    (scrollView.bounds.size.height - scrollView.contentSize.height) * 0.5 : 0.0;
    
    if (self.item.isImageShower) {
        self.imageView.center = CGPointMake(scrollView.contentSize.width * 0.5 + offsetX,
        scrollView.contentSize.height * 0.5 + offsetY);
     }
     else{
        self.videoView.playerView.center = CGPointMake(scrollView.contentSize.width * 0.5 + offsetX,
        scrollView.contentSize.height * 0.5 + offsetY);
     }
    
}

#pragma mark - GestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer == self.panGestureRecognizer) {
        if (gestureRecognizer.state == UIGestureRecognizerStatePossible) {
            if ([self isScrollViewOnTopOrBottom]) {
                return NO;
            }
        }
    }
    return YES;
}


@end

