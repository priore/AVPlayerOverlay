//
//  AVPlayerVC.h
//
//  Created by Danilo Priore on 28/04/16.
//  Copyright © 2016 Prioregroup.com. All rights reserved.
//
#define AVPlayerVCSetVideoURLNotification @"avplayervcsetvideourl"

#import <AVKit/AVKit.h>

@interface AVPlayerVC : AVPlayerViewController

@property (nonatomic, strong) NSURL *videoURL;

@end
