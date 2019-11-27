//
//  HGProgressLayer.h
//  HGPhotoBrowser
//
//  Created by 黄纲 on 2019/11/15.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface HGProgressLayer : CAShapeLayer

- (instancetype)initWithFrame:(CGRect)frame;
- (void)startSpin;
- (void)stopSpin;

@end

NS_ASSUME_NONNULL_END

