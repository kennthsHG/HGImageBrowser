//
//  HGPlayerView.m
//  HGImageBrowser
//
//  Created by 黄纲 on 2019/11/18.
//

#import "HGPlayerView.h"
#import "HGPhotoItem.h"
#import "HGProgressLayer.h"
#import "HGImageManagerProtocol.h"
#import <Photos/PHImageManager.h>
#import <MediaPlayer/MediaPlayer.h>
#import "UIImage+UIImage_BlurDark.h"
#import "HGImageManager.h"

@interface HGPlayerView()<UIScrollViewDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, strong, readwrite) HGPhotoItem *item;

@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVPlayerLayer *playerLayer;

/** 视频音频长度 */
@property (nonatomic, assign) CGFloat timeInterval;
/** 视频是否正在播放 */
@property (nonatomic, assign) BOOL isPlaying;

@property (nonatomic, strong) HGProgressLayer *progressLayer;
@property (nonatomic, copy) id<HGImageManager> imageManager;
/** 播放按钮 */
@property (nonatomic, strong) UIButton *playerButton;

/** 底部视图 */
@property (nonatomic, strong) UIView *playerBottomView;
/** 底部播放按钮 */
@property (nonatomic, strong) UIButton *bottomPlayButton;
/** 当前时间 */
@property (nonatomic, strong) UILabel *currentTimeLabel;
/** 总时间 */
@property (nonatomic, strong) UILabel *totalTimeLabel;
/** 加载进度条 */
@property (nonatomic, strong) UIProgressView *progressView;
/** 视频播放进度条 */
@property (nonatomic, strong) UISlider *videoSlider;
/** player 时间监听 */
@property (nonatomic,strong) id playerTimeObserver;
/** slider正在滑动 */
@property (nonatomic,assign) BOOL isDragingSlider;

@end

@implementation HGPlayerView

- (instancetype)initWithFrame:(CGRect)frame imageManager:(id<HGImageManager>)imageManager {
    self = [super initWithFrame:frame];
    if (self) {
        _imageManager = imageManager;
        [self initCommonUI];
    }
    return self;
}

#pragma mark - UI
- (void)initCommonUI{
    _playerView = [[UIView alloc]initWithFrame:self.bounds];
    [_playerView setBackgroundColor:[UIColor blackColor]];
    [self addSubview:_playerView];
   
    _imageView = [[UIImageView alloc] init];
    _imageView.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
    _imageView.center = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
    _imageView.backgroundColor = [UIColor blackColor];
    _imageView.contentMode = UIViewContentModeScaleAspectFit;
    _imageView.clipsToBounds = YES;
    [self addSubview:_imageView];
   
    _playerButton = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, 300, 300)];
    _playerButton.center = self.playerView.center;
    [_playerButton setImage:[UIImage hg_ImageNamedFromMyBundle:@"video_icon_play"] forState:UIControlStateNormal];
    [_playerButton setImage:[UIImage hg_ImageNamedFromMyBundle:@"video_icon_pause"] forState:UIControlStateSelected];
    _playerButton.hidden = YES;
    [_playerButton addTarget:self action:@selector(playButtonAction) forControlEvents:UIControlEventTouchUpInside];
    [self.playerView addSubview:_playerButton];
    
    _progressLayer = [[HGProgressLayer alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
    _progressLayer.position = CGPointMake([UIScreen mainScreen].bounds.size.width/2, [UIScreen mainScreen].bounds.size.height/2);
    
    [self initBottomView];
}

- (void)bottomViewShowStatus:(BOOL)hiden{
    self.playerBottomView.hidden = hiden;
}

- (void)initBottomView{
    _playerBottomView = [[UIView alloc]initWithFrame:CGRectMake(0, SCREEN_HEIGHT - SafeAreaBottomHeight - 80, SCREEN_WIDTH, 80)];
    [_playerBottomView setBackgroundColor:[UIColor clearColor]];
    [self addSubview:_playerBottomView];
    
    _bottomPlayButton = [[UIButton alloc]initWithFrame:CGRectMake(5, 20, 40, 40)];
    [_bottomPlayButton setImage:[UIImage hg_ImageNamedFromMyBundle:@"video_icon_bottom_play"] forState:UIControlStateNormal];
    [_bottomPlayButton setImage:[UIImage hg_ImageNamedFromMyBundle:@"video_icon_bottom_puase"] forState:UIControlStateSelected];
//    [_bottomPlayButton setImage:[UIImage hg_ImageNamedFromMyBundle:@"video_icon_bottom_play"] forState:UIControlStateSelected];
    [_bottomPlayButton addTarget:self action:@selector(playButtonAction) forControlEvents:UIControlEventTouchUpInside];
    [self.playerBottomView addSubview:_bottomPlayButton];
    
    _currentTimeLabel = [[UILabel alloc]initWithFrame:CGRectMake(45, 32.5, 50, 15)];
    [_currentTimeLabel setFont:[UIFont systemFontOfSize:15]];
    _currentTimeLabel.textAlignment = NSTextAlignmentLeft;
    [_currentTimeLabel setText:@"00:00"];
    [_currentTimeLabel setTextColor:[UIColor whiteColor]];
    [self.playerBottomView addSubview:_currentTimeLabel];
    
    _totalTimeLabel = [[UILabel alloc]initWithFrame:CGRectMake(SCREEN_WIDTH - 50, 32.5, 50, 15)];
    [_totalTimeLabel setFont:[UIFont systemFontOfSize:15]];
    _totalTimeLabel.textAlignment = NSTextAlignmentLeft;
    [_totalTimeLabel setText:@"00:00"];
    [_totalTimeLabel setTextColor:[UIColor whiteColor]];
    [self.playerBottomView addSubview:_totalTimeLabel];
    
    [self.videoSlider setFrame:CGRectMake(105, 30, SCREEN_WIDTH - 175, 20)];
    [self.playerBottomView addSubview:self.videoSlider];
}
#pragma mark - Methods




#pragma mark - Actions



#pragma mark - slider事件
// slider开始滑动事件
- (void)progressSliderTouchBegan:(UISlider *)slider {
    self.isDragingSlider = YES;
    [self.player pause];
}
// slider滑动中事件
- (void)progressSliderValueChanged:(UISlider *)slider {
    CGFloat current = self.timeInterval*slider.value;
    //秒数
    NSInteger proSec = (NSInteger)current%60;
    //分钟
    NSInteger proMin = (NSInteger)current/60;
    _currentTimeLabel.text = [NSString stringWithFormat:@"%02ld:%02ld", proMin, proSec];
    
}
// slider结束滑动事件
- (void)progressSliderTouchEnded:(UISlider *)slider {
    if (self.player.status != AVPlayerStatusReadyToPlay) {
        return;
    }
    //转换成CMTime才能给player来控制播放进度
    __weak typeof(self) weakself = self;
    CMTime dragedCMTime = CMTimeMakeWithSeconds(self.timeInterval * slider.value, 600);
    [self.player seekToTime:dragedCMTime toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:^(BOOL finished) {
        weakself.isDragingSlider = NO;
        if (finished) {
            if (weakself.isPlaying) {
                [weakself.player play];
            }
        }
    }];
    [self performSelector:@selector(playButtonShowStatus:) withObject:[NSNumber numberWithBool:YES] afterDelay:4.f];
}

- (void)tapSlider:(UITapGestureRecognizer *)tap {
    [self progressSliderTouchBegan:self.videoSlider];
    CGPoint point = [tap locationInView:tap.view];
    CGFloat value = point.x/ tap.view.frame.size.width;
    self.videoSlider.value = value;
    [self progressSliderValueChanged:self.videoSlider];
    [self progressSliderTouchEnded:self.videoSlider];
}
#pragma mark - Getters


#pragma mark - Setters


-(void)dealloc{
    [self playerCurrentItemRemoveObserver];
}

- (void)setMovieItem:(HGPhotoItem *)item determinate:(BOOL)determinate{
    _item = item;
    if (item) {
        self.player = nil;
        self.playerLayer = nil;
        [self.progressLayer removeFromSuperlayer];
        if (item.videoImage) {
            self.imageView.image = item.videoImage;
            self.imageView.hidden = NO;
            [self bringSubviewToFront:self.imageView];
        }
        if (item.videoAsset) {
            if (!item.videoImage) {
                [[HGImageManager sharedInstance]getPhotoWithAsset:item.videoAsset completion:^(UIImage * image, NSDictionary * dictionary, BOOL isDegraded) {
                    self.imageView.image = image;
                    self.imageView.hidden = NO;
                    [self.item resetVideoImage:image];
                    [self bringSubviewToFront:self.imageView];
                }];
            }
            [self.imageView.layer addSublayer:_progressLayer];
            [self.progressLayer startSpin];
            self.progressLayer.position = CGPointMake(self.imageView.frame.size.width/2, self.imageView.frame.size.height/2);
            [[HGImageManager sharedInstance]getVideoWithAsset:item.videoAsset completion:^(AVPlayerItem * playerItem, NSDictionary * dictionary) {
                [self.progressLayer stopSpin];
                [self.progressLayer removeFromSuperlayer];
                [self configPlayerWithItem:playerItem];
            }];
        }
        if (item.videoPath) {
            [self configPlayerWithItem:[AVPlayerItem playerItemWithURL:[NSURL fileURLWithPath:item.videoPath]]];
        }
        if (item.videoUrl) {
            [self.imageView.layer addSublayer:_progressLayer];
            [self.progressLayer startSpin];
            [self configPlayerWithItem:[AVPlayerItem playerItemWithURL:item.videoUrl]];
        }
    }
}

- (void)playButtonAction{
    self.playerButton.selected = !self.playerButton.selected;
    self.bottomPlayButton.selected = !self.bottomPlayButton.selected;
    self.imageView.hidden = YES;
    if (self.playerButton.selected || self.bottomPlayButton.selected) {
        CMTime currentTime = _player.currentItem.currentTime;
        CMTime durationTime = _player.currentItem.duration;
        if (_player.rate == 0.0f) {
            if (currentTime.value == durationTime.value) {
               [_player.currentItem seekToTime:CMTimeMake(0, 1)];
            }
        }
        [self.player play];
        self.isPlaying = YES;
    }
    else{
        [self.player pause];
        self.isPlaying = NO;
    }
    
    [self performSelector:@selector(playButtonShowStatus:) withObject:[NSNumber numberWithBool:YES] afterDelay:4.f];
    self.playButtonShowStatus = NO;
}

- (void)playerStopPlaying{
    [self.player seekToTime:CMTimeMakeWithSeconds(0, 600)];
    [self.player pause];
    self.playerButton.selected = NO;
    self.bottomPlayButton.selected = NO;
    self.playButtonShowStatus = YES;
    [self playButtonShowStatus:[NSNumber numberWithBool:NO]];
    [self playerCurrentItemRemoveObserver];
}

- (void)resetPlayer{
    [self.player seekToTime:CMTimeMakeWithSeconds(0, 600)];
    [self.player pause];
    self.playerButton.selected = NO;
    self.bottomPlayButton.selected = NO;
    self.playButtonShowStatus = YES;
    [self playButtonShowStatus:[NSNumber numberWithBool:NO]];
}

- (void)playButtonShowStatus:(NSNumber *)showStatus{
    self.playerButton.hidden = [showStatus boolValue];
    self.playerBottomView.hidden = [showStatus boolValue];
    [[NSNotificationCenter defaultCenter]postNotificationName:HGVideoViewHideenBottomViewNotifiCation object:showStatus];
}

- (void)configPlayerWithItem:(AVPlayerItem *)playerItem {
    self.playerView.hidden = NO;
    
    self.player = [AVPlayer playerWithPlayerItem:playerItem];
    if (!self.playerLayer) {
        self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
        self.playerLayer.backgroundColor = [UIColor blackColor].CGColor;
        self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
        [self.playerView.layer addSublayer:self.playerLayer];
    }
    else{
        [self playerCurrentItemRemoveObserver];
    }
//
    AVURLAsset  *asset;
    
    if (self.item.videoUrl) {
        asset = [AVURLAsset assetWithURL:self.item.videoUrl];
    }
    else{
        asset = (AVURLAsset *)playerItem.asset;
    }

    dispatch_async(dispatch_get_global_queue(0,0), ^{
        NSArray *array = asset.tracks;

        CGSize videoSize = CGSizeZero;

        for(AVAssetTrack  *track in array){
            if([track.mediaType isEqualToString:AVMediaTypeVideo])
            {
                  videoSize = track.naturalSize;
            }
        }
        if (videoSize.width == 0 || videoSize.height == 0) {
            videoSize = CGSizeMake(SCREEN_WIDTH, SCREEN_HEIGHT);
        }
        
        double scale = [UIScreen mainScreen].bounds.size.width / videoSize.width;
        double height = scale *videoSize.height;
        
        if (self.item.videoImage && self.item.videoUrl == nil) {
            scale = [UIScreen mainScreen].bounds.size.width / self.item.videoImage.size.width;
            height = scale *self.item.videoImage.size.height;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
        self.playerView.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, height);
        self.playerView.center = self.center;
        self.playerLayer.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, height);
            
        self.progressLayer.position = CGPointMake([UIScreen mainScreen].bounds.size.width/2, height/2);
                self.playerButton.center = CGPointMake([UIScreen mainScreen].bounds.size.width/2, height/2);
        });
    });
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resetPlayer) name:AVPlayerItemDidPlayToEndTimeNotification object:self.player.currentItem];
    
    //监控状态属性，注意AVPlayer也有一个status属性，通过监控它的status也可以获得播放状态
    [self.player.currentItem addObserver:self forKeyPath:@"status" options:(NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew) context:nil];
}

- (void)setPlayerTime{
    self.timeInterval = CMTimeGetSeconds(self.player.currentItem.asset.duration);
    
    {
        //秒数
        NSInteger proSec = (NSInteger)self.timeInterval%60;
        //分钟
        NSInteger proMin = (NSInteger)self.timeInterval/60;
        _totalTimeLabel.text = [NSString stringWithFormat:@"%02ld:%02ld", proMin, proSec];
    }
    
    [self removeTimeObserver];
     __weak typeof(self) weakSelf = self;
    _playerTimeObserver = [_player addPeriodicTimeObserverForInterval:CMTimeMake(1.0, 10) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
            CGFloat currentTime = CMTimeGetSeconds(time);
        [weakSelf.videoSlider setValue:currentTime/self.timeInterval animated:YES];
        //秒数
        NSInteger proSec = (NSInteger)currentTime%60;
        //分钟
        NSInteger proMin = (NSInteger)currentTime/60;
        weakSelf.currentTimeLabel.text    = [NSString stringWithFormat:@"%02ld:%02ld", proMin, proSec];
    }];
    
}

- (void)removeTimeObserver {
    if (_playerTimeObserver) {
        @try {
            [_player removeTimeObserver:_playerTimeObserver];
        }@catch (id e) {
            
        }@finally {
            _playerTimeObserver = nil;
        }
    }
}

- (void)playerCurrentItemRemoveObserver {
    @try {
         [self.player.currentItem removeObserver:self  forKeyPath:@"status"];
           [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    } @catch (NSException *exception) {
        
    } @finally {
        
    }
   
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    
    AVPlayerItem *playerItem = object;
    if ([keyPath isEqualToString:@"status"]) {
        AVPlayerItemStatus status = [change[@"new"] integerValue];
        switch (status) {
            case AVPlayerItemStatusReadyToPlay:
            {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self.progressLayer removeFromSuperlayer];
                    [self setPlayerTime];
                    self.imageView.hidden = YES;
                    self.playerButton.hidden = NO;
                    self.playerBottomView.hidden = NO;
                    self.item.finished = YES;
                    [self.playerView bringSubviewToFront:self.playerButton];
                });
            }
                break;
            case AVPlayerItemStatusFailed:
            {
                NSLog(@"加载失败");
            }
                break;
            case AVPlayerItemStatusUnknown:
            {
                NSLog(@"未知资源");
            }
                break;
            default:
                break;
        }
    }
}

- (UISlider *)videoSlider {
    if (!_videoSlider) {
        _videoSlider = [[UISlider alloc]init];
        [_videoSlider setThumbImage:[UIImage hg_ImageNamedFromMyBundle:@"video_icon_spot"] forState:UIControlStateNormal];
        _videoSlider.minimumTrackTintColor = RGBA(255, 255, 255, 1);
        _videoSlider.maximumTrackTintColor = RGBA(152, 152, 152, 1);
         //slider开始滑动事件
        [_videoSlider addTarget:self action:@selector(progressSliderTouchBegan:) forControlEvents:UIControlEventTouchDown];
        // slider滑动中事件
        [_videoSlider addTarget:self action:@selector(progressSliderValueChanged:) forControlEvents:UIControlEventValueChanged];
        // slider结束滑动事件
        [_videoSlider addTarget:self action:@selector(progressSliderTouchEnded:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchCancel | UIControlEventTouchUpOutside];
        
        UITapGestureRecognizer *sliderTap=[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapSlider:)];
        [_videoSlider addGestureRecognizer:sliderTap];
    }
    return _videoSlider;
}

@end
