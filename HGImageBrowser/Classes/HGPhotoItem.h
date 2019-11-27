//
//  HGPhotoItem.h
//  HGPhotoBrowser
//
//  Created by 黄纲 on 2019/11/15.
//

#import <UIKit/UIKit.h>
#import <Photos/PHAsset.h>

NS_ASSUME_NONNULL_BEGIN

@interface HGPhotoItem : NSObject
/**点击的View */
@property (nonatomic, strong, readonly) UIView *sourceView;
/**图片下载完成前的略缩图 */
@property (nonatomic, strong, readonly) UIImage *thumbImage;
/**本地图片 */
@property (nonatomic, strong) UIImage *image;
/**PhotoURl */
@property (nonatomic, strong, readonly) NSURL *imageUrl;
/**PhotoAsset */
@property (nonatomic, strong, readonly) PHAsset *imageAsset;
/**图片本地路径 */
@property (nonatomic, strong, readonly) NSString *imagePath;

/**VideoAsset */
@property (nonatomic, strong, readonly) PHAsset *videoAsset;
/**VideoUrl */
@property (nonatomic, strong, readonly) NSURL *videoUrl;
/**videoImage */
@property (nonatomic, strong, readonly) UIImage *videoImage;
/**video本地路径 */
@property (nonatomic, strong, readonly) NSString *videoPath;


/**是否加载完成 */
@property (nonatomic, assign) BOOL finished;
/**是否为展示图片 */
@property (nonatomic, assign, readonly) BOOL isImageShower;

/** 初始化PhotoItem(图片URL初始化)
@param view 当前图片View
@param image 原图（含原图则url无效）
@param thumbImage 略缩图
@param url 图片url
 */
- (instancetype)initWithSourceView:(nullable UIView *)view
                             image:(nullable UIImage *)image
                        thumbImage:(nullable UIImage *)thumbImage
                          imageUrl:(nullable NSURL *)url;

/** 初始化PhotoItem(图片PhAsset初始化)
@param view 当前图片View
@param imageAsset 图片PHAsset
*/
- (instancetype)initWithSourceView:(nullable UIView *)view
                        imageAsset:(nullable PHAsset *)imageAsset;

/** 初始化PhotoItem(图片路径初始化)
@param view 当前图片View
@param imagePath 图片路径
*/
- (instancetype)initWithSourceView:(nullable UIView *)view
                         imagePath:(nullable NSString *)imagePath;

/** 初始化PhotoItem(视频PhAsset初始化)
@param view 当前图片View
@param videoAsset 视频PHAsset
@param videoImage 视频图片（可传可不传，不传则从asset获取）
*/
- (instancetype)initWithSourceView:(nullable UIView *)view
                        videoAsset:(nullable PHAsset *)videoAsset
                        videoImage:(nullable UIImage *)videoImage;

/** 初始化PhotoItem(视频URL初始化)
@param view 当前图片View
@param videoImage 视频图片
@param videoUrl 视频播放地址
*/
- (instancetype)initWithSourceView:(nullable UIView *)view
                        videoImage:(nullable UIImage *)videoImage
                          videoUrl:(nullable NSURL *)videoUrl;

/** 初始化PhotoItem(视频路径初始化)
@param view 当前图片View
@param videoImage 视频图片
@param videoPath 视频路径
*/
- (instancetype)initWithSourceView:(nullable UIView *)view
                        videoImage:(nullable UIImage *)videoImage
                         videoPath:(nullable NSString *)videoPath;

/** 重设视频图片
@param videoImage 视频图片
*/
- (void)resetVideoImage:(UIImage *)videoImage;
@end

NS_ASSUME_NONNULL_END

