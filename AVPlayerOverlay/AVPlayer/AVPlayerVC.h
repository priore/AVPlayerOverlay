//
//  AVPlayerVC.h
//
//  Created by Danilo Priore on 28/04/16.
//  Copyright © 2016 Prioregroup.com. All rights reserved.
//
#define AVPlayerVCSetVideoURLNotification @"avplayervcsetvideourl"
#define kAVPlayerVCSubtitleURL @"subtitles"

#import "AVPlayerOverlayVC.h"
#import "AVPlayerPIPOverlayVC.h"

@import AVKit;
@import AVFoundation;

IB_DESIGNABLE
@interface AVPlayerVC : AVPlayerViewController

@property (nonatomic, strong) NSURL *videoURL;
@property (nonatomic, strong) NSURL *subtitlesURL;
@property (nonatomic, strong) AVPlayerOverlayVC *overlayVC;
@property (nonatomic, strong) AVPlayerPIPOverlayVC *pipOverlayVC;

@property (nonatomic, assign) IBInspectable BOOL videoBackground;
@property (nonatomic, strong) IBInspectable NSString *PIPStoryboardId;
@property (nonatomic, strong) IBInspectable NSString *overlayStoryboardId;
@property (nonatomic, strong) IBInspectable NSString *userAgent;

- (void)playInBackground:(BOOL)play;

@end
