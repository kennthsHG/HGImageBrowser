#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "HGDownLoadManager.h"
#import "HGImageBrowserMacro.h"
#import "HGImageManager.h"
#import "HGImageManagerProtocol.h"
#import "HGPhotoBrowser.h"
#import "HGPhotoItem.h"
#import "HGPhotoView.h"
#import "HGPlayerView.h"
#import "HGProgressLayer.h"
#import "HGScrollView.h"
#import "HGSDImageManager.h"
#import "HGVideoSavingView.h"
#import "UIImage+UIImage_BlurDark.h"

FOUNDATION_EXPORT double HGImageBrowserVersionNumber;
FOUNDATION_EXPORT const unsigned char HGImageBrowserVersionString[];

