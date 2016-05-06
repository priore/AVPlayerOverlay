//
//  AVPlayerOverlayVC.m
//
//  Created by Danilo Priore on 28/04/16.
//  Copyright © 2016 Prioregroup.com. All rights reserved.
//
#define PLAYERBAR_AUTOHIDE 5.0

#import "AVPlayerOverlayVC.h"

@import AVFoundation;
@import MediaPlayer;

@interface AVPlayerOverlayVC ()
{
    id timeObserver;
    BOOL isVideoSliderMoving;
}

@property (nonatomic, weak) UIView *containerView;
@property (nonatomic, weak) UIWindow *mainWindow;
@property (nonatomic, weak) UIViewController *mainParent;
@property (nonatomic, weak) UISlider *mpSlider;

@property (nonatomic, assign) BOOL statusBarHidden;
@property (nonatomic, assign) BOOL navbarHidden;
@property (nonatomic, assign) CGRect currentFrame;

@property (nonatomic, strong) UIWindow *window;
@property (nonatomic, strong) MPVolumeView *volume;

@end

@implementation AVPlayerOverlayVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.clipsToBounds = YES;
    self.view.backgroundColor = [UIColor clearColor];
    
    // system volume
    self.volume = [[MPVolumeView alloc] initWithFrame:CGRectZero];
    for (id view in _volume.subviews) {
        if ([view isKindOfClass:[UISlider class]]) {
            _mpSlider = view;
            break;
        }
    }
    
    _volumeSlider.hidden = YES;
    _volumeSlider.transform = CGAffineTransformMakeRotation(-M_PI_2);
    _volumeSlider.value = [AVAudioSession sharedInstance].outputVolume;
    
    _playBigButton.layer.borderWidth = 1.0;
    _playBigButton.layer.borderColor = [UIColor whiteColor].CGColor;
    _playBigButton.layer.cornerRadius = _playBigButton.frame.size.width / 2.0;
    
    [self videoSliderEnabled:NO];
    
    // actions
    [_playButton addTarget:self action:@selector(didPlayButtonSelected:) forControlEvents:UIControlEventTouchUpInside];
    [_volumeButton addTarget:self action:@selector(didVolumeButtonSelected:) forControlEvents:UIControlEventTouchUpInside];
    [_fullscreenButton addTarget:self action:@selector(didFullscreenButtonSelected:) forControlEvents:UIControlEventTouchUpInside];
    [_playBigButton addTarget:self action:@selector(didPlayButtonSelected:) forControlEvents:UIControlEventTouchUpInside];
    [_videoSlider addTarget:self action:@selector(didVideoSliderTouchUp:) forControlEvents:UIControlEventTouchUpInside];
    [_videoSlider addTarget:self action:@selector(didVideoSliderTouchDown:) forControlEvents:UIControlEventTouchDown];
    [_volumeSlider addTarget:self action:@selector(didVolumeSliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    
    // tap gesture
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapGesture:)];
    [self.view addGestureRecognizer:tap];
    
    [self.view layoutIfNeeded];
    [self autoHidePlayerBar];
}

- (void)dealloc
{
    _volume = nil;

    [_window removeFromSuperview], _window = nil;
    [_mainWindow makeKeyAndVisible];
}

- (void)setPlayer:(AVPlayer *)player
{
    @synchronized (self) {
        _player = player;

        if (_player == nil) {
            
            if (timeObserver)
                [_player removeTimeObserver:timeObserver];
            
            _volumeSlider.value = 1.0;
            _videoSlider.value = 0.0;

        } else {
            
            __weak typeof(self) wself = self;
            timeObserver =  [self.player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(1.0 / 60.0, NSEC_PER_SEC)
                                                                      queue:NULL
                                                                 usingBlock:^(CMTime time){
                                                                     [wself updateProgressBar];
                                                                 }];
            _videoSlider.value = 0;
            _volumeSlider.value = _player.volume;
        }
        
        _playButton.selected = NO;
        _playBigButton.hidden = NO;
        _playBigButton.selected = NO;

        [self showPlayerBar];
        [self autoHidePlayerBar];
        [self videoSliderEnabled:NO];
    }
}

- (void)updateProgressBar
{
    Float64 duration = CMTimeGetSeconds(_player.currentItem.duration);
    if (!isVideoSliderMoving && !isnan(duration)) {
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
}

#pragma mark - PlayerBar

- (void)autoHidePlayerBar
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hidePlayerBar) object:nil];
    [self performSelector:@selector(hidePlayerBar) withObject:nil afterDelay:PLAYERBAR_AUTOHIDE];
}

- (void)hidePlayerBar
{
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

- (void)didTapGesture:(id)sender
{
    if (_playerBarView.hidden)
    {
        [self showPlayerBar];
    }
    else if (_volumeSlider.hidden)
    {
        [self didPlayButtonSelected:sender];
    }
}

- (void)didPlayButtonSelected:(id)sender
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
        self.statusBarHidden = [UIApplication sharedApplication].isStatusBarHidden;
        self.mainParent = parent.parentViewController;
        self.currentFrame = [parent.view convertRect:parent.view.frame toView:_mainWindow];
        self.containerView = parent.view.superview;
        self.navbarHidden = parent.navigationController.isNavigationBarHidden;
        
        [parent removeFromParentViewController];
        [parent.view removeFromSuperview];
        [parent willMoveToParentViewController:nil];
        
        self.window = [[UIWindow alloc] initWithFrame:_currentFrame];
        _window.backgroundColor = [UIColor blackColor];
        _window.windowLevel = UIWindowLevelNormal;
        
        [_window.layer addSublayer:parent.view.layer];
        [_window makeKeyAndVisible];
        
        _window.rootViewController = parent;
        
        [self didFullScreenModeFromParentViewController:parent];
        
        [UIView animateKeyframesWithDuration:0.5
                                       delay:0
                                     options:UIViewKeyframeAnimationOptionLayoutSubviews
                                  animations:^{
                                      _window.frame = _mainWindow.bounds;
                                  } completion:^(BOOL finished) {
                                      _fullscreenButton.transform = CGAffineTransformMakeScale(-1.0, -1.0);
                                      _isFullscreen = YES;
                                  }];
        
        [self.navigationController setNavigationBarHidden:YES animated:YES];
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
        
    } else {
        
        [self didNormalScreenModeToParentViewController:parent];
        
        [UIView animateKeyframesWithDuration:0.5
                                       delay:0
                                     options:UIViewKeyframeAnimationOptionLayoutSubviews
                                  animations:^{
                                      _window.frame = _currentFrame;
                                  } completion:^(BOOL finished) {
                                      
                                      _window.rootViewController = nil;
                                      _fullscreenButton.transform = CGAffineTransformIdentity;

                                      [_mainParent addChildViewController:parent];
                                      [_containerView addSubview:parent.view];
                                      [parent didMoveToParentViewController:_mainParent];
                                      
                                      [_window removeFromSuperview], _window = nil;
                                      [_mainWindow makeKeyAndVisible];
                                      
                                      _isFullscreen = NO;
                                  }];
        
        [self.navigationController setNavigationBarHidden:_navbarHidden animated:YES];
        [[UIApplication sharedApplication] setStatusBarHidden:_statusBarHidden withAnimation:UIStatusBarAnimationSlide];
        
    }
    
    [self autoHidePlayerBar];
}

#pragma mark - Overridable Methods

- (void)didFullScreenModeFromParentViewController:(UIViewController*)parent
{
    
}

- (void)didNormalScreenModeToParentViewController:(UIViewController*)parent
{
    
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
    
    isVideoSliderMoving = NO;
    [self autoHidePlayerBar];
}

- (void)didVideoSliderTouchDown:(id)sender
{
    isVideoSliderMoving = YES;
    [self autoHidePlayerBar];
}

- (void)videoSliderEnabled:(BOOL)enabled
{
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

@end
