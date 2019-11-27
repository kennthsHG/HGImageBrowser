//
//  HGProgressLayer.m
//  HGPhotoBrowser
//
//  Created by gang on 2017/11/30.
//  Copyright © 2016 DaShang. All rights reserved.
//

#import "HGProgressLayer.h"

@interface HGProgressLayer ()<CAAnimationDelegate>

@property (nonatomic, assign) BOOL isSpinning;

@end

@implementation HGProgressLayer

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super init];
    if (self) {
        self.frame = frame;
        self.cornerRadius = 20;
        self.fillColor = [UIColor clearColor].CGColor;
        self.strokeColor = [UIColor whiteColor].CGColor;
        self.lineWidth = 4;
        self.lineCap = kCALineCapRound;
        self.strokeStart = 0;
        self.strokeEnd = 0.01;
        self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5].CGColor;
        
        UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectInset(self.bounds, 2, 2) cornerRadius:20-2];
        self.path = path.CGPath;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)applicationDidBecomeActive:(NSNotification *)notification {
    if (self.isSpinning) {
        [self startSpin];
    }
}

- (void)startSpin {
    self.isSpinning = YES;
    [self spinWithAngle:M_PI];
}

- (void)spinWithAngle:(CGFloat)angle {
    self.strokeEnd = 0.33;
    CABasicAnimation *rotationAnimation;
    rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotationAnimation.toValue = @(M_PI-0.5);
    rotationAnimation.duration = 0.4;
    rotationAnimation.cumulative = YES;
    rotationAnimation.repeatCount = HUGE;
    [self addAnimation:rotationAnimation forKey:nil];
}

- (void)stopSpin {
    self.isSpinning = NO;
    [self removeAllAnimations];
}

@end

