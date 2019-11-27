//
//  HGPlayerView.h
//  HGImageBrowser
//
//  Created by 黄纲 on 2019/11/18.
//

#import <UIKit/UIKit.h>


NS_ASSUME_NONNULL_BEGIN
@protocol HGImageManager;
@class HGPhotoItem;

@interface HGPlayerView : UIView

@property (nonatomic, strong, readonly) HGPhotoItem *item;

@property (nonatomic, strong) UIView *playerView;

@property (nonatomic, strong) UIImageView *imageView;

@property (nonatomic, assign) BOOL playButtonShowStatus;

- (instancetype)initWithFrame:(CGRect)frame imageManager:(id<HGImageManager>)imageManager;

- (void)setMovieItem:(HGPhotoItem *)item determinate:(BOOL)determinate;

- (void)bottomViewShowStatus:(BOOL)hiden;

- (void)playButtonShowStatus:(NSNumber *)showStatus;

- (void)playerStopPlaying;
@end

NS_ASSUME_NONNULL_END
