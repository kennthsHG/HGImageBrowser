//
//  HGPhotoBrowser.m
//  HGPhotoBrowser
//
//  Created by gang on 2017/11/30.
//  Copyright © 2016 DaShang. All rights reserved.
//

#import "HGPhotoBrowser.h"
#import "HGPhotoView.h"
#import "HGSDImageManager.h"
#import "UIImage+UIImage_BlurDark.h"
#import "HGVideoSavingView.h"

static const NSTimeInterval kAnimationDuration = 0.3;
static const NSTimeInterval HGpringAnimationDuration = 0.5;
static Class imageManagerClass = nil;

@interface HGPhotoBrowser () <UIScrollViewDelegate, UIViewControllerTransitioningDelegate, CAAnimationDelegate,UIActionSheetDelegate,UIAlertViewDelegate> {
    CGPoint _startLocation;
}

@property(nonatomic, assign) BOOL bounces;
@property(nonatomic, strong) UIScrollView *scrollView;
@property(nonatomic, strong) NSMutableArray *photoItems;
@property(nonatomic, strong) NSMutableSet *reusableItemViews;

@property(nonatomic, strong) NSMutableArray *visibleItemViews;
@property(nonatomic, assign) NSUInteger lastPage;
@property(nonatomic, assign) NSUInteger currentPage;
@property(nonatomic, strong) UIImageView *backgroundView;

@property(nonatomic, strong) UIButton *leftBigBackBtn;
@property(nonatomic, strong) UIButton *rightBigMoreBtn;
@property(nonatomic, strong) UIButton *rightBigDeleteBtn;

@property(nonatomic, strong) UIButton *leftBackBtn; //返回按钮
@property(nonatomic, strong) UIButton *rightMoreBtn; //更多选择按钮
@property(nonatomic, strong) UILabel *pageLabel; //当前页

@property(nonatomic, strong) UIView *titleNavView;
@property(nonatomic, assign) BOOL presented;
@property(nonatomic, strong) id<HGImageManager> imageManager;

@property (nonatomic, strong) HGVideoSavingView *savingView;

@property (nonatomic, strong) UIView *customView;
@end

@implementation HGPhotoBrowser

// MAKR: - Initializer
+ (instancetype)browserWithPhotoItems:(NSArray<HGPhotoItem *> *)photoItems selectedIndex:(NSUInteger)selectedIndex {
    HGPhotoBrowser *browser = [[HGPhotoBrowser alloc] initWithPhotoItems:photoItems selectedIndex:selectedIndex];
    
    return browser;
}

- (instancetype)init {
    NSAssert(NO, @"Use initWithMediaItems: instead.");
    return nil;
}

- (instancetype)initWithPhotoItems:(NSArray<HGPhotoItem *> *)photoItems selectedIndex:(NSUInteger)selectedIndex{
    self = [super init];
    if (self) {
        self.modalPresentationStyle = UIModalPresentationCustom;
        self.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        
        self.photoItems = [NSMutableArray arrayWithArray:photoItems];
        _currentPage = selectedIndex;

        _dismissalStyle = HGPhotoBrowserInteractiveDismissalStyleScale;
        _backgroundStyle = HGPhotoBrowserBackgroundStyleBlack;
        _loadingStyle = HGPhotoBrowserImageLoadingStyleIndeterminate;
        _showLongTapToSave = YES;
        _showRightButtonToSave = YES;
        _tapToLeave = YES;
        _reusableItemViews = [[NSMutableSet alloc] init];
        _visibleItemViews = [[NSMutableArray alloc] init];
        
        if (imageManagerClass == nil) {
            imageManagerClass = HGSDImageManager.class;
        }
        _imageManager = [[imageManagerClass alloc] init];
        
        [[NSNotificationCenter defaultCenter]
        addObserver:self selector:@selector(getHGVideoViewHideenBottomViewNotifiCationAction:) name:HGVideoViewHideenBottomViewNotifiCation object:nil];
    }
    return self;
}

// MARK: - Life Cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor clearColor];
    
    self.backgroundView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    self.backgroundView.contentMode = UIViewContentModeScaleAspectFill;
    self.backgroundView.alpha = 0;
    [self.view addSubview:self.backgroundView];
    
    CGRect rect = self.view.bounds;
//    rect.origin.x -= kHGPhotoViewHGadding;
//    rect.size.width += 2 * kHGPhotoViewHGadding;
    _scrollView = [[UIScrollView alloc] initWithFrame:rect];
    _scrollView.pagingEnabled = YES;
    _scrollView.showsHorizontalScrollIndicator = NO;
    _scrollView.delegate = self;
    [self.view addSubview:_scrollView];
    
    _titleNavView = [[UIView alloc]initWithFrame:CGRectMake(0, IOS11TopHeight, self.view.bounds.size.width, 44)];
    [_titleNavView setBackgroundColor:[UIColor colorWithRed:0.f/255.f green:0.f/255.f blue:0.f/255.f alpha:.6f]];
    [self.view addSubview:_titleNavView];
    
    [self initTitleNavView];
    
    CGSize contentSize = CGSizeMake(rect.size.width * _photoItems.count, rect.size.height);
    _scrollView.contentSize = contentSize;
    
    [self addGestureRecognizer];
    
    CGPoint contentOffset = CGPointMake(_scrollView.frame.size.width*_currentPage, 0);
    [_scrollView setContentOffset:contentOffset animated:NO];
    if (contentOffset.x == 0) {
        [self scrollViewDidScroll:_scrollView];
    }
}

- (void)initTitleNavView{
    [self.titleNavView addSubview:self.pageLabel];
    [self.titleNavView addSubview:self.leftBigBackBtn];
    [self.titleNavView addSubview:self.leftBackBtn];
    if (self.showRightButtonToSave) {
        [self.titleNavView addSubview:self.rightBigMoreBtn];
        [self.titleNavView addSubview:self.rightMoreBtn];
    }
    [self.titleNavView setBackgroundColor:[UIColor clearColor]];
    [self.titleNavView setAlpha:1.f];
    
    [self configPageLabelWithPage:_currentPage];
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    HGPhotoItem *item = [_photoItems objectAtIndex:_currentPage];
    HGPhotoView *photoView = [self photoViewForPage:_currentPage];
    [self resetCustomView];
    if ([_imageManager imageFromMemoryForURL:item.imageUrl]) {
        [self configPhotoView:photoView withItem:item];
    } else {
        if (item.thumbImage) {
            photoView.imageView.image = item.thumbImage;
           [photoView resizeImageView];
        }
        if (item.image) {
            photoView.imageView.image = item.image;
            [photoView resizeImageView];
        }
    }
    
    CGRect endRect = photoView.imageView.frame;
    CGRect sourceRect;
    float systemVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
    if (systemVersion >= 8.0 && systemVersion < 9.0) {
        sourceRect = [item.sourceView.superview convertRect:item.sourceView.frame toCoordinateSpace:photoView];
    } else {
        sourceRect = [item.sourceView.superview convertRect:item.sourceView.frame toView:photoView];
    }
    photoView.imageView.frame = sourceRect;
    
    if (_backgroundStyle == HGPhotoBrowserBackgroundStyleBlur) {
        [self blurBackgroundWithImage:[self screenshot] animated:NO];
    } else if (_backgroundStyle == HGPhotoBrowserBackgroundStyleBlurPhoto) {
        [self blurBackgroundWithImage:item.thumbImage animated:NO];
    }
    if (_bounces) {
        [UIView animateWithDuration:HGpringAnimationDuration delay:0 usingSpringWithDamping:0.6 initialSpringVelocity:0 options:kNilOptions animations:^{
            photoView.imageView.frame = endRect;
            self.view.backgroundColor = [UIColor blackColor];
            self.backgroundView.alpha = 1;
        } completion:^(BOOL finished) {
            [self configPhotoView:photoView withItem:item];
            self.presented = YES;
            [self setStatusBarHidden:YES];
        }];
    } else {
        [UIView animateWithDuration:kAnimationDuration animations:^{
            photoView.imageView.frame = endRect;
            self.view.backgroundColor = [UIColor blackColor];
            self.backgroundView.alpha = 1;
        } completion:^(BOOL finished) {
            [self configPhotoView:photoView withItem:item];
            self.presented = YES;
            [self setStatusBarHidden:YES];
        }];
    }
}

- (void)dealloc {
    NSLog(@"%s",__func__);
    [_photoItems removeAllObjects];
    _photoItems = nil;
    [_visibleItemViews removeAllObjects];
    _visibleItemViews = nil;
    _scrollView = nil;
    [_titleNavView removeFromSuperview];
    _titleNavView = nil;
}

// MARK: - Public
- (void)savePhoto{
    HGPhotoView *photoView = [self photoViewForPage:_currentPage];
    photoView.item.image = photoView.imageView.image;
    self.savingView.item = photoView.item;
    [self.savingView showToSave];
}

- (void)backBtnSelect{
    [self showDismissalAnimation];
}

- (void)rightMoreBtnSelect{
    [self moreAction];
}

- (void)moreAction{
    UIActionSheet * sheet = [[UIActionSheet alloc]initWithTitle:nil delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles:@"保存到系统相册", nil];
    [sheet showInView:self.view];
}

- (void)showFromViewController:(UIViewController *)vc {
    [vc presentViewController:self animated:NO completion:nil];
}

// MARK: - Private
- (void)getHGVideoViewHideenBottomViewNotifiCationAction:(NSNotification *)notification{
    NSNumber *showStatus = [notification object];
    self.titleNavView.hidden = [showStatus boolValue];
}

- (void)setStatusBarHidden:(BOOL)hidden {
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    if (hidden) {
        window.windowLevel = UIWindowLevelStatusBar + 1;
    } else {
        window.windowLevel = UIWindowLevelNormal;
    }
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (HGPhotoView *)photoViewForPage:(NSUInteger)page {
    for (HGPhotoView *photoView in _visibleItemViews) {
        if (photoView.tag == page) {
            return photoView;
        }
    }
    return nil;
}

- (HGPhotoView *)dequeueReusableItemView {
    HGPhotoView *photoView = [_reusableItemViews anyObject];
    if (photoView == nil) {
        photoView = [[HGPhotoView alloc] initWithFrame:_scrollView.bounds imageManager:_imageManager];
    } else {
        [_reusableItemViews removeObject:photoView];
    }
    photoView.tag = -1;
    return photoView;
}

- (void)updateReusableItemViews {
    NSMutableArray *itemsForRemove = @[].mutableCopy;
    for (HGPhotoView *photoView in _visibleItemViews) {
        if (photoView.frame.origin.x + photoView.frame.size.width < _scrollView.contentOffset.x - _scrollView.frame.size.width ||
            photoView.frame.origin.x > _scrollView.contentOffset.x + 2 * _scrollView.frame.size.width) {
            [photoView removeFromSuperview];
            [self configPhotoView:photoView withItem:nil];
            [itemsForRemove addObject:photoView];
            [_reusableItemViews addObject:photoView];
        }
    }
    [_visibleItemViews removeObjectsInArray:itemsForRemove];
}

- (void)configItemViews {
    NSInteger page = _scrollView.contentOffset.x / _scrollView.frame.size.width + 0.5;
    for (NSInteger i = page - 1; i <= page + 1; i++) {
        if (i < 0 || i >= _photoItems.count) {
            continue;
        }
        HGPhotoView *photoView = [self photoViewForPage:i];
        if (photoView == nil) {
            photoView = [self dequeueReusableItemView];
            CGRect rect = _scrollView.bounds;
            rect.origin.x = i * _scrollView.bounds.size.width;
            photoView.frame = rect;
            photoView.tag = i;
            [_scrollView addSubview:photoView];
            [_visibleItemViews addObject:photoView];
        }
        if (photoView.item == nil && _presented) {
            HGPhotoItem *item = [_photoItems objectAtIndex:i];
            [self configPhotoView:photoView withItem:item];
        }
    }
    
    if (page != _currentPage && _presented && (page >= 0 && page < _photoItems.count)) {
        HGPhotoItem *item = [_photoItems objectAtIndex:page];
        if (_backgroundStyle == HGPhotoBrowserBackgroundStyleBlurPhoto) {
            [self blurBackgroundWithImage:item.thumbImage animated:YES];
        }
        _lastPage = _currentPage;
        _currentPage = page;
        
        [self configPageLabelWithPage:_currentPage];
    }
}

- (void)dismissAnimated:(BOOL)animated {
    for (HGPhotoView *photoView in _visibleItemViews) {
        [photoView cancelCurrentImageLoad];
    }
    HGPhotoItem *item = [_photoItems objectAtIndex:_currentPage];
    if (animated) {
        [UIView animateWithDuration:kAnimationDuration animations:^{
            item.sourceView.alpha = 1;
        }];
    } else {
        item.sourceView.alpha = 1;
    }
    [self dismissViewControllerAnimated:NO completion:nil];
}

- (void)performRotationWithPan:(UIPanGestureRecognizer *)pan {
    CGPoint point = [pan translationInView:self.view];
    CGPoint location = [pan locationInView:self.view];
    CGPoint velocity = [pan velocityInView:self.view];
    HGPhotoView *photoView = [self photoViewForPage:_currentPage];
    switch (pan.state) {
        case UIGestureRecognizerStateBegan:
            _startLocation = location;
            [self handlePanBegin];
            break;
        case UIGestureRecognizerStateChanged: {
            CGFloat angle = 0;
            if (_startLocation.x < self.view.frame.size.width/2) {
                angle = -(M_PI / 2) * (point.y / self.view.frame.size.height);
            } else {
                angle = (M_PI / 2) * (point.y / self.view.frame.size.height);
            }
            CGAffineTransform rotation = CGAffineTransformMakeRotation(angle);
            CGAffineTransform translation = CGAffineTransformMakeTranslation(0, point.y);
            CGAffineTransform transform = CGAffineTransformConcat(rotation, translation);
            photoView.item.isImageShower ? (photoView.imageView.transform = transform) : (photoView.videoView.playerView.transform = transform);
            
            double percent = 1 - fabs(point.y)/(self.view.frame.size.height/2);
            self.view.backgroundColor = [UIColor colorWithWhite:0 alpha:percent];
            self.backgroundView.alpha = percent;
            [photoView.videoView bottomViewShowStatus:YES];
            self.titleNavView.hidden = YES;
            self.customView.hidden = YES;
        }
            break;
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled: {
            if (fabs(point.y) > 200 || fabs(velocity.y) > 500) {
                [self showRotationCompletionAnimationFromPoint:point];
            } else {
                [self showCancellationAnimation];
                [photoView.videoView bottomViewShowStatus:NO];
                self.titleNavView.hidden = NO;
                self.customView.hidden = NO;
            }
        }
            break;
            
        default:
            break;
    }
}

- (void)performScaleWithPan:(UIPanGestureRecognizer *)pan {
    CGPoint point = [pan translationInView:self.view];
    CGPoint location = [pan locationInView:self.view];
    CGPoint velocity = [pan velocityInView:self.view];
    HGPhotoView *photoView = [self photoViewForPage:_currentPage];
    switch (pan.state) {
        case UIGestureRecognizerStateBegan:
            _startLocation = location;
            [self handlePanBegin];
            break;
        case UIGestureRecognizerStateChanged: {
            double percent = 1 - fabs(point.y) / self.view.frame.size.height;
            percent = MAX(percent, 0);
            double s = MAX(percent, 0.5);
            CGAffineTransform translation = CGAffineTransformMakeTranslation(point.x/s, point.y/s);
            CGAffineTransform scale = CGAffineTransformMakeScale(s, s);
            photoView.item.isImageShower ? (photoView.imageView.transform = CGAffineTransformConcat(translation, scale)) : (photoView.videoView.playerView.transform = CGAffineTransformConcat(translation, scale));
            self.view.backgroundColor = [UIColor colorWithWhite:0 alpha:percent];
            self.backgroundView.alpha = percent;
            [photoView.videoView bottomViewShowStatus:YES];
            self.titleNavView.hidden = YES;
            self.customView.hidden = YES;
        }
            break;
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled: {
            if (fabs(point.y) > 100 || fabs(velocity.y) > 500) {
                [self showDismissalAnimation];
                [photoView.videoView bottomViewShowStatus:YES];
                self.titleNavView.hidden = YES;
                self.customView.hidden = YES;
            } else {
                [self showCancellationAnimation];
                [photoView.videoView bottomViewShowStatus:NO];
                self.titleNavView.hidden = NO;
                self.customView.hidden = NO;
            }
        }
            break;
            
        default:
            break;
    }
}

- (void)performSlideWithPan:(UIPanGestureRecognizer *)pan {
    CGPoint point = [pan translationInView:self.view];
    CGPoint location = [pan locationInView:self.view];
    CGPoint velocity = [pan velocityInView:self.view];
    HGPhotoView *photoView = [self photoViewForPage:_currentPage];
    switch (pan.state) {
        case UIGestureRecognizerStateBegan:
            _startLocation = location;
            [self handlePanBegin];
            break;
        case UIGestureRecognizerStateChanged: {
            photoView.item.isImageShower ? (photoView.imageView.transform = CGAffineTransformMakeTranslation(0, point.y)) : (photoView.videoView.playerView.transform = CGAffineTransformMakeTranslation(0, point.y));
            double percent = 1 - fabs(point.y)/(self.view.frame.size.height/2);
            self.view.backgroundColor = [UIColor colorWithWhite:0 alpha:percent];
            self.backgroundView.alpha = percent;
            [photoView.videoView bottomViewShowStatus:YES];
            self.titleNavView.hidden = YES;
            self.customView.hidden = YES;
        }
            break;
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled: {
            if (fabs(point.y) > 200 || fabs(velocity.y) > 500) {
                [self showSlideCompletionAnimationFromPoint:point];
            } else {
                [self showCancellationAnimation];
                [photoView.videoView bottomViewShowStatus:NO];
                self.titleNavView.hidden = NO;
                self.customView.hidden = NO;
            }
        }
            break;
            
        default:
            break;
    }
}

- (UIImage *)screenshot {
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    UIGraphicsBeginImageContextWithOptions(window.bounds.size, YES, [UIScreen mainScreen].scale);
    [window.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (void)blurBackgroundWithImage:(UIImage *)image animated:(BOOL)animated {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        UIImage *blurImage = [image hg_imageByBlurDark];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (animated) {
                [UIView animateWithDuration:kAnimationDuration animations:^{
                    self.backgroundView.alpha = 0;
                } completion:^(BOOL finished) {
                    self.backgroundView.image = blurImage;
                    [UIView animateWithDuration:kAnimationDuration animations:^{
                        self.backgroundView.alpha = 1;
                    } completion:nil];
                }];
            } else {
                self.backgroundView.image = blurImage;
            }
        });
    });
}

- (void)configPhotoView:(HGPhotoView *)photoView withItem:(HGPhotoItem *)item {
    [photoView setItem:item determinate:(_loadingStyle == HGPhotoBrowserImageLoadingStyleDeterminate)];
}

- (void)configPageLabelWithPage:(NSUInteger)page {
    _pageLabel.text = [NSString stringWithFormat:@"%lu / %lu", page+1, _photoItems.count];
}

- (void)handlePanBegin {
    HGPhotoView *photoView = [self photoViewForPage:_currentPage];
    [photoView cancelCurrentImageLoad];
    HGPhotoItem *item = [_photoItems objectAtIndex:_currentPage];
    [self setStatusBarHidden:NO];
    photoView.progressLayer.hidden = YES;
    item.sourceView.alpha = 0;
}

// MARK: - Gesture Recognizer

- (void)addGestureRecognizer {
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didDoubleTap:)];
    doubleTap.numberOfTapsRequired = 2;
    [self.view addGestureRecognizer:doubleTap];
    
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didSingleTap:)];
    singleTap.numberOfTapsRequired = 1;
    [singleTap requireGestureRecognizerToFail:doubleTap];
    [self.view addGestureRecognizer:singleTap];
    
    if (self.showLongTapToSave) {
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(didLongPress:)];
        [self.view addGestureRecognizer:longPress];
    }

    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(didPan:)];
    [self.view addGestureRecognizer:pan];
}

- (void)didSingleTap:(UITapGestureRecognizer *)tap {
    HGPhotoView *photoView = [self photoViewForPage:_currentPage];
    if (!photoView.item.isImageShower) {
        photoView.videoView.playButtonShowStatus = !photoView.videoView.playButtonShowStatus;
        [self hideNavTitleAndBottmCustom:photoView.videoView.playButtonShowStatus];
        [photoView.videoView playButtonShowStatus:[NSNumber numberWithBool:photoView.videoView.playButtonShowStatus]];
        return;
    }
    if (!_tapToLeave || self.customView) {
        [self hideNavTitleAndBottmCustom:self.titleNavView.alpha == 1];
    }
    else{
        [self showDismissalAnimation];
    }
}

- (void)hideNavTitleAndBottmCustom:(BOOL)hidden{
    if (!hidden) {
        [UIView animateKeyframesWithDuration:.2f delay:0.f options:UIViewKeyframeAnimationOptionBeginFromCurrentState animations:^{
            [self.titleNavView setFrame:CGRectMake(0, IOS11TopHeight, self.view.bounds.size.width, 44.f)];
            self.titleNavView.alpha = 1.f;
             [self.customView setFrame:CGRectMake(self.customView.frame.origin.x, SCREEN_HEIGHT - self.customView.frame.size.height, self.customView.frame.size.width, self.customView.frame.size.height)];
        } completion:^(BOOL finished) {
            self.customView.hidden = !self.customView.hidden;
        }];
    }
    else{
        [UIView animateKeyframesWithDuration:.2f delay:0.f options:UIViewKeyframeAnimationOptionBeginFromCurrentState animations:^{
            [self.titleNavView setFrame:CGRectMake(0, -44, self.view.bounds.size.width, 44.f)];
            [self.customView setFrame:CGRectMake(self.customView.frame.origin.x, self.customView.frame.origin.y + self.customView.frame.size.height, self.customView.frame.size.width, self.customView.frame.size.height)];
        } completion:^(BOOL finished) {
            self.titleNavView.alpha = 0.f;
            self.customView.hidden = !self.customView.hidden;
        }];
    }
}

- (void)didDoubleTap:(UITapGestureRecognizer *)tap {
    HGPhotoView *photoView = [self photoViewForPage:_currentPage];
    HGPhotoItem *item = [_photoItems objectAtIndex:_currentPage];
    if (!item.finished) {
        return;
    }
    if (photoView.zoomScale > 1) {
        [photoView setZoomScale:1 animated:YES];
    } else {
        CGPoint location = [tap locationInView:self.view];
        CGFloat maxZoomScale = photoView.maximumZoomScale;
        CGFloat width = self.view.bounds.size.width / maxZoomScale;
        CGFloat height = self.view.bounds.size.height / maxZoomScale;
        [photoView zoomToRect:CGRectMake(location.x - width/2, location.y - height/2, width, height) animated:YES];
    }
}

- (void)didLongPress:(UILongPressGestureRecognizer *)longPress {
    if (longPress.state != UIGestureRecognizerStateBegan) {
        return;
    }
    HGPhotoView *photoView = [self photoViewForPage:_currentPage];
//    UIImage *image = photoView.imageView.image;
//    if (!image) {
//        return;
//    }
    
    [self moreAction];
    
}

- (void)didPan:(UIPanGestureRecognizer *)pan {
    HGPhotoView *photoView = [self photoViewForPage:_currentPage];
    if (photoView.zoomScale > 1.1) {
        return;
    }
    
    switch (_dismissalStyle) {
        case HGPhotoBrowserInteractiveDismissalStyleRotation:
            [self performRotationWithPan:pan];
            break;
        case HGPhotoBrowserInteractiveDismissalStyleScale:
            [self performScaleWithPan:pan];
            break;
        case HGPhotoBrowserInteractiveDismissalStyleSlide:
            [self performSlideWithPan:pan];
            break;
        default:
            break;
    }
}

// MARK: - Animation
- (void)showCancellationAnimation {
    HGPhotoView *photoView = [self photoViewForPage:_currentPage];
    HGPhotoItem *item = [_photoItems objectAtIndex:_currentPage];
    item.sourceView.alpha = 1;
    if (item.isImageShower) {
        if (!photoView.item.finished) {
             photoView.progressLayer.hidden = NO;
         }
    }
    else{
        if (!photoView.videoView.item.finished) {
             photoView.progressLayer.hidden = NO;
         }
    }
 
    if (_bounces && _dismissalStyle == HGPhotoBrowserInteractiveDismissalStyleScale) {
        [UIView animateWithDuration:HGpringAnimationDuration delay:0 usingSpringWithDamping:0.6 initialSpringVelocity:0 options:kNilOptions animations:^{
            photoView.imageView.transform = CGAffineTransformIdentity;
            photoView.videoView.playerView.transform = CGAffineTransformIdentity;
            self.view.backgroundColor = [UIColor blackColor];
            self.backgroundView.alpha = 1;
        } completion:^(BOOL finished) {
            [self setStatusBarHidden:YES];
            if (photoView.item.isImageShower) {
                [self configPhotoView:photoView withItem:item];
            }
            
        }];
    } else {
        [UIView animateWithDuration:kAnimationDuration animations:^{
            photoView.imageView.transform = CGAffineTransformIdentity;
            photoView.videoView.playerView.transform = CGAffineTransformIdentity;
            self.view.backgroundColor = [UIColor blackColor];
            self.backgroundView.alpha = 1;
        } completion:^(BOOL finished) {
            [self setStatusBarHidden:YES];
            if (photoView.item.isImageShower) {
                [self configPhotoView:photoView withItem:item];
            }
        }];
    }
}

- (void)showRotationCompletionAnimationFromPoint:(CGPoint)point {
    HGPhotoView *photoView = [self photoViewForPage:_currentPage];
    BOOL startFromLeft = _startLocation.x < self.view.frame.size.width / 2;
    BOOL throwToTop = point.y < 0;
    CGFloat angle, toTranslationY;
    if (throwToTop) {
        angle = startFromLeft ? (M_PI / 2) : -(M_PI / 2);
        toTranslationY = -self.view.frame.size.height;
    } else {
        angle = startFromLeft ? -(M_PI / 2) : (M_PI / 2);
        toTranslationY = self.view.frame.size.height;
    }
    
    CGFloat angle0 = 0;
    if (_startLocation.x < self.view.frame.size.width/2) {
        angle0 = -(M_PI / 2) * (point.y / self.view.frame.size.height);
    } else {
        angle0 = (M_PI / 2) * (point.y / self.view.frame.size.height);
    }
    
    CABasicAnimation *rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotationAnimation.fromValue = @(angle0);
    rotationAnimation.toValue = @(angle);
    CABasicAnimation *translationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.translation.y"];
    translationAnimation.fromValue = @(point.y);
    translationAnimation.toValue = @(toTranslationY);
    CAAnimationGroup *throwAnimation = [CAAnimationGroup animation];
    throwAnimation.duration = kAnimationDuration;
    throwAnimation.delegate = self;
    throwAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    throwAnimation.animations = @[rotationAnimation, translationAnimation];
    [throwAnimation setValue:@"throwAnimation" forKey:@"id"];
    photoView.item.isImageShower ? [photoView.imageView.layer addAnimation:throwAnimation forKey:@"throwAnimation"] : [photoView.videoView.playerView.layer addAnimation:throwAnimation forKey:@"throwAnimation"];
    
    CGAffineTransform rotation = CGAffineTransformMakeRotation(angle);
    CGAffineTransform translation = CGAffineTransformMakeTranslation(0, toTranslationY);
    CGAffineTransform transform = CGAffineTransformConcat(rotation, translation);
    photoView.item.isImageShower ? (photoView.imageView.transform = transform) : (photoView.videoView.playerView.transform = transform);
    
    
    [UIView animateWithDuration:kAnimationDuration animations:^{
        self.view.backgroundColor = [UIColor clearColor];
        self.backgroundView.alpha = 0;
    } completion:nil];
}

- (void)showDismissalAnimation {
    
    HGPhotoItem *item = [_photoItems objectAtIndex:_currentPage];
    HGPhotoView *photoView = [self photoViewForPage:_currentPage];
    [photoView cancelCurrentImageLoad];
    [self setStatusBarHidden:NO];
    
    if (item.sourceView == nil) {
        [UIView animateWithDuration:kAnimationDuration animations:^{
            self.view.alpha = 0;
        } completion:^(BOOL finished) {
            [self dismissAnimated:NO];
        }];
        return;
    }
    
    photoView.progressLayer.hidden = YES;
    item.sourceView.alpha = 0;
    CGRect sourceRect;
    float systemVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
    if (systemVersion >= 8.0 && systemVersion < 9.0) {
        sourceRect = [item.sourceView.superview convertRect:item.sourceView.frame toCoordinateSpace:photoView];
    } else {
        sourceRect = [item.sourceView.superview convertRect:item.sourceView.frame toView:photoView];
    }
    if (_bounces) {
        [UIView animateWithDuration:HGpringAnimationDuration delay:0 usingSpringWithDamping:0.6 initialSpringVelocity:0 options:kNilOptions animations:^{
            photoView.imageView.frame = sourceRect;
            photoView.videoView.playerView.frame = sourceRect;
            self.view.backgroundColor = [UIColor clearColor];
            self.backgroundView.alpha = 0;
        } completion:^(BOOL finished) {
            [self dismissAnimated:NO];
        }];
    } else {
        [UIView animateWithDuration:kAnimationDuration animations:^{
            photoView.imageView.frame = sourceRect;
            photoView.videoView.playerView.frame = sourceRect;
            self.view.backgroundColor = [UIColor clearColor];
            self.backgroundView.alpha = 0;
        } completion:^(BOOL finished) {
            [self dismissAnimated:NO];
        }];
    }
    [UIView animateKeyframesWithDuration:.5f delay:0.f options:UIViewKeyframeAnimationOptionOverrideInheritedOptions animations:^{
        [self.titleNavView setFrame:CGRectMake(0, -44, self.view.bounds.size.width, 44.f)];
        self.titleNavView.alpha = 0.f;
        
    } completion:^(BOOL finished) {
        [self.titleNavView removeFromSuperview];
    }];
}

- (void)showSlideCompletionAnimationFromPoint:(CGPoint)point {
    HGPhotoView *photoView = [self photoViewForPage:_currentPage];
    BOOL throwToTop = point.y < 0;
    CGFloat toTranslationY = 0;
    if (throwToTop) {
        toTranslationY = -self.view.frame.size.height;
    } else {
        toTranslationY = self.view.frame.size.height;
    }
    [UIView animateWithDuration:kAnimationDuration animations:^{
        photoView.imageView.transform = CGAffineTransformMakeTranslation(0, toTranslationY);
        self.view.backgroundColor = [UIColor clearColor];
        self.backgroundView.alpha = 0;
    } completion:^(BOOL finished) {
        [self dismissAnimated:YES];
    }];
}

// MARK: - Animation Delegate
- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
    if ([[anim valueForKey:@"id"] isEqualToString:@"throwAnimation"]) {
        [self dismissAnimated:YES];
    }
}

// MARK: - ScrollView Delegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self updateReusableItemViews];
    [self configItemViews];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    if (_lastPage ==_currentPage) {
        return;
    }
    HGPhotoView *lastphotoView = [self photoViewForPage:_lastPage];
    [lastphotoView.videoView playerStopPlaying];
    
    HGPhotoView *currentphotoView = [self photoViewForPage:_currentPage];

    if (self.delegate && [self.delegate respondsToSelector:@selector(photoBrowserDidScrollToIndex:currentPhotoView:)]) {
        [self.delegate photoBrowserDidScrollToIndex:_currentPage currentPhotoView:currentphotoView];
    }
    
    [self resetCustomView];
}

- (void)resetCustomView{
    [self.customView removeFromSuperview];
       
    if (self.delegate && [self.delegate respondsToSelector:@selector(photoBrowsertheIndexShowView:)]) {
        self.customView = [self.delegate photoBrowsertheIndexShowView:_currentPage];
        self.customView.hidden = self.titleNavView.alpha == 0;
        [self.view addSubview:self.customView];
        [self.view bringSubviewToFront:self.customView];
    }
}

#pragma mark - UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
   if (buttonIndex == 0) {
       [self savePhoto];
   }
}

#pragma mark - Getters
- (UILabel*)pageLabel{
    if (_pageLabel == nil) {
        _pageLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 250, 20)];
        _pageLabel.center = CGPointMake(self.titleNavView.center.x, self.titleNavView.center.y);
        _pageLabel.textColor = [UIColor whiteColor];
        _pageLabel.font = [UIFont systemFontOfSize:17];
        _pageLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _pageLabel;
}

- (UIButton*)leftBigBackBtn{
    if (_leftBigBackBtn == nil) {
        _leftBigBackBtn = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, 50, 44)];
        _leftBigBackBtn.center = CGPointMake(_leftBigBackBtn.center.x, self.titleNavView.center.y);
        [_leftBigBackBtn addTarget:self action:@selector(backBtnSelect) forControlEvents:UIControlEventTouchUpInside];
    }
    return _leftBigBackBtn;
}


- (UIButton *)leftBackBtn{
    if (_leftBackBtn == nil) {
        UIImage *image = [UIImage hg_ImageNamedFromMyBundle:@"tap_icon_back"];
        _leftBackBtn = [[UIButton alloc]initWithFrame:CGRectMake(10.5f, 0, 10, 17.5f)];
        _leftBackBtn.center = CGPointMake(_leftBackBtn.center.x, self.titleNavView.center.y);
        [_leftBackBtn setBackgroundImage:image forState:UIControlStateNormal];
        [_leftBackBtn addTarget:self action:@selector(backBtnSelect) forControlEvents:UIControlEventTouchUpInside];
    }
    return _leftBackBtn;
}

- (UIButton *)rightBigMoreBtn{
    if (_rightBigMoreBtn == nil) {
        _rightBigMoreBtn = [[UIButton alloc]initWithFrame:CGRectMake(self.view.bounds.size.width - 70, 0, 60, 44)];
        _rightBigMoreBtn.center = CGPointMake(_rightBigMoreBtn.center.x, self.titleNavView.center.y);
        [_rightBigMoreBtn addTarget:self action:@selector(rightMoreBtnSelect) forControlEvents:UIControlEventTouchUpInside];
    }
    return _rightBigMoreBtn;
}


- (UIButton *)rightMoreBtn{
    if (_rightMoreBtn == nil) {
        UIImage * image = [UIImage hg_ImageNamedFromMyBundle:@"nav_icon_more_operation"];
        _rightMoreBtn = [[UIButton alloc]initWithFrame:CGRectMake(self.view.bounds.size.width - 35, 0, 22, 23)];
        _rightMoreBtn.center = CGPointMake(_rightMoreBtn.center.x, self.titleNavView.center.y);
        [_rightMoreBtn setBackgroundImage:image forState:UIControlStateNormal];
        [_rightMoreBtn addTarget:self action:@selector(rightMoreBtnSelect) forControlEvents:UIControlEventTouchUpInside];
    }
    return _rightMoreBtn;
}

- (HGVideoSavingView *)savingView {
    if (!_savingView) {
        _savingView = [[HGVideoSavingView alloc] init];
    }
    return _savingView;
}

@end

