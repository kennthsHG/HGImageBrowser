//
//  HGPhotoView.h
//  HGPhotoBrowser
//
//  Created by 黄纲 on 2019/11/15.
//

#import <UIKit/UIKit.h>
#import "HGProgressLayer.h"
#import "HGPlayerView.h"
#import "HGScrollView.h"
NS_ASSUME_NONNULL_BEGIN

@protocol HGImageManager;
@class HGPhotoItem;

@interface HGPhotoView : HGScrollView

@property (nonatomic, strong) HGPlayerView *videoView;

@property (nonatomic, strong, readonly) UIImageView *imageView;
@property (nonatomic, strong, readonly) HGProgressLayer *progressLayer;
@property (nonatomic, strong, readonly) HGPhotoItem *item;
@property (nonatomic, copy) dispatch_block_t playButtonActionBlock;

@property (nonatomic, assign) BOOL playButtonShowStatus;

- (instancetype)initWithFrame:(CGRect)frame imageManager:(id<HGImageManager>)imageManager;
- (void)setItem:(HGPhotoItem *)item determinate:(BOOL)determinate;
- (void)resizeImageView;
- (void)resizingImageView;
- (void)cancelCurrentImageLoad;

@end

NS_ASSUME_NONNULL_END

