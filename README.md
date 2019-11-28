# HGImageBrowser

自定义图片视频展示库，可展示图片，视频，支持URL，Image，Asset，Path

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

Use CocoaPods

```ruby
pod 'HGImageBrowser'
```

## How to use it
```ruby
HGPhotoItem *imageItem = [[HGPhotoItem alloc]initWithSourceView:self.imageview image:nil thumbImage:self.imageview.image imageUrl:[NSURL URLWithString:@"http://116.7.226.222:10001/static/material/img/inbound/267cceced7504c9cb3cafbf0b2e378a0/d9a9a281-b4ba-4977-a8f8-6e32df426fb8.png"]];

HGPhotoItem *videoItem = [[HGPhotoItem alloc]initWithSourceView:self.imageview
                                                    videoImage:[UIImage imageNamed:@""]
                                                      videoUrl:[NSURL URLWithString:@"https://vdse.bdstatic.com//f11546e6b21bb6f60f025df3d5cb5735?authorization=bce-auth-v1/fb297a5cc0fb434c971b8fa103e8dd7b/2017-05-11T09:02:31Z/-1//560f50696b0d906271532cf3868d7a3baf6e4f7ffbe74e8dff982ed57f72c088.mp4"]];

HGPhotoBrowser *browser = [HGPhotoBrowser browserWithPhotoItems:@[imageItem,videoItem] selectedIndex:0];
[browser showFromViewController:self];
```
## Author

黄 纲, 362168751@qq.com

## License

HGImageBrowser is available under the MIT license. See the LICENSE file for more info.
