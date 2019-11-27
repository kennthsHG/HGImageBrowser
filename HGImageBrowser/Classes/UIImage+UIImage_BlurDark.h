//
//  UIImage+UIImage_BlurDark.h
//  KSPhotoBrowserDemo
//
//  Created by 黄纲 on 2019/11/15.
//

#import <UIKit/UIKit.h>

@interface UIImage (UIImage_BlurDark)

+ (UIImage *)hg_ImageNamedFromMyBundle:(NSString *)name;

- (UIImage *)hg_imageByBlurDark;
- (UIImage *)hg_imageByBlurWithTint:(UIColor *)tintColor;
@end
