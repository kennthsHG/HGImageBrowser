//
//  HGVideoSavingView.h
//  HGImageBrowser
//
//  Created by 黄纲 on 2019/11/22.
//

#import <UIKit/UIKit.h>
#import "HGPhotoItem.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM (NSInteger, HGVideoSavingState) {
    HGVideoSavingState_Saving,
    HGVideoSavingState_Success,
    HGVideoSavingState_Fail,
};

@interface HGVideoSavingView : UIView

@property (nonatomic, assign) HGVideoSavingState state;
@property (nonatomic, assign) CGFloat progress;
@property (nonatomic, strong) HGPhotoItem *item;
@property (nonatomic, assign) NSUInteger downloadIndex;

- (void)showToSave;
- (void)hide;

NS_ASSUME_NONNULL_END

@end
