//
//  AVPlayerPIPOverlayVC.h
//  AVPlayerOverlay
//
//  Created by Danilo Priore on 22/03/17.
//  Copyright © 2017 Danilo Priore. All rights reserved.
//
#define AVPlayerPIPOverlayVCwillPIPDeactivationNotification @"AVPlayerPIPOverlayVCwillPIPDeactivation"

#import <UIKit/UIKit.h>

@class AVPlayer;

IB_DESIGNABLE
@interface AVPlayerPIPOverlayVC : UIViewController

@property (nonatomic, weak) IBOutlet UIView *playerBarView;
@property (nonatomic, weak) IBOutlet UIButton *playButton;
@property (nonatomic, weak) IBOutlet UIButton *restoreButton;
@property (nonatomic, weak) IBOutlet UIButton *closeButton;

@property (nonatomic, assign) IBInspectable CGFloat animationDuration;

@property (nonatomic, weak) AVPlayer *player;

- (void)didPlayButtonSelected:(id)sender;
- (void)didRestoreButtonSelected:(id)sender;
- (void)didCloseButtonSelected:(id)sender;

- (void)didPipBecomeActiveNotification:(NSNotification*)note;
- (void)willPipDeactivationNotification:(NSNotification*)note;

@end
