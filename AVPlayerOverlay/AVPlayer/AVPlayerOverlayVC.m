//
//  AVPlayerOverlayVC.m
//
//  Created by Danilo Priore on 28/04/16.
//  Copyright © 2016 Prioregroup.com. All rights reserved.
//
#define PLAYERBAR_AUTOHIDE 5.0

#import <AVFoundation/AVFoundation.h>
#import "AVPlayerOverlayVC.h"

@interface AVPlayerOverlayVC ()
{
    id timeObserver;
    BOOL isVideoSliderMoving;
}

@property (nonatomic, strong) UIWindow *window;

@end

@implementation AVPlayerOverlayVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.clipsToBounds = YES;
    self.view.backgroundColor = [UIColor clearColor];
    
    _volumeSlider.hidden = YES;
    _volumeSlider.transform = CGAffineTransformMakeRotation(-M_PI_2);
    
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
            
            typeof(self) wself = self;
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
        [UIView animateWithDuration:0.25
                         animations:^{
                             _playBigButton.alpha = 1.0;
                         }];

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

    typeof(self) wself = self;
    [self setConstraintValue:height
                forAttribute:NSLayoutAttributeBottom
                    duration:1.0 animations:^{
                        wself.volumeSlider.alpha = 0.0;
                    } completion:^(BOOL finished) {
                        wself.volumeSlider.hidden = YES;
                        wself.playerBarView.hidden = YES;
                    }];
}

- (void)showPlayerBar
{
    _playerBarView.hidden = NO;

    typeof(self) wself = self;
    [self setConstraintValue:0
                forAttribute:NSLayoutAttributeBottom
                    duration:0.5
                  animations:nil
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
        
        _playBigButton.alpha = 1.0;
        _playBigButton.hidden = NO;
        [UIView animateWithDuration:0.25
                         animations:^{
                             _playBigButton.alpha = 0.0;
                         } completion:^(BOOL finished) {
                             _playBigButton.hidden = YES;
                         }];
        
    } else {
        [_player pause];
        
        _playButton.selected = NO;
        
        _playBigButton.alpha = 0.0;
        _playBigButton.hidden = NO;
        [UIView animateWithDuration:0.25
                         animations:^{
                             _playBigButton.alpha = 1.0;
                         }];
    }
    
    [self autoHidePlayerBar];
}

- (void)didVolumeButtonSelected:(id)sender
{
    if (_volumeSlider.hidden)
    {
        _volumeSlider.alpha = 0.0;
        _volumeSlider.hidden = NO;
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
    static CGRect current_frame;
    static UIView *container_view;
    static UIViewController *original_parent;
    
    UIViewController *parent = self.parentViewController; // AVPlayerViewController
    UIWindow *mainWindow = [UIApplication sharedApplication].keyWindow;

    if (_window == nil)
    {
        original_parent = parent.parentViewController;
        current_frame = [parent.view convertRect:parent.view.frame toView:mainWindow];
        container_view = parent.view.superview;
        
        [parent removeFromParentViewController];
        [parent.view removeFromSuperview];
        [parent willMoveToParentViewController:nil];
        
        self.window = [[UIWindow alloc] initWithFrame:current_frame];
        _window.backgroundColor = [UIColor blackColor];
        _window.windowLevel = UIWindowLevelNormal;
        
        [_window.layer addSublayer:parent.view.layer];
        [_window makeKeyAndVisible];
        
        _window.rootViewController = parent;
        
        [UIView animateKeyframesWithDuration:0.5
                                       delay:0
                                     options:UIViewKeyframeAnimationOptionLayoutSubviews
                                  animations:^{
                                      _window.frame = mainWindow.bounds;
                                  } completion:^(BOOL finished) {
                                      _fullscreenButton.transform = CGAffineTransformMakeScale(-1.0, -1.0);
                                  }];
    } else {
        
        [UIView animateKeyframesWithDuration:0.5
                                       delay:0
                                     options:UIViewKeyframeAnimationOptionLayoutSubviews
                                  animations:^{
                                      _window.frame = current_frame;
                                  } completion:^(BOOL finished) {
                                      
                                      _window.rootViewController = nil;
                                      _fullscreenButton.transform = CGAffineTransformIdentity;

                                      [original_parent addChildViewController:parent];
                                      [container_view addSubview:parent.view];
                                      [parent didMoveToParentViewController:self];
                                      
                                      [_window removeFromSuperview], self.window = nil;
                                  }];
    }
    
    [self autoHidePlayerBar];
}

#pragma mark - Volume Slider

- (void)didVolumeSliderValueChanged:(id)sender
{
    _player.volume = ((UISlider*)sender).value;
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
