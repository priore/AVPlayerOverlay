//
//  AVPlayerOverlayVC.h
//
//  Created by Danilo Priore on 28/04/16.
//  Copyright © 2016 Prioregroup.com. All rights reserved.
//
#define AVPlayerOverlayVCFullScreenNotification     @"AVPlayerOverlayVCFullScreen"
#define AVPlayerOverlayVCNormalScreenNotification   @"AVPlayerOverlayVCNormalScreen"

#import <UIKit/UIKit.h>

@class AVPlayer;

@interface AVPlayerOverlayVC : UIViewController

@property (nonatomic, weak) IBOutlet UIView *playerBarView;
@property (nonatomic, weak) IBOutlet UIButton *playButton;
@property (nonatomic, weak) IBOutlet UIButton *playBigButton;
@property (nonatomic, weak) IBOutlet UIButton *volumeButton;
@property (nonatomic, weak) IBOutlet UIButton *fullscreenButton;
@property (nonatomic, weak) IBOutlet UISlider *videoSlider;
@property (nonatomic, weak) IBOutlet UISlider *volumeSlider;

@property (nonatomic, weak) AVPlayer *player;
@property (nonatomic, assign) BOOL isFullscreen;

- (void)updateProgressBar;

- (void)autoHidePlayerBar;
- (void)hidePlayerBar;
- (void)showPlayerBar;

- (void)didTapGesture:(id)sender;
- (void)didPlayButtonSelected:(id)sender;
- (void)didVolumeButtonSelected:(id)sender;
- (void)didFullscreenButtonSelected:(id)sender;

- (void)didVolumeSliderValueChanged:(id)sender;

- (void)didVideoSliderTouchUp:(id)sender;
- (void)didVideoSliderTouchDown:(id)sender;
- (void)videoSliderEnabled:(BOOL)enabled;

- (void)didFullScreenModeFromParentViewController:(UIViewController*)parent;
- (void)didNormalScreenModeToParentViewController:(UIViewController*)parent;

@end
