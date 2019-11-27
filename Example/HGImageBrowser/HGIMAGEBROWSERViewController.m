//
//  HGIMAGEBROWSERViewController.m
//  HGImageBrowser
//
//  Created by 黄 纲 on 11/13/2019.
//  Copyright (c) 2019 黄 纲. All rights reserved.
//

#import "HGIMAGEBROWSERViewController.h"
#import "HGPhotoBrowser.h"
#import "TZImagePickerController.h"

@interface HGIMAGEBROWSERViewController ()<HGPhotoBrowserDelegate>
@property (strong, nonatomic) UIImageView *imageview;
@property (strong, nonatomic) PHAsset *assets;
@property (strong, nonatomic) PHAsset *videoAssets;
@property (strong, nonatomic) UIImage *videoImage;
@end

@implementation HGIMAGEBROWSERViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    
    UIButton *button = [[UIButton alloc]initWithFrame:CGRectMake(0, 400, 210, 50)];
    [button addTarget:self action:@selector(buttonAction) forControlEvents:UIControlEventTouchUpInside];
    [button setTitle:@"aaa" forState:UIControlStateNormal];
    [button setBackgroundColor:[UIColor redColor]];
    [self.view addSubview:button];
    
    UIButton *buttons = [[UIButton alloc]initWithFrame:CGRectMake(0, 500, 210, 50)];
    [buttons addTarget:self action:@selector(videobuttonAction) forControlEvents:UIControlEventTouchUpInside];
    [buttons setTitle:@"video" forState:UIControlStateNormal];
    [buttons setBackgroundColor:[UIColor redColor]];
    [self.view addSubview:buttons];
    
    
    self.imageview = [[UIImageView alloc]initWithFrame:CGRectMake(0, 200, 210, 50)];
    [self.imageview setBackgroundColor:[UIColor redColor]];
    [self.imageview setImage:[UIImage imageNamed:@"youyaoqiIcon"]];
    self.imageview.userInteractionEnabled = YES;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(selectImageView)];
    [self.imageview addGestureRecognizer:tap];
    [self.view addSubview:self.imageview];
    
   
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)buttonAction{
    TZImagePickerController *imagePickController = [[TZImagePickerController alloc] initWithMaxImagesCount:1 delegate:nil];
    [imagePickController setDidFinishPickingPhotosHandle:^(NSArray<UIImage *> *photos, NSArray *assets, BOOL isSelectOriginalPhoto) {
        self.assets = assets.firstObject;
    }];
    [imagePickController setDidFinishPickingVideoHandle:^(UIImage *coverImage, PHAsset *asset) {
        self.videoAssets = asset;
        self.videoImage = coverImage;
    }];
    [self presentViewController:imagePickController animated:YES completion:nil];
}



- (void)videobuttonAction{
    
    if (self.videoAssets) {
        HGPhotoItem *items = [[HGPhotoItem alloc]initWithSourceView:self.imageview videoAsset:self.videoAssets videoImage:self.videoImage];
        HGPhotoBrowser *browser = [HGPhotoBrowser browserWithPhotoItems:@[items] selectedIndex:0];
        [browser showFromViewController:self];
        return;
    }
    
    HGPhotoItem *items = [[HGPhotoItem alloc]initWithSourceView:self.imageview image:nil thumbImage:self.imageview.image imageUrl:[NSURL URLWithString:@"http://116.7.226.222:10001/static/material/img/inbound/267cceced7504c9cb3cafbf0b2e378a0/d9a9a281-b4ba-4977-a8f8-6e32df426fb8.png"]];
    HGPhotoItem *item = [[HGPhotoItem alloc]initWithSourceView:self.imageview
                                                    videoImage:[UIImage imageNamed:@"youyaoqiIcon"]
                                                      videoUrl:[NSURL URLWithString:@"https://vdse.bdstatic.com//f11546e6b21bb6f60f025df3d5cb5735?authorization=bce-auth-v1/fb297a5cc0fb434c971b8fa103e8dd7b/2017-05-11T09:02:31Z/-1//560f50696b0d906271532cf3868d7a3baf6e4f7ffbe74e8dff982ed57f72c088.mp4"]];
    
    NSMutableArray * array = @[].mutableCopy;
    for (int i = 0; i < 10; i++) {
        [array addObject:item];
        [array addObject:items];
    }
    HGPhotoBrowser *browser = [HGPhotoBrowser browserWithPhotoItems:[NSArray arrayWithArray:array] selectedIndex:0];
    browser.dismissalStyle = HGPhotoBrowserInteractiveDismissalStyleSlide;
    browser.backgroundStyle = HGPhotoBrowserBackgroundStyleBlur;
    browser.loadingStyle = HGPhotoBrowserImageLoadingStyleDeterminate;
    [browser showFromViewController:self];
}

- (void)selectImageView{
    
    HGPhotoItem *item;
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
       
    NSString *doucumentDir = [paths objectAtIndex:0];
       
    NSString *pathFileName = [doucumentDir stringByAppendingPathComponent:@"aaa.png"];
    
    NSString *videopathFileName = [doucumentDir stringByAppendingPathComponent:@"sss.mp4"];
    
    if (self.assets) {
        item = [[HGPhotoItem alloc]initWithSourceView:self.imageview imageAsset:self.assets];
    }
    else{
        item = [[HGPhotoItem alloc]initWithSourceView:self.imageview image:nil thumbImage:self.imageview.image imageUrl:[NSURL URLWithString:@"http://116.7.226.222:10001/static/material/img/inbound/267cceced7504c9cb3cafbf0b2e378a0/d9a9a281-b4ba-4977-a8f8-6e32df426fb8.png"]];
    }
    
    HGPhotoItem *items = [[HGPhotoItem alloc]initWithSourceView:self.imageview image:self.imageview.image thumbImage:self.imageview.image imageUrl:nil];

    HGPhotoItem *item2 = [[HGPhotoItem alloc]initWithSourceView:self.imageview imagePath:pathFileName];
    HGPhotoItem *videoitem = [[HGPhotoItem alloc]initWithSourceView:self.imageview videoImage:nil videoPath:videopathFileName];
    HGPhotoBrowser *browser = [HGPhotoBrowser browserWithPhotoItems:@[item,items,item2,videoitem] selectedIndex:0];
    browser.delegate = self;
    [browser showFromViewController:self];
}

/**
图片浏览滑动到某一页

@param index 当前页数
@param currentPhotoView 当前图片视图
*/
- (void)photoBrowserDidScrollToIndex:(NSUInteger)index
                    currentPhotoView:(HGPhotoView *)currentPhotoView{
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
