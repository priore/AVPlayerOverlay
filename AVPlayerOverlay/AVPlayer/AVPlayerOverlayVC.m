//
//  AVPlayerOverlayVC.m
//
//  Created by Danilo Priore on 28/04/16.
//  Copyright © 2016 Prioregroup.com. All rights reserved.
//
#import "AVPlayerOverlayVC.h"
#import "AVPlayerPIPOverlayVC.h"
#import "SubtitlePackage.h"
#import "UIView+draggable.h"

@import AVFoundation;
@import MediaPlayer;

@interface AVPlayerOverlayVC ()

@property (nonatomic, weak) UISlider *mpSlider;
@property (nonatomic, weak) UIWindow *mainWindow;
@property (nonatomic, weak) UIButton *airPlayInternalButton;
@property (nonatomic, weak) UINavigationController *navController;

@property (nonatomic, assign) CGRect currentFrame;
@property (nonatomic, assign) CGRect originalFrame;

@property (nonatomic, strong) UIWindow *window;
@property (nonatomic, strong) MPVolumeView *volume;
@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UIViewController *mainParent;

@property (nonatomic, strong) id timeObserver;

@property (nonatomic, assign) BOOL isPreloaded;
@property (nonatomic, assign) BOOL isVideoSliderMoving;
@property (nonatomic, assign) BOOL isAirPlayRoutingVisible;

@property (nonatomic, assign) BOOL hiddenStatusBar;
@property (nonatomic, assign) BOOL hiddenNavBar;

@property (nonatomic, assign) UIDeviceOrientation currentOrientation;

@property (nonatomic, strong) SubtitlePackage *subtitles;

@end

@implementation AVPlayerOverlayVC

static void *AirPlayContext = &AirPlayContext;
static void *PlayViewControllerCurrentItemObservationContext = &PlayViewControllerCurrentItemObservationContext;

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        
        _pipSize = CGSizeMake(200, 112.5);
        _pipAnimationDuration = 1.0;
        _pipPadding = 10.0;
        
        _isPIP = NO;
        _isPreloaded = NO;
        _isFullscreen = NO;
        _isVideoSliderMoving = NO;
        _isPlayerBarVisibile = YES;
        _barAnimationDuration = 1.0;
        _playBarAutoideInterval = 5.0;
        _volumeAnimationDuration = .25;
        _subtitlesAnimtationDuration = .15;
        _fullscreenAnimtationDuration = .5;
        _autorotationMode = AVPlayerFullscreenAutorotationDefaultMode;
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.clipsToBounds = YES;
    self.view.backgroundColor = [UIColor clearColor];
    
    // system volume
    _volume = [[MPVolumeView alloc] initWithFrame:CGRectZero];
    for (id view in _volume.subviews) {
        if ([view isKindOfClass:[UISlider class]]) {
            _mpSlider = view;
            break;
        }
    }
    
    _volumeSlider.hidden = YES;
    _volumeSlider.transform = CGAffineTransformMakeRotation(-M_PI_2);
    _volumeSlider.value = [AVAudioSession sharedInstance].outputVolume;
    
    _playButton.enabled = NO;
    _playBigButton.alpha = 0.0;
    _playBigButton.hidden = YES;
    _playBigButton.enabled = NO;
    _playBigButton.layer.borderWidth = 1.0;
    _playBigButton.layer.borderColor = [UIColor whiteColor].CGColor;
    _playBigButton.layer.cornerRadius = _playBigButton.frame.size.width / 2.0;
    
    _subtitlesLabel.hidden = YES;
    _subtitlesLabel.numberOfLines = 0;
    _subtitlesLabel.contentMode = UIViewContentModeBottom;
    _subtitlesLabel.baselineAdjustment = UIBaselineAdjustmentAlignBaselines;
    _subtitlesButton.enabled = NO;
    
    _activityIndicatorView.hidesWhenStopped = YES;
    
    [self videoSliderEnabled:NO];
    [self setupAirPlay];
    
    // actions
    [_playButton addTarget:self action:@selector(didPlayButtonSelected:) forControlEvents:UIControlEventTouchUpInside];
    [_playBigButton addTarget:self action:@selector(didPlayButtonSelected:) forControlEvents:UIControlEventTouchUpInside];
    [_volumeButton addTarget:self action:@selector(didVolumeButtonSelected:) forControlEvents:UIControlEventTouchUpInside];
    [_fullscreenButton addTarget:self action:@selector(didFullscreenButtonSelected:) forControlEvents:UIControlEventTouchUpInside];
    [_videoSlider addTarget:self action:@selector(didVideoSliderTouchUp:) forControlEvents:UIControlEventTouchUpInside];
    [_videoSlider addTarget:self action:@selector(didVideoSliderTouchDown:) forControlEvents:UIControlEventTouchDown];
    [_volumeSlider addTarget:self action:@selector(didVolumeSliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    [_subtitlesButton addTarget:self action:@selector(didSubtitlesButtonSelected:) forControlEvents:UIControlEventTouchUpInside];
    [_airPlayButton addTarget:self action:@selector(didAirPlayButtonSelected:) forControlEvents:UIControlEventTouchUpInside];
    [_pipButton addTarget:self action:@selector(didPIPButtonSelected:) forControlEvents:UIControlEventTouchUpInside];
    
    // tap gesture for hide/show player bar
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapGesture:)];
    [self.view addGestureRecognizer:tap];
    
    // double tap gesture for normal and fullscreen
    UITapGestureRecognizer *doubleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didDoubleTapGesture:)];
    doubleTapGesture.numberOfTapsRequired = 2;
    [self.view addGestureRecognizer:doubleTapGesture];
    
    // pinch gesture for normal and fullscreen
    UIPinchGestureRecognizer *pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(didPinchGesture:)];
    [self.view addGestureRecognizer:pinchGesture];
    
    // device rotation
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationDidChange:) name:UIDeviceOrientationDidChangeNotification object:nil];
    
    [self.view layoutIfNeeded];
    [self autoHidePlayerBar];
    
}

- (void)dealloc
{
    if (_timeObserver)
        [_player removeTimeObserver:_timeObserver];
    _timeObserver = nil;

    @try {
        [_player.currentItem removeObserver:self forKeyPath:@"status"];
    } @catch (NSException *exception) { }
    
    [self deallocAirplay];

    _volume = nil;
    _player = nil;
    _delegate = nil;
    
    _navController = nil;
    _containerView = nil;
    _mainParent = nil;

    [_window removeFromSuperview], _window = nil;
    [_mainWindow makeKeyAndVisible];
    
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
}

- (void)setPlayer:(AVPlayer *)player
{
    @synchronized (self) {
        
        if (_player) {
            
            if (_timeObserver)
                [_player removeTimeObserver:_timeObserver], _timeObserver = nil;
            
            @try {
                [_player.currentItem removeObserver:self forKeyPath:@"status"];
            } @catch (NSException *exception) { }
        }
        
        _player = player;

        if (_player == nil) {
            
            _volumeSlider.value = 1.0;
            _videoSlider.value = 0.0;
            _playButton.enabled = NO;
            _playBigButton.enabled = NO;

        } else {
            
            __weak typeof(self) wself = self;
            self.timeObserver =  [_player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(0.5, NSEC_PER_SEC)
                                                                       queue:NULL
                                                                  usingBlock:^(CMTime time){
                                                                      
                                                                      [wself updateProgressBar];
                                                                      
                                                                      wself.playButton.selected = wself.player.rate != 0;
                                                                      wself.playBigButton.selected = wself.player.rate != 0;
                                                                      
                                                                      if (wself.currentTimeLabel)
                                                                          wself.currentTimeLabel.text = CMTIME_IS_VALID(time) ? [SubtitlePackage makeSaveName:time] : nil;
                                                                      
                                                                      if (!wself.subtitlesLabel.hidden && wself.subtitles.subtitleItems.count > 0)
                                                                      {
                                                                          NSInteger index = [wself.subtitles indexOfProperSubtitleWithGivenCMTime:time];
                                                                          IndividualSubtitle *subtitle = wself.subtitles.subtitleItems[index];
                                                                          [UIView transitionWithView:wself.subtitlesLabel
                                                                                            duration:_subtitlesAnimtationDuration
                                                                                             options:UIViewAnimationOptionTransitionCrossDissolve
                                                                                          animations:^{
                                                                                              wself.subtitlesLabel.attributedText = [wself attributedSubtitle:subtitle];
                                                                                          } completion:nil];
                                                                      }
                                                                      
                                                                      NSValue *o_time =[NSValue valueWithCMTime:time];
                                                                      [self sendActionsForEvent:AVPlayerOverlayEventPeriodicTimeObserver object:o_time];
                                                                      
                                                                      [[NSNotificationCenter defaultCenter] postNotificationName:AVPlayerOverlayVCDidPeriodicTimeObserverNotification object:o_time];
                                                                      
                                                                      if ([_delegate respondsToSelector:@selector(avPlayerOverlay:periodicTimeObserver:)])
                                                                          [_delegate avPlayerOverlay:self periodicTimeObserver:time];
                                                                      
                                                                  }];
            
            if (_player.currentItem) {
                
                _isPreloaded = NO;
                
                [_player.currentItem addObserver:self
                          forKeyPath:@"status"
                             options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                             context:PlayViewControllerCurrentItemObservationContext];
            }

            _videoSlider.value = 0;
            _volumeSlider.value = _player.volume;
            _playButton.enabled = YES;
            _playBigButton.enabled = YES;
        }
        
        _playButton.selected = NO;
        _playBigButton.selected = NO;

        [self showPlayerBar];
        [self videoSliderEnabled:NO];
    }
}

- (void)updateProgressBar
{
    Float64 duration = CMTimeGetSeconds(_player.currentItem.duration);
    if (!_isVideoSliderMoving && !isnan(duration)) {
        _videoSlider.maximumValue = duration;
        _videoSlider.value = CMTimeGetSeconds(_player.currentTime);
        
        [self videoSliderEnabled:YES];
    } else if (_videoSlider.isUserInteractionEnabled) {
        
        [self videoSliderEnabled:NO];
    }
}

- (void)setConstraintValue:(CGFloat)value
              forAttribute:(NSLayoutAttribute)attribute
                  duration:(NSTimeInterval)duration
                animations:(void(^)())animations
                completion:(void(^)(BOOL finished))completion
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        NSArray *constraints = self.view.constraints;
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"firstAttribute = %d", attribute];
        NSArray *filteredArray = [constraints filteredArrayUsingPredicate:predicate];
        NSLayoutConstraint *constraint = [filteredArray firstObject];
        if (constraint.constant != value) {
            [self.view removeConstraint:constraint];
            constraint.constant = value;
            [self.view addConstraint:constraint];
            
            [UIView animateWithDuration:duration animations:^{
                if (animations)
                    animations();
                [self.view layoutIfNeeded];
            } completion:completion];
        }
    });
}

#pragma mark - Observer

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == AirPlayContext)
    {
        if (object == _airPlayInternalButton && [[change valueForKey:NSKeyValueChangeNewKey] intValue] == 1) {
            // airplayIsPresent
            _isAirplayPresent = YES;
            [self airplayBecomePresent];
        }
        else {
            _isAirplayPresent = NO;
            [self airplayResignPresent];
        }
    }
    else if (context == PlayViewControllerCurrentItemObservationContext)
    {
        AVPlayerStatus status = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
        switch (status) {
            case AVPlayerStatusUnknown:
                break;
                
            case AVPlayerStatusReadyToPlay:
                [self statusReadyToPlay];
                break;
                
            case AVPlayerStatusFailed:
                break;
        }
    }
    else
    {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}


#pragma mark - PlayerBar

- (void)autoHidePlayerBar
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hidePlayerBar) object:nil];

    if (_playBarAutoideInterval > 0) {
        [self performSelector:@selector(hidePlayerBar) withObject:nil afterDelay:_playBarAutoideInterval];
    }
}

- (void)hidePlayerBar
{
    if (_isAirplayInUse || _isAirPlayRoutingVisible)
        return;
    
    CGFloat height = _playerBarView.frame.size.height;

    __weak typeof(self) wself = self;
    [self setConstraintValue:height
                forAttribute:NSLayoutAttributeBottom
                    duration:_barAnimationDuration
                  animations:^{
                      wself.volumeSlider.alpha = 0.0;
                      wself.playBigButton.alpha = 0.0;
                  } completion:^(BOOL finished) {
                      _isPlayerBarVisibile = NO;
                      wself.volumeSlider.hidden = YES;
                      wself.playerBarView.hidden = YES;
                      wself.playBigButton.hidden = YES;
                  }];
}

- (void)showPlayerBar
{
    _playerBarView.hidden = NO;
    _playBigButton.hidden = !_isPreloaded;
    
    __weak typeof(self) wself = self;
    [self setConstraintValue:0
                forAttribute:NSLayoutAttributeBottom
                    duration:_barAnimationDuration
                  animations:^{
                      wself.playBigButton.alpha = 1.0;
                  }
                  completion:^(BOOL finished) {
                      _isPlayerBarVisibile = YES;
                      [wself autoHidePlayerBar];
                  }];
}

#pragma mark - Actions

- (void)didTapGesture:(UITapGestureRecognizer*)sender
{
    if (_playerBarView.hidden)
    {
        [self showPlayerBar];
    }
    else if (_volumeSlider.hidden)
    {
        [self didPlayButtonSelected:nil];
    }
}

- (void)didDoubleTapGesture:(UITapGestureRecognizer*)sender
{
    [self didFullscreenButtonSelected:nil];
}

- (void)didPinchGesture:(UIPinchGestureRecognizer*)sender
{
    if ((sender.scale > 1.0 && !_isFullscreen) || (sender.scale <= 1.0 && _isFullscreen))
        [self didFullscreenButtonSelected:nil];
}

- (void)didPlayButtonSelected:(id)sender
{
    if (_player.currentItem != nil)
    {
        if (_player.rate == 0)
        {
            [_player play];
            
            _playButton.selected = YES;
            _playBigButton.selected = YES;
            
        } else {
            [_player pause];
            
            _playButton.selected = NO;
            _playBigButton.selected = NO;
            
        }
    }
    
    [self autoHidePlayerBar];
}

- (void)didVolumeButtonSelected:(id)sender
{
    if (_volumeSlider.hidden)
    {
        _volumeSlider.alpha = 0.0;
        _volumeSlider.hidden = NO;
        _volumeSlider.value = [AVAudioSession sharedInstance].outputVolume;
        [UIView animateWithDuration:_volumeAnimationDuration
                         animations:^{
                             _volumeSlider.alpha = 1.0;
                         }];
        
    }
    else
    {
        _volumeSlider.alpha = 1.0;
        [UIView animateWithDuration:_volumeAnimationDuration
                         animations:^{
                             _volumeSlider.alpha = 0.0;
                         } completion:^(BOOL finished) {
                             _volumeSlider.hidden = YES;
                         }];
    }
    
    [self autoHidePlayerBar];
}

- (void)didFullscreenButtonSelected:(id)sender
{
    UIViewController *parent = self.parentViewController; // AVPlayerViewController
    
    if (_mainWindow == nil)
        _mainWindow = [UIApplication sharedApplication].keyWindow;

    if (_window == nil)
    {
        self.originalFrame = parent.view.frame;
        self.mainParent = parent.parentViewController;
        self.currentFrame = [parent.view convertRect:parent.view.frame toView:_mainWindow];
        self.containerView = parent.view.superview;
        
        [parent removeFromParentViewController];
        [parent.view removeFromSuperview];
        [parent willMoveToParentViewController:nil];
        
        self.window = [[UIWindow alloc] initWithFrame:_currentFrame];
        _window.backgroundColor = [UIColor blackColor];
        _window.windowLevel = UIWindowLevelNormal;
        [_window makeKeyAndVisible];
        
        _window.rootViewController = parent;
        parent.view.frame = _window.bounds;
        
        [self willFullScreenModeFromParentViewController:parent];
        [UIView animateKeyframesWithDuration:_fullscreenAnimtationDuration
                                       delay:0
                                     options:UIViewKeyframeAnimationOptionLayoutSubviews
                                  animations:^{
                                      _window.frame = _mainWindow.bounds;
                                  } completion:^(BOOL finished) {
                                      _fullscreenButton.transform = CGAffineTransformMakeScale(-1.0, -1.0);
                                      _isFullscreen = YES;
                                      
                                      [self didFullScreenModeFromParentViewController:parent];
                                  }];
        
    } else {
        
        [self animatedNormalScreenWithDuration:_fullscreenAnimtationDuration animation:^(UIViewController *parent) {
            _window.frame = _currentFrame;
        } completion:nil];
    }
    
    [self autoHidePlayerBar];
}

- (void)didSubtitlesButtonSelected:(id)sender
{
    _subtitlesButton.selected = !_subtitlesButton.selected;
    if (_subtitlesButton.selected)
        [self showSubtitles];
    else
        [self hideSubtitles];
}

- (void)didAirPlayButtonSelected:(id)sender
{
    [_airPlayInternalButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    [self checkAirPlayRoutingViewVisible];
}

- (void)didPIPButtonSelected:(id)sender
{
    [self pipActivate];
}

#pragma mark - Overridable Methods

- (void)didCloseAll
{
    [self sendActionsForEvent:AVPlayerOverlayEventDidCloseAll object:self];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:AVPlayerOverlayVCDidCloseAllNotification object:self];
    
    if ([_delegate respondsToSelector:@selector(avPlayerOverlay:didCloseAll:)])
        [_delegate avPlayerOverlay:self didCloseAll:nil];
}

- (void)statusReadyToPlay
{
    _isPreloaded = YES;
    
    _playBigButton.hidden = NO;
    if (_isPlayerBarVisibile) {
        [UIView animateWithDuration:0.3 animations:^{
            _playBigButton.alpha = 1.0;
        }];
    }
    
    if (_durationTimeLabel) {
        CMTime duration = [self playerItemDuration];
        _durationTimeLabel.text = CMTIME_IS_VALID(duration) ? [SubtitlePackage makeSaveName:duration] : nil;
    }
    
    [_activityIndicatorView stopAnimating];
    
    [self sendActionsForEvent:AVPlayerOverlayEventStatusReadyToPlay object:self];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:AVPlayerOverlayVCStatusReadyToPlayNotification object:self];
    
    if ([_delegate respondsToSelector:@selector(avPlayerOverlay:statusReadyToPlay:)])
        [_delegate avPlayerOverlay:self statusReadyToPlay:nil];
}

- (void)willFullScreenModeFromParentViewController:(UIViewController*)parent
{
    _hiddenNavBar = self.navigationController.isNavigationBarHidden;
    _hiddenStatusBar = [UIApplication sharedApplication].isStatusBarHidden;
    
    [self sendActionsForEvent:AVPlayerOverlayEventWillFullScreenMode object:parent];

    [[NSNotificationCenter defaultCenter] postNotificationName:AVPlayerOverlayVCWillFullScreenNotification object:self];
    
    if ([_delegate respondsToSelector:@selector(avPlayerOverlay:willFullScreen:)])
        [_delegate avPlayerOverlay:self willFullScreen:parent];
}

- (void)didFullScreenModeFromParentViewController:(UIViewController*)parent
{
    if (_autorotationMode == AVPlayerFullscreenAutorotationLandscapeMode)
    {
        UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
        // force fullscreen for landscape device rotation
        [self forceDeviceOrientation:UIInterfaceOrientationUnknown];
        if (orientation == UIDeviceOrientationLandscapeRight) {
            [self forceDeviceOrientation:UIInterfaceOrientationLandscapeLeft];
        } else {
            [self forceDeviceOrientation:UIInterfaceOrientationUnknown];
            [self forceDeviceOrientation:UIInterfaceOrientationLandscapeRight];
        }
        
        [self.navigationController setNavigationBarHidden:YES animated:YES];
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
    }

    [self sendActionsForEvent:AVPlayerOverlayEventDidFullScreenMode object:parent];

    [[NSNotificationCenter defaultCenter] postNotificationName:AVPlayerOverlayVCDidFullScreenNotification object:self];
    
    if ([_delegate respondsToSelector:@selector(avPlayerOverlay:didFullScreen:)])
        [_delegate avPlayerOverlay:self didFullScreen:parent];
}

- (void)willNormalScreenModeToParentViewController:(UIViewController*)parent
{
        if (_autorotationMode == AVPlayerFullscreenAutorotationLandscapeMode)
            [self forceDeviceOrientation:UIInterfaceOrientationPortrait];
    
    [[UIApplication sharedApplication] setStatusBarHidden:_hiddenStatusBar withAnimation:UIStatusBarAnimationFade];
    [self.navigationController setNavigationBarHidden:_hiddenNavBar animated:YES];

    [self sendActionsForEvent:AVPlayerOverlayEventWillNormalScreenMode object:parent];

    [[NSNotificationCenter defaultCenter] postNotificationName:AVPlayerOverlayVCWillNormalScreenNotification object:self];
    
    if ([_delegate respondsToSelector:@selector(avPlayerOverlay:willNormalScreen:)])
        [_delegate avPlayerOverlay:self willNormalScreen:parent];
}

- (void)didNormalScreenModeToParentViewController:(UIViewController*)parent
{
    if (_autorotationMode == AVPlayerFullscreenAutorotationLandscapeMode)
        [self forceDeviceOrientation:UIInterfaceOrientationPortrait];
    
    [self sendActionsForEvent:AVPlayerOverlayEventDidNormalScreenMode object:parent];

    [[NSNotificationCenter defaultCenter] postNotificationName:AVPlayerOverlayVCDidNormalScreenNotification object:self];
    
    if ([_delegate respondsToSelector:@selector(avPlayerOverlay:didNormalScreen:)])
        [_delegate avPlayerOverlay:self didNormalScreen:parent];
}

- (void)willPIPBecomeActivationViewController:(UIViewController*)parent
{
    [self sendActionsForEvent:AVPlayerOverlayEventWillPIPBecomeActive object:parent];

    [[NSNotificationCenter defaultCenter] postNotificationName:AVPlayerOverlayVCWillPIPBecomeActiveNotification object:self];
    
    if ([_delegate respondsToSelector:@selector(avPlayerOverlay:willPIPBecomeActive:)])
        [_delegate avPlayerOverlay:self willPIPBecomeActive:parent];
}

- (void)didPIPBecomeActivationViewController:(UIViewController*)parent
{
    _isPIP = YES;
    
    [self sendActionsForEvent:AVPlayerOverlayEventDidPIPBecomeActive object:parent];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:AVPlayerOverlayVCDidPIPBecomeActiveNotification object:self];
    
    if ([_delegate respondsToSelector:@selector(avPlayerOverlay:didPIPBecomeActive:)])
        [_delegate avPlayerOverlay:self didPIPBecomeActive:parent];
}

- (void)willPIPDeactivationViewController:(UIViewController*)parent
{
    [self sendActionsForEvent:AVPlayerOverlayEventWillPIPDeactivation object:parent];

    [[NSNotificationCenter defaultCenter] postNotificationName:AVPlayerOverlayVCWillPIPDeactivationNotification object:self];
    
    if ([_delegate respondsToSelector:@selector(avPlayerOverlay:willPIPDeactivation:)])
        [_delegate avPlayerOverlay:self willPIPDeactivation:parent];
}

- (void)didPIPDeactivationViewController:(UIViewController*)parent
{
    _isPIP = NO;
    
    [self sendActionsForEvent:AVPlayerOverlayEventDidPIPDeactivation object:parent];

    [[NSNotificationCenter defaultCenter] postNotificationName:AVPlayerOverlayVCDidPIPDeactivationNotification object:self];
    
    if ([_delegate respondsToSelector:@selector(avPlayerOverlay:didPIPDeactivation:)])
        [_delegate avPlayerOverlay:self didPIPDeactivation:parent];
}

#pragma mark - Volume Slider

- (void)didVolumeSliderValueChanged:(id)sender
{
    _mpSlider.value = ((UISlider*)sender).value;
    [_mpSlider sendActionsForControlEvents:UIControlEventTouchUpInside];
    
    [self autoHidePlayerBar];
}

#pragma mark - Video Slider

- (void)didVideoSliderTouchUp:(id)sender
{
    if (_player.status == AVPlayerStatusReadyToPlay)
    {
        Float64 timeStart = ((UISlider*)sender).value;
        int32_t timeScale = _player.currentItem.asset.duration.timescale;
        CMTime seektime = CMTimeMakeWithSeconds(timeStart, timeScale);
        if (CMTIME_IS_VALID(seektime))
            [_player seekToTime:seektime toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
    }
    
    _isVideoSliderMoving = NO;
    [self autoHidePlayerBar];
}

- (void)didVideoSliderTouchDown:(id)sender
{
    _isVideoSliderMoving = YES;
    [self autoHidePlayerBar];
}

- (void)videoSliderEnabled:(BOOL)enabled
{
    if (!_isVideoSliderMoving) {
        if (enabled && !_videoSlider.isUserInteractionEnabled) {
            _videoSlider.userInteractionEnabled = YES;
            [UIView animateWithDuration:0.25 animations:^{
                _videoSlider.alpha = 1.0;
            }];
        } else if (!enabled && _videoSlider.isUserInteractionEnabled) {
            _videoSlider.userInteractionEnabled = NO;
            [UIView animateWithDuration:0.25 animations:^{
                _videoSlider.alpha = 0.3;
            }];
        }
    }
}

#pragma mark - Subtitles

- (void)showSubtitles
{
    _subtitlesLabel.alpha = 0.0;
    _subtitlesLabel.hidden = NO;
    [UIView animateWithDuration:_subtitlesAnimtationDuration animations:^{
        _subtitlesLabel.alpha = 1.0;
    }];
}

- (void)hideSubtitles
{
    [UIView animateWithDuration:_subtitlesAnimtationDuration animations:^{
        _subtitlesLabel.alpha = 0.0;
    } completion:^(BOOL finished) {
        _subtitlesLabel.hidden = YES;
    }];
}

- (void)loadSubtitlesWithURL:(NSURL*)url
{
    _subtitles = nil;
    
    if (url == nil || _subtitlesButton == nil || _subtitlesLabel == nil)
        return;
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error == nil) {
            NSString *context = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            _subtitles = [[SubtitlePackage alloc] initWithContext:context];
            _subtitlesButton.enabled = _subtitles.subtitleItems.count > 0;
        }
    }];
    
    [task resume];
}

- (NSAttributedString*)attributedSubtitle:(IndividualSubtitle*)subtitle
{
    NSDictionary *options = @{NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType};
    NSDictionary *attrsDictionary = [NSDictionary dictionaryWithObject:_subtitlesLabel.textColor forKey:NSForegroundColorAttributeName];
    
    __block NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] initWithString:@"" attributes:attrsDictionary];;
    
    NSString *str = [NSString stringWithFormat:@"%@\n%@", subtitle.ChiSubtitle ?: @"", subtitle.EngSubtitle ?: @""];
    [str enumerateLinesUsingBlock:^(NSString *line, BOOL *stop)
     {
         NSError *error;
         line = [NSString stringWithFormat:@"<font color=\"#FFFFFF\">%@</font>", line];
         NSAttributedString *preview = [[NSAttributedString alloc] initWithData:[line dataUsingEncoding:NSUTF8StringEncoding]
                                                                        options:options
                                                             documentAttributes:nil
                                                                          error:&error];
         [attrString appendAttributedString:preview];
         
         if (line.length)
             [attrString appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n" attributes:attrsDictionary]];
     }];
    
    NSRange rng = NSMakeRange(0, attrString.length);
    NSMutableParagraphStyle *paragraphStyle = NSMutableParagraphStyle.new;
    paragraphStyle.alignment = NSTextAlignmentCenter;
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    
    [attrString addAttribute:NSFontAttributeName value:_subtitlesLabel.font range:NSMakeRange(0, attrString.length)];
    [attrString addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:rng];
    
    return attrString;
}

#pragma mark - Player Helper

- (void)closeAll
{
    // close fullscreen
    [self animatedNormalScreenWithDuration:_fullscreenAnimtationDuration / 2.0 animation:^(UIViewController *parent) {
        _window.transform = CGAffineTransformScale(_window.transform, 0.01, 0.01);
    } completion:^(BOOL finished) {
        [self didCloseAll];
    }];
    
    // close PIP
    [self animmatedPIPDeactivationWithDuration:_pipAnimationDuration / 2.0 animation:^(UIViewController *parent) {
        parent.view.transform = CGAffineTransformScale(parent.view.transform, 0.01, 0.01);
    } completion:^(BOOL finished) {
        [self didCloseAll];
    }];
}

- (CMTime)playerItemDuration
{
    if (_player.currentItem && _player.currentItem.asset) {
        if (_player.currentItem.status == AVPlayerItemStatusReadyToPlay && !CMTIME_IS_INDEFINITE(_player.currentItem.asset.duration)) {
            return _player.currentItem.asset.duration;
        }
    }
    
    return kCMTimeInvalid;
}

- (void)animatedNormalScreenWithDuration:(CGFloat)duration animation:(void (^)(UIViewController *parent))animation completion:(void(^)(BOOL finished))completion
{
    if (_isFullscreen) {
        
        UIViewController *parent = self.parentViewController; // AVPlayerViewController
        if (parent) {
            
            [self willNormalScreenModeToParentViewController:parent];
            
            _window.frame = _mainWindow.bounds;
            [UIView animateKeyframesWithDuration:duration
                                           delay:0
                                         options:UIViewKeyframeAnimationOptionLayoutSubviews
                                      animations:^{
                                          if (animation)
                                              animation(parent);
                                      }
                                      completion:^(BOOL finished) {
                                          
                                          [parent.view removeFromSuperview];
                                          _window.rootViewController = nil;
                                          
                                          [_mainParent addChildViewController:parent];
                                          [_containerView addSubview:parent.view];
                                          parent.view.frame = _originalFrame;
                                          [parent didMoveToParentViewController:_mainParent];
                                          
                                          [_mainWindow makeKeyAndVisible];
                                          
                                          _fullscreenButton.transform = CGAffineTransformIdentity;
                                          _isFullscreen = NO;
                                          
                                          _containerView = nil;
                                          _mainParent = nil;
                                          _window = nil;
                                          
                                          [self didNormalScreenModeToParentViewController:parent];
                                          
                                          if (completion)
                                              completion(finished);
                                          
                                      }];
        }
    }
}

- (void)animmatedPIPDeactivationWithDuration:(CGFloat)duration animation:(void (^)(UIViewController *parent))animation completion:(void(^)(BOOL finished))completion
{
    if (_isPIP) {
        
        UIViewController *parent = self.parentViewController; // AVPlayerViewController
        if (parent) {
            
            [self willPIPDeactivationViewController:parent];
            [self showMainParentBeforePIPDeactivation];
            
            [UIView animateWithDuration:duration
                                  delay:0
                                options:UIViewAnimationOptionCurveEaseInOut
                             animations:^{
                                 if (animation) {
                                     animation(parent);
                                 }
                             }
                             completion:^(BOOL finished) {
                                 
                                 [parent.view removeFromSuperview];
                                 
                                 [_mainParent addChildViewController:parent];
                                 [_containerView addSubview:parent.view];
                                 parent.view.frame = _originalFrame;
                                 [parent didMoveToParentViewController:_mainParent];
                                 
                                 self.view.alpha = 1.0;
                                 self.view.hidden = NO;
                                 [self showPlayerBar];
                                 
                                 _navController = nil;
                                 _containerView = nil;
                                 _mainParent = nil;
                                 
                                 [self didPIPDeactivationViewController:parent];
                                 
                                 if (completion) {
                                     completion(finished);
                                 }
                             }];
        }
    }
}

#pragma mark - AirPlay

- (void)setupAirPlay
{
    if (_airPlayButton)
    {
        _volume.hidden = YES;
        [_airPlayButton insertSubview:_volume atIndex:0]; // important!

        _airPlayButton.enabled = NO;
        for (id current in _volume.subviews)
        {
            if([current isKindOfClass:[UIButton class]])
            {
                _airPlayInternalButton = (UIButton*)current;
                [_airPlayInternalButton addObserver:self forKeyPath:@"alpha" options:NSKeyValueObservingOptionNew context:AirPlayContext];
                break;
            }
        }
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(airPlayRouteChange:)
                                                     name:AVAudioSessionRouteChangeNotification
                                                   object:nil];
    }
}

- (void)deallocAirplay
{
    @try {
        [_airPlayInternalButton removeObserver:self forKeyPath:@"alpha"];
    } @catch (NSException *exception) {
        // NOP
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVAudioSessionRouteChangeNotification object:nil ];
    
    _isAirplayInUse = NO;
}

- (void)airPlayRouteChange:(NSNotification*)note
{
    BOOL inUse = [self checkAirPlayIsRunning];
    [self airPlayChangeInUseState:inUse];
}

- (BOOL)checkAirPlayIsRunning
{
    BOOL isActive = NO;
    
    NSArray *outputs = [AVAudioSession sharedInstance].currentRoute.outputs;
    for (AVAudioSessionPortDescription *outItem in outputs)
    {
        if([outItem.portType isEqualToString:AVAudioSessionPortAirPlay]) {
            _airPlayPlayerName = outItem.portName;
            isActive = YES;
            break;
        }
    }
    
    return isActive;
}

- (void)airPlayChangeInUseState:(BOOL)isInUse
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if(isInUse)
        {
            _isAirplayInUse = YES;
            _airPlayButton.selected = YES;
            
            if(_subtitlesLabel && _subtitles.subtitleItems.count > 0) {
                _subtitlesButton.enabled = NO;
                [self hideSubtitles];
            }
        }
        else
        {
            _isAirplayInUse = NO;
            _airPlayButton.selected = NO;
            
            if(_subtitlesLabel && _subtitles.subtitleItems.count > 0 && _subtitlesButton.selected) {
                _subtitlesButton.enabled = YES;
                [self showSubtitles];
            }
        }
        
        [self showPlayerBar];
        [self sendActionsForEvent:AVPlayerOverlayEventAirPlayInUse];

        [[NSNotificationCenter defaultCenter] postNotificationName:AVPlayerOverlayVCAirPlayInUseNotification
                                                            object:self
                                                          userInfo:@{kAVPlayerOverlayVCAirPlayInUse : @(_isAirplayInUse)}];
        
        if ([_delegate respondsToSelector:@selector(avPlayerOverlay:airPlayInUse:)])
            [_delegate avPlayerOverlay:self airPlayInUse:_isAirplayInUse];
    });
}

- (void)checkAirPlayRoutingViewVisible
{
    static BOOL routingVisible = NO;
    
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    _isAirPlayRoutingVisible = [self isAirPlayRoutingInView:window];
    if (_isAirPlayRoutingVisible != routingVisible) {
        routingVisible = _isAirPlayRoutingVisible;
        if (routingVisible == NO) {
            [self autoHidePlayerBar];
            return;
        }
    }

    [self performSelector:@selector(checkAirPlayRoutingViewVisible) withObject:nil afterDelay:1];
}

- (BOOL)isAirPlayRoutingInView:(UIView *)view
{
    BOOL ret = NO;
    for (id subview in view.subviews)
    {
        NSString *className = NSStringFromClass([subview class]);
        if ([className hasPrefix:@"MPAVRouting"]) {
            ret = YES;
            break;
        } else {
            ret = [self isAirPlayRoutingInView:subview];
            if (ret) break;
        }
    }
    
    return ret;
}

- (void)airplayBecomePresent
{
    _airPlayButton.enabled = YES;
    
    [self sendActionsForEvent:AVPlayerOverlayEventAirPlayBecomePresent];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:AVPlayerOverlayVCAirPlayBecomePresentNotification object:self];
    
    if ([_delegate respondsToSelector:@selector(avPlayerOverlay:airPlayBecomePresent:)])
        [_delegate avPlayerOverlay:self airPlayBecomePresent:nil];
}

- (void)airplayResignPresent
{
    _airPlayButton.enabled = NO;
    
    [self sendActionsForEvent:AVPlayerOverlayEventAirPlayResignPresent];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:AVPlayerOverlayVCAirPlayResignPresentNotification object:self];
    
    if ([_delegate respondsToSelector:@selector(avPlayerOverlay:airPlayResignPresent:)])
        [_delegate avPlayerOverlay:self airPlayResignPresent:nil];
}

#pragma mark - PIP

- (void)pipActivate
{
    [self pipActivateWithCompletion:nil];
}

- (void)pipActivateWithCompletion:(void(^)())completion;
{
    [UIView animateWithDuration:_pipAnimationDuration / 4.0 animations:^{
        self.view.alpha = 0.0;
    } completion:^(BOOL finished) {
        self.view.hidden = YES;
        
        UIViewController *parent = self.parentViewController; // AVPlayerViewController
        [self willPIPBecomeActivationViewController:parent];
        
        if (_mainWindow == nil)
            _mainWindow = [UIApplication sharedApplication].keyWindow;
        
        self.originalFrame = parent.view.frame;
        self.mainParent = parent.parentViewController;
        self.currentFrame = [parent.view convertRect:parent.view.frame toView:_mainWindow];
        self.containerView = parent.view.superview;
        self.navController = _mainParent.navigationController;
        
        [parent removeFromParentViewController];
        [parent.view removeFromSuperview];
        [parent willMoveToParentViewController:nil];
        
        parent.view.frame = _currentFrame;
        
        if (_isFullscreen) {
            [_window addSubview:parent.view];
        } else {
            [_mainWindow addSubview:parent.view];
        }
        
        parent.view.autoresizesSubviews = YES;
        parent.view.layer.zPosition = MAXFLOAT;
        [parent.view enableDragging];
        
        CGFloat scaleX = 1.0 / (_currentFrame.size.width / _pipSize.width);
        CGFloat scaleY = 1.0 / (_currentFrame.size.height / _pipSize.height);
        
        CGSize screen = [UIScreen mainScreen].bounds.size;
        CGPoint finalCenter = CGPointMake((screen.width - _pipSize.width / 2.0f - _pipPadding),
                                          (screen.height - _pipSize.height / 2.0f - _pipPadding));
        CGFloat deltaX = finalCenter.x - parent.view.center.x;
        CGFloat deltaY = finalCenter.y - parent.view.center.y;
        
        [self hideMainParentBeforePIPActivation];
        
        [UIView animateWithDuration:_pipAnimationDuration
                              delay:0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^(void){
                             parent.view.transform = CGAffineTransformMake(scaleX, 0.0f, 0.0f, scaleY, deltaX, deltaY);
                         }
                         completion:^(BOOL finished) {
                             
                             CGRect frame = parent.view.frame;
                             parent.view.transform = CGAffineTransformIdentity;
                             parent.view.frame = frame;
                             
                             if (_isFullscreen)
                             {
                                 [self willNormalScreenModeToParentViewController:parent];
                                 [UIView animateWithDuration:_pipAnimationDuration / 2.0 animations:^{
                                     _window.layer.backgroundColor = [UIColor clearColor].CGColor;
                                 } completion:^(BOOL finished) {
                                     [parent.view removeFromSuperview];
                                     _window.rootViewController = nil;
                                     
                                     [_mainWindow addSubview:parent.view];
                                     [_mainWindow makeKeyAndVisible];
                                     
                                     _fullscreenButton.transform = CGAffineTransformIdentity;
                                     _isFullscreen = NO;
                                     _window = nil;
                                     
                                     [self didNormalScreenModeToParentViewController:parent];
                                 }];
                             }
                             
                             [self didPIPBecomeActivationViewController:parent];
                             
                             if (completion)
                                 completion();
                         }];
    }];}

- (void)pipDeactivate
{
    [self pipDeactivateWithCompletion:nil];
}

- (void)pipDeactivateWithCompletion:(void(^)())completion;
{
    [self animmatedPIPDeactivationWithDuration:_pipAnimationDuration animation:^(UIViewController *parent) {
        parent.view.frame = _currentFrame;
    } completion:^(BOOL finished) {
       if (completion)
           completion();
    }];
}

- (void)showMainParentBeforePIPDeactivation
{
    if (![_navController.viewControllers isEqual:_mainParent])
    {
        CATransition *transition = [CATransition animation];
        transition.duration = _pipAnimationDuration / 2.0;
        transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        transition.type = kCATransitionFade;
        [_navController.view.layer addAnimation:transition forKey:nil];
        [_navController pushViewController:_mainParent animated:YES];
    }
}

- (void)hideMainParentBeforePIPActivation
{
    // remove container viewcontroller
    CATransition *transition = [CATransition animation];
    transition.duration = _pipAnimationDuration / 2.0;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.type = kCATransitionFade;
    [_mainParent.navigationController.view.layer addAnimation:transition forKey:nil];
    [_mainParent.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Device rotation

- (void)forceDeviceOrientation:(UIInterfaceOrientation)orientation
{
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
    [[UIDevice currentDevice] setValue:@(orientation) forKey:@"orientation"];
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
}

- (void)deviceOrientationDidChange:(NSNotification *)notification
{
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    if ((orientation) == UIDeviceOrientationFaceUp || (orientation) == UIDeviceOrientationFaceDown || (orientation) == UIDeviceOrientationUnknown || _currentOrientation == orientation) {
        return;
    }
    
    _currentOrientation = orientation;
    
    [[NSOperationQueue currentQueue] addOperationWithBlock:^{
        if (_autorotationMode == AVPlayerFullscreenAutorotationLandscapeMode) {
            // force fullscreen for landscape device rotation
            if (UIDeviceOrientationIsLandscape(orientation) && !_isFullscreen) {
                [self didFullscreenButtonSelected:nil];
            } else if (UIDeviceOrientationIsPortrait(orientation) && _isFullscreen) {
                [self didFullscreenButtonSelected:nil];
            }
        }
    }];
}


@end
