//
//  AVPlayerPIPOverlayVC.h
//  AVPlayerOverlay
//
//  Created by Danilo Priore on 22/03/17.
//  Copyright © 2017 Danilo Priore. All rights reserved.
//
#define AVPlayerOverlayPIPClosedNotification @"AVPlayerOverlayPIPClosed"

#import "AVPlayerOverlayViewController.h"

@import AVKit;
@import CoreMedia;

@protocol AVPlayerPIPOverlayVCDelegate;

IB_DESIGNABLE
@interface AVPlayerPIPOverlayVC : AVPlayerOverlayViewController

@property (nonatomic, weak) IBOutlet UIView *playerBarView;
@property (nonatomic, weak) IBOutlet UIButton *playButton;
@property (nonatomic, weak) IBOutlet UIButton *restoreButton;
@property (nonatomic, weak) IBOutlet UIButton *closeButton;
@property (nonatomic, weak) IBOutlet UISlider *videoSlider;
@property (nonatomic, weak) IBOutlet UILabel *currentTimeLabel;
@property (nonatomic, weak) IBOutlet UILabel *durationTimeLabel;

@property (nonatomic, assign) IBInspectable CGFloat animationDuration;

@property (nonatomic, weak) AVPlayer *player;

@property (nonatomic, assign) id<AVPlayerPIPOverlayVCDelegate> delegate;

- (void)didPlayButtonSelected:(id)sender;
- (void)didRestoreButtonSelected:(id)sender;
- (void)didCloseButtonSelected:(id)sender;

- (void)showControls;
- (void)hideControls;

- (void)setCurrentTimeValue:(CMTime)time;

@end

@protocol AVPlayerPIPOverlayVCDelegate <NSObject>

- (void)pipOverlayViewController:(UIViewController*)viewController willPIPClosed:(id)sender;
- (void)pipOverlayViewController:(UIViewController*)viewController willPIPDeactivation:(id)sender;

@end
