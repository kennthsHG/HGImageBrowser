//
//  HGScrollView.m
//  HGImageBrowser
//
//  Created by 黄纲 on 2019/11/19.
//

#import "HGScrollView.h"

@implementation HGScrollView

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *view = [super hitTest:point withEvent:event];
    if([view isKindOfClass:[UISlider class]]){
      //如果响应view是UISlider,则scrollview禁止滑动
        self.scrollEnabled = NO;
    }else{
      //如果不是,则恢复滑动
      self.scrollEnabled = YES;
    }
    return view;
}


@end
