//
//  AVPlayerVC.h
//
//  Created by Danilo Priore on 28/04/16.
//  Copyright © 2016 Prioregroup.com. All rights reserved.
//
#define AVPlayerVCSetVideoURLNotification @"avplayervcsetvideourl"

#import <AVKit/AVKit.h>
#import "AVPlayerOverlayVC.h"

IB_DESIGNABLE
@interface AVPlayerVC : AVPlayerViewController

@property (nonatomic, strong) NSURL *videoURL;
@property (nonatomic, strong) AVPlayerOverlayVC *overlayVC;

@property (nonatomic, assign) IBInspectable BOOL videoBackground;
@property (nonatomic, strong) IBInspectable NSString *overlayStoryboardId;

- (void)playInBackground:(BOOL)play;

@end
