//
//  HGPhotoBrowser.h
//  HGPhotoBrowser
//
//  Created by 黄纲 on 2019/11/15.
//

#import <UIKit/UIKit.h>
#import "HGPhotoItem.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, HGPhotoBrowserInteractiveDismissalStyle) {
    HGPhotoBrowserInteractiveDismissalStyleRotation,
    HGPhotoBrowserInteractiveDismissalStyleScale,
    HGPhotoBrowserInteractiveDismissalStyleSlide,
    HGPhotoBrowserInteractiveDismissalStyleNone
};

typedef NS_ENUM(NSUInteger, HGPhotoBrowserBackgroundStyle) {
    HGPhotoBrowserBackgroundStyleBlurPhoto,
    HGPhotoBrowserBackgroundStyleBlur,
    HGPhotoBrowserBackgroundStyleBlack
};

typedef NS_ENUM(NSUInteger, HGPhotoBrowserImageLoadingStyle) {
    HGPhotoBrowserImageLoadingStyleIndeterminate,
    HGPhotoBrowserImageLoadingStyleDeterminate
};

@protocol HGPhotoBrowserDelegate, HGImageManager;
@class HGPhotoView;

@interface HGPhotoBrowser : UIViewController
/**图片浏览消失样式  默认渐隐*/
@property (nonatomic, assign) HGPhotoBrowserInteractiveDismissalStyle dismissalStyle;
/**图片浏览背景样式  默认黑色*/
@property (nonatomic, assign) HGPhotoBrowserBackgroundStyle backgroundStyle;
/**图片展示图片样式  默认展示等待提示*/
@property (nonatomic, assign) HGPhotoBrowserImageLoadingStyle loadingStyle;

/**显示右侧保存按钮 默认为TRUE */
@property (nonatomic, assign) BOOL showRightButtonToSave;
/**是否显示长按保存 默认为TRUE */
@property (nonatomic, assign) BOOL showLongTapToSave;
/**是否点击页面消失 默认为TRUE（不支持视频） */
@property (nonatomic, assign) BOOL tapToLeave;

@property (nonatomic, weak)   id<HGPhotoBrowserDelegate> delegate;

+ (instancetype)browserWithPhotoItems:(NSArray<HGPhotoItem *> *)photoItems selectedIndex:(NSUInteger)selectedIndex;

- (void)showFromViewController:(UIViewController *)vc;

@end

@protocol HGPhotoBrowserDelegate <NSObject>

/**
图片浏览滑动到某一页

@param index 当前页数
@param currentPhotoView 当前图片视图
*/
- (void)photoBrowserDidScrollToIndex:(NSUInteger)index
                    currentPhotoView:(HGPhotoView *)currentPhotoView;

/**
图片浏览滑动到某一页加载用户自定义视图

@param index 当前页数
@return 需要展示的视图
*/
- (UIView *)photoBrowsertheIndexShowView:(NSUInteger)index;

@end

NS_ASSUME_NONNULL_END

