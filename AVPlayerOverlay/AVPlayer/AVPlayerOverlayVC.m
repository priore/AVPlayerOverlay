//
//  AVPlayerOverlayVC.m
//
//  Created by Danilo Priore on 28/04/16.
//  Copyright © 2016 Prioregroup.com. All rights reserved.
//
#import "AVPlayerOverlayVC.h"
#import "SubtitlePackage.h"

@import AVFoundation;
@import MediaPlayer;

@interface AVPlayerOverlayVC ()

@property (nonatomic, weak) UIView *containerView;
@property (nonatomic, weak) UIWindow *mainWindow;
@property (nonatomic, weak) UIViewController *mainParent;
@property (nonatomic, weak) UISlider *mpSlider;
@property (nonatomic, weak) UIButton *airPlayInternalButton;

@property (nonatomic, assign) CGRect currentFrame;

@property (nonatomic, strong) UIWindow *window;
@property (nonatomic, strong) MPVolumeView *volume;

@property (nonatomic, strong) id timeObserver;

@property (nonatomic, assign) BOOL isVideoSliderMoving;
@property (nonatomic, assign) BOOL isAirPlayRoutingVisible;

@property (nonatomic, assign) BOOL hiddenStatusBar;
@property (nonatomic, assign) BOOL hiddenNavBar;

@property (nonatomic, assign) UIDeviceOrientation currentOrientation;

@property (nonatomic, strong) SubtitlePackage *subtitles;

@end

@implementation AVPlayerOverlayVC

static void *AirPlayContext = &AirPlayContext;

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        
        _isFullscreen = NO;
        _isVideoSliderMoving = NO;
        _playBarAutoideInterval = 5.0;
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
    _playBigButton.enabled = NO;
    _playBigButton.layer.borderWidth = 1.0;
    _playBigButton.layer.borderColor = [UIColor whiteColor].CGColor;
    _playBigButton.layer.cornerRadius = _playBigButton.frame.size.width / 2.0;
    
    _subtitlesLabel.hidden = YES;
    _subtitlesLabel.numberOfLines = 0;
    _subtitlesLabel.contentMode = UIViewContentModeBottom;
    _subtitlesLabel.baselineAdjustment = UIBaselineAdjustmentAlignBaselines;
    _subtitlesButton.enabled = NO;
    
    [self videoSliderEnabled:NO];
    [self setupAirPlay];
    
    // actions
    [_playButton addTarget:self action:@selector(didPlayButtonSelected:) forControlEvents:UIControlEventTouchUpInside];
    [_volumeButton addTarget:self action:@selector(didVolumeButtonSelected:) forControlEvents:UIControlEventTouchUpInside];
    [_fullscreenButton addTarget:self action:@selector(didFullscreenButtonSelected:) forControlEvents:UIControlEventTouchUpInside];
    [_playBigButton addTarget:self action:@selector(didPlayButtonSelected:) forControlEvents:UIControlEventTouchUpInside];
    [_videoSlider addTarget:self action:@selector(didVideoSliderTouchUp:) forControlEvents:UIControlEventTouchUpInside];
    [_videoSlider addTarget:self action:@selector(didVideoSliderTouchDown:) forControlEvents:UIControlEventTouchDown];
    [_volumeSlider addTarget:self action:@selector(didVolumeSliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    [_subtitlesButton addTarget:self action:@selector(didSubtitlesButtonSelected:) forControlEvents:UIControlEventTouchUpInside];
    [_airPlayButton addTarget:self action:@selector(didAirPlayButtonSelected:) forControlEvents:UIControlEventTouchUpInside];
    
    // tap gesture for hide/show player bar
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapGesture:)];
    [self.view addGestureRecognizer:tap];
    
    // double tap gesture for normal and fullscreen
    UITapGestureRecognizer *doubleTapGesture=[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didDoubleTapGesture:)];
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
    [NSObject cancelPreviousPerformRequestsWithTarget:self];

    if (_timeObserver)
        [_player removeTimeObserver:_timeObserver];
    _timeObserver = nil;

    _volume = nil;
    _player = nil;

    [_window removeFromSuperview], _window = nil;
    [_mainWindow makeKeyAndVisible];
    
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
}

- (void)setPlayer:(AVPlayer *)player
{
    @synchronized (self) {
        _player = player;

        if (_player == nil) {
            
            if (_timeObserver)
                [_player removeTimeObserver:_timeObserver];
            _timeObserver = nil;
            
            _volumeSlider.value = 1.0;
            _videoSlider.value = 0.0;
            _playButton.enabled = NO;
            _playBigButton.enabled = NO;

        } else {
            
            if (_durationTimeLabel) {
                CMTime duration = [self playerItemDuration];
                _durationTimeLabel.text = CMTIME_IS_VALID(duration) ? [_subtitles makeSaveName:duration] : nil;
            }
            
            __weak typeof(self) wself = self;
            self.timeObserver =  [_player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(0.5, NSEC_PER_SEC)
                                                                       queue:NULL
                                                                  usingBlock:^(CMTime time){
                                                                      
                                                                      [wself updateProgressBar];
                                                                      
                                                                      if (wself.currentTimeLabel)
                                                                          wself.currentTimeLabel.text = CMTIME_IS_VALID(time) ? [wself.subtitles makeSaveName:time] : nil;
                                                                      
                                                                      if (!wself.subtitlesLabel.hidden && wself.subtitles.subtitleItems.count > 0)
                                                                      {
                                                                          NSInteger index = [wself.subtitles indexOfProperSubtitleWithGivenCMTime:time];
                                                                          IndividualSubtitle *subtitle = wself.subtitles.subtitleItems[index];
                                                                          wself.subtitlesLabel.attributedText = [wself attributedSubtitle:subtitle];
                                                                          [wself.subtitlesLabel setNeedsDisplay];
                                                                      }
                                                                      
                                                                  }];
            _videoSlider.value = 0;
            _volumeSlider.value = _player.volume;
            _playButton.enabled = YES;
            _playBigButton.enabled = YES;
        }
        
        _playButton.selected = NO;
        _playBigButton.hidden = NO;
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

#pragma mark - Observe

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == AirPlayContext) {
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
                    duration:1.0
                  animations:^{
                      wself.volumeSlider.alpha = 0.0;
                      wself.playBigButton.alpha = 0.0;
                  } completion:^(BOOL finished) {
                      wself.volumeSlider.hidden = YES;
                      wself.playerBarView.hidden = YES;
                      wself.playBigButton.hidden = YES;
                  }];
}

- (void)showPlayerBar
{
    _playerBarView.hidden = NO;
    _playBigButton.hidden = NO;
    
    __weak typeof(self) wself = self;
    [self setConstraintValue:0
                forAttribute:NSLayoutAttributeBottom
                    duration:0.5
                  animations:^{
                      wself.playBigButton.alpha = 1.0;
                  }
                  completion:^(BOOL finished) {
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
        [UIView animateWithDuration:0.25
                         animations:^{
                             _volumeSlider.alpha = 1.0;
                         }];
        
    }
    else
    {
        _volumeSlider.alpha = 1.0;
        [UIView animateWithDuration:0.25
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
        self.mainWindow = [UIApplication sharedApplication].keyWindow;

    if (_window == nil)
    {
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
        [UIView animateKeyframesWithDuration:0.5
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
        
        [self willNormalScreenModeToParentViewController:parent];
        
        _window.frame = _mainWindow.bounds;
        [UIView animateKeyframesWithDuration:0.5
                                       delay:0
                                     options:UIViewKeyframeAnimationOptionLayoutSubviews
                                  animations:^{
                                      _window.frame = _currentFrame;
                                  } completion:^(BOOL finished) {
                                      
                                      [parent.view removeFromSuperview];
                                      _window.rootViewController = nil;
                                      
                                      [_mainParent addChildViewController:parent];
                                      [_containerView addSubview:parent.view];
                                      parent.view.frame = _containerView.bounds;
                                      [parent didMoveToParentViewController:_mainParent];
                                      
                                      [_mainWindow makeKeyAndVisible];
                                      
                                      _fullscreenButton.transform = CGAffineTransformIdentity;
                                      _isFullscreen = NO;
                                      _window = nil;
                                      
                                      [self didNormalScreenModeToParentViewController:parent];
                                  }];
        
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

#pragma mark - Overridable Methods

- (void)willFullScreenModeFromParentViewController:(UIViewController*)parent
{
    _hiddenNavBar = self.navigationController.isNavigationBarHidden;
    _hiddenStatusBar = [UIApplication sharedApplication].isStatusBarHidden;
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

    [[NSNotificationCenter defaultCenter] postNotificationName:AVPlayerOverlayVCFullScreenNotification object:self];
}

- (void)willNormalScreenModeToParentViewController:(UIViewController*)parent
{
        if (_autorotationMode == AVPlayerFullscreenAutorotationLandscapeMode)
            [self forceDeviceOrientation:UIInterfaceOrientationPortrait];
    
    [[UIApplication sharedApplication] setStatusBarHidden:_hiddenStatusBar withAnimation:UIStatusBarAnimationFade];
    [self.navigationController setNavigationBarHidden:_hiddenNavBar animated:YES];
}

- (void)didNormalScreenModeToParentViewController:(UIViewController*)parent
{
    if (_autorotationMode == AVPlayerFullscreenAutorotationLandscapeMode)
        [self forceDeviceOrientation:UIInterfaceOrientationPortrait];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:AVPlayerOverlayVCNormalScreenNotification object:self];
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
    [UIView animateWithDuration:.25 animations:^{
        _subtitlesLabel.alpha = 1.0;
    }];
}

- (void)hideSubtitles
{
    [UIView animateWithDuration:.25 animations:^{
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

- (CMTime)playerItemDuration
{
    if (_player.currentItem && _player.currentItem.asset) {
        if (_player.currentItem.status == AVPlayerItemStatusReadyToPlay && !CMTIME_IS_INDEFINITE(_player.currentItem.asset.duration)) {
            return _player.currentItem.asset.duration;
        }
    }
    
    return kCMTimeInvalid;
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

        [[NSNotificationCenter defaultCenter] postNotificationName:AVPlayerOverlayVCAirPlayInUseNotification
                                                            object:self
                                                          userInfo:@{kAVPlayerOverlayVCAirPlayInUse : @(_isAirplayInUse)}];
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
    [[NSNotificationCenter defaultCenter] postNotificationName:AVPlayerOverlayVCAirPlayBecomePresentNotification object:self];
}

- (void)airplayResignPresent
{
    _airPlayButton.enabled = NO;
    [[NSNotificationCenter defaultCenter] postNotificationName:AVPlayerOverlayVCAirPlayResignPresentNotification object:self];
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
