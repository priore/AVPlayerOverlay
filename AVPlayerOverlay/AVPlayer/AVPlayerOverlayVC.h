//
//  AVPlayerOverlayVC.h
//
//  Created by Danilo Priore on 28/04/16.
//  Copyright © 2016 Prioregroup.com. All rights reserved.
//
#define AVPlayerOverlayVCWillFullScreenNotification             @"AVPlayerOverlayVCWillFullScreen"
#define AVPlayerOverlayVCDidFullScreenNotification              @"AVPlayerOverlayVCDidFullScreen"
#define AVPlayerOverlayVCWillNormalScreenNotification           @"AVPlayerOverlayVCWillNormalScreen"
#define AVPlayerOverlayVCDidNormalScreenNotification            @"AVPlayerOverlayVCDidNormalScreen"
#define AVPlayerOverlayVCAirPlayInUseNotification               @"AVPlayerOverlayVCAirPlayInUse"
#define AVPlayerOverlayVCAirPlayBecomePresentNotification       @"AVPlayerOverlayVCAirPlayBecomePresent"
#define AVPlayerOverlayVCAirPlayResignPresentNotification       @"AVPlayerOverlayVCAirPlayResignPresent"
#define AVPlayerOverlayVCWillPIPBecomeActiveNotification        @"AVPlayerOverlayVCWillPIPBecomeActive"
#define AVPlayerOverlayVCDidPIPBecomeActiveNotification         @"AVPlayerOverlayVCDidPIPBecomeActive"
#define AVPlayerOverlayVCWillPIPDeactivationNotification        @"AVPlayerOverlayVCWillPIPDeactivation"
#define AVPlayerOverlayVCDidPIPDeactivationNotification         @"AVPlayerOverlayVCDidPIPDeactivation"
#define AVPlayerOverlayVCDidPeriodicTimeObserverNotification    @"AVPlayerOverlayVCDidPeriodicTimeObserver"
#define AVPlayerOverlayVCStatusReadyToPlayNotification          @"AVPlayerOverlayVCStatusReadyToPlay"
#define AVPlayerOverlayVCDidCloseAllNotification                @"AVPlayerOverlayVCDidCloseAll"

#define kAVPlayerOverlayVCAirPlayInUse  @"airPlayInUse"

#import "AVPlayerOverlayViewController.h"

@import UIKit;
@import CoreMedia;

@class AVPlayer;
@protocol AVPlayerOverlayVCDelegate;

typedef NS_ENUM(NSInteger, AVPlayerFullscreenAutorotaionMode)
{
    AVPlayerFullscreenAutorotationDefaultMode,
    AVPlayerFullscreenAutorotationLandscapeMode
};

IB_DESIGNABLE
@interface AVPlayerOverlayVC : AVPlayerOverlayViewController

@property (nonatomic, weak) IBOutlet UIView *playerBarView;
@property (nonatomic, weak) IBOutlet UIButton *playButton;
@property (nonatomic, weak) IBOutlet UIButton *playBigButton;
@property (nonatomic, weak) IBOutlet UIButton *volumeButton;
@property (nonatomic, weak) IBOutlet UIButton *fullscreenButton;
@property (nonatomic, weak) IBOutlet UIButton *airPlayButton;
@property (nonatomic, weak) IBOutlet UIButton *subtitlesButton;
@property (nonatomic, weak) IBOutlet UIButton *pipButton;
@property (nonatomic, weak) IBOutlet UISlider *videoSlider;
@property (nonatomic, weak) IBOutlet UISlider *volumeSlider;
@property (nonatomic, weak) IBOutlet UILabel *subtitlesLabel;
@property (nonatomic, weak) IBOutlet UILabel *currentTimeLabel;
@property (nonatomic, weak) IBOutlet UILabel *durationTimeLabel;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *activityIndicatorView;

@property (nonatomic, weak) AVPlayer *player;

@property (nonatomic, assign) IBInspectable CGSize pipSize;
@property (nonatomic, assign) IBInspectable CGFloat pipPadding;
@property (nonatomic, assign) IBInspectable CGFloat pipAnimationDuration;

@property (nonatomic, assign) IBInspectable CGFloat barAnimationDuration;
@property (nonatomic, assign) IBInspectable CGFloat volumeAnimationDuration;
@property (nonatomic, assign) IBInspectable CGFloat fullscreenAnimtationDuration;
@property (nonatomic, assign) IBInspectable CGFloat subtitlesAnimtationDuration;

@property (nonatomic, assign) IBInspectable NSTimeInterval playBarAutoideInterval;
@property (nonatomic, assign) IBInspectable AVPlayerFullscreenAutorotaionMode autorotationMode;

@property (nonatomic, assign, readonly) BOOL isPIP;
@property (nonatomic, assign, readonly) BOOL isFullscreen;
@property (nonatomic, assign, readonly) BOOL isAirplayInUse;
@property (nonatomic, assign, readonly) BOOL isAirplayPresent;
@property (nonatomic, assign, readonly) BOOL isPlayerBarVisibile;

@property (nonatomic, strong, readonly) NSString *airPlayPlayerName;

@property (nonatomic, assign) id<AVPlayerOverlayVCDelegate> delegate;

- (void)updateProgressBar;

- (void)autoHidePlayerBar;
- (void)hidePlayerBar;
- (void)showPlayerBar;

- (void)didTapGesture:(id)sender;
- (void)didDoubleTapGesture:(id)sender;
- (void)didPinchGesture:(id)sender;
- (void)didPlayButtonSelected:(id)sender;
- (void)didVolumeButtonSelected:(id)sender;
- (void)didFullscreenButtonSelected:(id)sender;
- (void)didSubtitlesButtonSelected:(id)sender;
- (void)didPIPButtonSelected:(id)sender;

- (void)didVolumeSliderValueChanged:(id)sender;

- (void)didVideoSliderTouchUp:(id)sender;
- (void)didVideoSliderTouchDown:(id)sender;
- (void)videoSliderEnabled:(BOOL)enabled;

// Overridable Methods
- (void)didCloseAll;
- (void)statusReadyToPlay;
- (void)willFullScreenModeFromParentViewController:(UIViewController*)parent;
- (void)didFullScreenModeFromParentViewController:(UIViewController*)parent;
- (void)willNormalScreenModeToParentViewController:(UIViewController*)parent;
- (void)didNormalScreenModeToParentViewController:(UIViewController*)parent;
- (void)willPIPBecomeActivationViewController:(UIViewController*)parent;
- (void)didPIPBecomeActivationViewController:(UIViewController*)parent;
- (void)willPIPDeactivationViewController:(UIViewController*)parent;
- (void)didPIPDeactivationViewController:(UIViewController*)parent;

- (void)showSubtitles;
- (void)hideSubtitles;
- (void)loadSubtitlesWithURL:(NSURL*)url;

- (NSAttributedString*)attributedSubtitle:(id)subtitle;

- (void)closeAll;
- (CMTime)playerItemDuration;

- (void)animatedNormalScreenWithDuration:(CGFloat)duration
                               animation:(void(^)(UIViewController *parent))animation
                              completion:(void(^)(BOOL finished))completion;

- (void)animmatedPIPDeactivationWithDuration:(CGFloat)duration
                                   animation:(void(^)(UIViewController *parent))animation
                                  completion:(void(^)(BOOL finished))completion;

- (void)setupAirPlay;
- (void)deallocAirplay;
- (void)airPlayRouteChange:(NSNotification*)note;
- (BOOL)checkAirPlayIsRunning;
- (void)airPlayChangeInUseState:(BOOL)isInUse;
- (void)checkAirPlayRoutingViewVisible;
- (BOOL)isAirPlayRoutingInView:(UIView*)view;

- (void)airplayBecomePresent;
- (void)airplayResignPresent;

- (void)pipActivate;
- (void)pipActivateWithCompletion:(void(^)())completion;

- (void)pipDeactivate;
- (void)pipDeactivateWithCompletion:(void(^)())completion;

- (void)showMainParentBeforePIPDeactivation;
- (void)hideMainParentBeforePIPActivation;

- (void)forceDeviceOrientation:(UIInterfaceOrientation)orientation;
- (void)deviceOrientationDidChange:(NSNotification *)notification;

@end

@protocol  AVPlayerOverlayVCDelegate <NSObject>

@optional

- (void)avPlayerOverlay:(AVPlayerOverlayVC*)viewController willFullScreen:(id)sender;
- (void)avPlayerOverlay:(AVPlayerOverlayVC*)viewController didFullScreen:(id)sender;
- (void)avPlayerOverlay:(AVPlayerOverlayVC*)viewController willNormalScreen:(id)sender;
- (void)avPlayerOverlay:(AVPlayerOverlayVC*)viewController didNormalScreen:(id)sender;
- (void)avPlayerOverlay:(AVPlayerOverlayVC*)viewController airPlayInUse:(BOOL)inUse;
- (void)avPlayerOverlay:(AVPlayerOverlayVC*)viewController airPlayBecomePresent:(id)sender;
- (void)avPlayerOverlay:(AVPlayerOverlayVC*)viewController airPlayResignPresent:(id)sender;
- (void)avPlayerOverlay:(AVPlayerOverlayVC*)viewController willPIPBecomeActive:(id)sender;
- (void)avPlayerOverlay:(AVPlayerOverlayVC*)viewController didPIPBecomeActive:(id)sender;
- (void)avPlayerOverlay:(AVPlayerOverlayVC*)viewController willPIPDeactivation:(id)sender;
- (void)avPlayerOverlay:(AVPlayerOverlayVC*)viewController didPIPDeactivation:(id)sender;
- (void)avPlayerOverlay:(AVPlayerOverlayVC*)viewController periodicTimeObserver:(CMTime)time;
- (void)avPlayerOverlay:(AVPlayerOverlayVC*)viewController statusReadyToPlay:(id)sender;
- (void)avPlayerOverlay:(AVPlayerOverlayVC*)viewController didCloseAll:(id)sender;

@end

