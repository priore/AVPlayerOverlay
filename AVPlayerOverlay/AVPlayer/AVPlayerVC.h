//
//  AVPlayerVC.h
//
//  Created by Danilo Priore on 28/04/16.
//  Copyright © 2016 Prioregroup.com. All rights reserved.
//
#define AVPlayerVCSetVideoURLNotification @"avplayervcsetvideourl"

#define kAVPlayerVCSubtitleURL @"subtitles"

#import "AVPlayerOverlayVC.h"

@import AVKit;

IB_DESIGNABLE
@interface AVPlayerVC : AVPlayerViewController

@property (nonatomic, strong) NSURL *videoURL;
@property (nonatomic, strong) AVPlayerOverlayVC *overlayVC;

@property (nonatomic, assign) IBInspectable BOOL videoBackground;
@property (nonatomic, strong) IBInspectable NSString *overlayStoryboardId;
@property (nonatomic, strong) IBInspectable NSString *userAgent;

- (void)playInBackground:(BOOL)play;

@end
