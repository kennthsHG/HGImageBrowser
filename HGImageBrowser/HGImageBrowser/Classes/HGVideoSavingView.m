//
//  HGVideoSavingView.m
//  HGImageBrowser
//
//  Created by 黄纲 on 2019/11/22.
//

#import "HGVideoSavingView.h"
#import "HGDownLoadManager.h"
#import "HGImageManager.h"
#import "UIImage+UIImage_BlurDark.h"
#import "HGImageManager.h"

@implementation HGVideoSavingView {
    UIView *_bgView;
    UILabel *_progressLabel;
    UILabel *_tipLabel;
    UIImageView *_resultIV;
    CALayer *_progressBgLayer;
    CAShapeLayer *_progressLayer;
}

- (instancetype)init {
    if (self = [super init]) {
        self.frame = UIScreen.mainScreen.bounds;
        
        _bgView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 160, 104)];
        _bgView.center = self.center;
        _bgView.backgroundColor = RGBA(0, 0, 0, .8);
        _bgView.layer.cornerRadius = 4;
        _bgView.layer.masksToBounds = YES;
        
        _progressLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 30, _bgView.frame.size.width, 20)];
        _progressLabel.font = [UIFont boldSystemFontOfSize:14];
        _progressLabel.textAlignment = NSTextAlignmentCenter;
        _progressLabel.textColor = [UIColor whiteColor];
        
        _tipLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 76, _bgView.frame.size.width, 20)];
        _tipLabel.textColor = [UIColor whiteColor];
        _tipLabel.font = [UIFont systemFontOfSize:14];
        _tipLabel.textAlignment = NSTextAlignmentCenter;
        
        _resultIV = [[UIImageView alloc] initWithFrame:CGRectMake(54, 14, 52, 52)];
        
        _progressBgLayer = [CAShapeLayer layer];
        _progressBgLayer.frame = CGRectMake(56, 16, 48, 48);
        _progressBgLayer.borderColor = RGBA(255, 255, 255, .3).CGColor;
        _progressBgLayer.borderWidth = 3;
        _progressBgLayer.cornerRadius = _progressBgLayer.frame.size.width*.5;
        
        _progressLayer = [CAShapeLayer layer];
        _progressLayer.frame = _progressBgLayer.frame;
        _progressLayer.strokeColor = [UIColor whiteColor].CGColor;
        _progressLayer.fillColor = [UIColor clearColor].CGColor;
        _progressLayer.lineWidth = 3.0;
        _progressLayer.lineCap = kCALineCapRound;
        CGFloat r = _progressLayer.frame.size.width*.5 - 1.5;
        UIBezierPath *path = [UIBezierPath bezierPath];
        [path moveToPoint:CGPointMake(_progressLayer.frame.size.width*.5, 1.5)];
        [path addArcWithCenter:CGPointMake(_progressLayer.frame.size.width*.5, _progressLayer.frame.size.height*.5) radius:r startAngle:M_PI*1.5 endAngle:M_PI*3.5 clockwise:YES];
        [path closePath];
        _progressLayer.path = path.CGPath;
        
        [self addSubview:_bgView];
        [_bgView addSubview:_progressLabel];
        [_bgView addSubview:_resultIV];
        [_bgView addSubview:_tipLabel];
        [_bgView.layer addSublayer:_progressBgLayer];
        [_bgView.layer addSublayer:_progressLayer];
        
    }
    return self;
}


- (void)setState:(HGVideoSavingState)state {
    _progressLabel.hidden = state != HGVideoSavingState_Saving;
    _progressLayer.hidden = state != HGVideoSavingState_Saving;
    _progressBgLayer.hidden = state != HGVideoSavingState_Saving;
    _resultIV.hidden = state == HGVideoSavingState_Saving;
    
    switch (state) {
        case HGVideoSavingState_Saving:
            _tipLabel.text = @"正在保存到相册…";
            break;
            
        case HGVideoSavingState_Success: {
            _tipLabel.text = @"保存成功";
            _resultIV.image = [UIImage hg_ImageNamedFromMyBundle:@"toast_save_done"];
            self.userInteractionEnabled = NO;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self hide];
            });
        }
            break;
            
        case HGVideoSavingState_Fail: {
            _tipLabel.text = @"保存失败";
            _resultIV.image = [UIImage hg_ImageNamedFromMyBundle:@"toast_save_fail"];
            self.userInteractionEnabled = NO;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self hide];
            });
        }
            break;
            
        default:
            break;
    }
}

- (void)setProgress:(CGFloat)progress {
    if (progress < 0)
        progress = 0;
    if (progress > 1)
        progress = 1;
    _progressLayer.strokeEnd = progress;
    _progressLabel.text = [NSString stringWithFormat:@"%d%%", (int)(progress*100)];
}

- (void)showToSave{
    self.alpha = 1.0;
    self.state = HGVideoSavingState_Saving;
    self.userInteractionEnabled = YES;
    self.progress = .0;
    
    [UIApplication.sharedApplication.delegate.window addSubview:self];
    [self startSave];
}

- (void)hide {
    [UIView animateWithDuration:.25 animations:^{
        self.alpha = .0;
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
        self.progress = 0;
    }];
}

#pragma mark Authorization
#pragma mark Download

- (void)startSave {
    [self setState:HGVideoSavingState_Saving];
     
     if (self.item.isImageShower) {
            [[HGImageManager sharedInstance]savePhotoWithImage:self.item.image completion:^(PHAsset * _Nonnull asset, NSError * _Nonnull error) {
                if(error){
                     [self setState:HGVideoSavingState_Fail];
                }
                else{
                    [self setState:HGVideoSavingState_Success];
                }
            }];
        }
        else{
            if (self.item.videoUrl) {
                [[HGDownLoadManager sharedInstance] startDownLoad:self.item.videoUrl progressBlock:^(CGFloat nowProgress) {
                    self.progress = nowProgress;
                } successBlock:^(NSString * path) {
                    [[HGImageManager sharedInstance]saveVideoWithUrl:[NSURL fileURLWithPath:path] completion:^(PHAsset * _Nonnull asset, NSError * _Nonnull error) {
                        [self setState:HGVideoSavingState_Success];
                    }];
                } failBlock:^{
                    [self setState:HGVideoSavingState_Fail];
                }];
            }
            else if (self.item.videoPath){
                [[HGImageManager sharedInstance]saveVideoWithUrl:[NSURL fileURLWithPath:self.item.videoPath] completion:^(PHAsset * _Nonnull asset, NSError * _Nonnull error) {
                    if(error){
                        [self setState:HGVideoSavingState_Fail];
                    }
                    else{
                        [self setState:HGVideoSavingState_Success];
                    }
                }];
            }
            else{
                [[HGImageManager sharedInstance]saveVideoWithAsset:self.item.videoAsset completion:^(NSError * _Nonnull error) {
                    if(error){
                        [self setState:HGVideoSavingState_Fail];
                    }
                    else{
                        [self setState:HGVideoSavingState_Success];
                    }
                }];
            }
        }
    
    
}



@end
