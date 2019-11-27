//
//  HGImageBrowserMacro.h
//  Pods
//
//  Created by 黄纲 on 2019/11/18.
//

#ifndef HGImageBrowserMacro_h
#define HGImageBrowserMacro_h

#define WS(weakSelf)  __weak __typeof(&*self)weakSelf = self;

#define isIPhoneX \
({BOOL isPhoneX = NO;\
if (@available(iOS 11.0, *)) {\
isPhoneX = [[UIApplication sharedApplication] delegate].window.safeAreaInsets.bottom > 0.0;\
}\
(isPhoneX);})

#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height
#define SafeAreaTopHeight (isIPhoneX ? 88 : 64)
#define SafeAreaBottomHeight (isIPhoneX ? 34 : 0)
#define SafeAreaStatusBarHeight (isIPhoneX ? 44 : 20)
#define IOS11TopHeight isIPhoneX ? 33.f : 0.f

#define RGBA(r,g,b,a) [UIColor colorWithRed:r/255.0f green:g/255.0f blue:b/255.0f alpha:a]

#define kHGPhotoViewHGadding 10.0
#define kHGPhotoViewMaxScale 3.0

#define HGVideoViewHideenBottomViewNotifiCation @"HGVideoViewHideenBottomViewNotifiCation"
#endif /* HGImageBrowserMacro_h */
