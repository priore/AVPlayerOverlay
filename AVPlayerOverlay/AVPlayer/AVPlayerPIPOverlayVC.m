//
//  AVPlayerPIPOverlayVC.m
//  AVPlayerOverlay
//
//  Created by Danilo Priore on 22/03/17.
//  Copyright © 2017 Danilo Priore. All rights reserved.
//

#import "AVPlayerPIPOverlayVC.h"
#import "AVPlayerOverlayVC.h"
#import "SubtitlePackage.h"

@import AVFoundation;
@import MediaPlayer;

@interface AVPlayerPIPOverlayVC ()

@property (nonatomic, assign) BOOL isVideoSliderMoving;

@end

@implementation AVPlayerPIPOverlayVC

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        
        _animationDuration = 0.3;
        _isVideoSliderMoving = NO;
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.alpha = 0.0;
    self.view.hidden = YES;
    self.view.backgroundColor = [UIColor clearColor];
    
    [_playButton addTarget:self action:@selector(didPlayButtonSelected:) forControlEvents:UIControlEventTouchUpInside];
    [_restoreButton addTarget:self action:@selector(didRestoreButtonSelected:) forControlEvents:UIControlEventTouchUpInside];
    [_closeButton addTarget:self action:@selector(didCloseButtonSelected:) forControlEvents:UIControlEventTouchUpInside];
    [_videoSlider addTarget:self action:@selector(didVideoSliderTouchUp:) forControlEvents:UIControlEventTouchUpInside];
    [_videoSlider addTarget:self action:@selector(didVideoSliderTouchDown:) forControlEvents:UIControlEventTouchDown];

    // double tap gesture for restore
    UITapGestureRecognizer *doubleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didRestoreButtonSelected:)];
    doubleTapGesture.numberOfTapsRequired = 2;
    [self.view addGestureRecognizer:doubleTapGesture];
    
}

- (void)dealloc
{
    _player = nil;
    _delegate = nil;
}

#pragma mark - Properties

- (void)setPlayer:(AVPlayer *)player
{
    @synchronized (self) {
        _player = player;
        
        _videoSlider.value = 0;
        _playButton.enabled = _player != nil;
        _playButton.selected = NO;
        
        [self videoSliderEnabled:NO];
    }
}

#pragma mark - Publich Methods

- (void)setCurrentTimeValue:(CMTime)time
{
    if (_currentTimeLabel) {
        _currentTimeLabel.text = CMTIME_IS_VALID(time) ? [SubtitlePackage makeSaveName:time] : nil;
    }
    
    Float64 duration = CMTimeGetSeconds(_player.currentItem.duration);
    if (!_isVideoSliderMoving && !isnan(duration)) {
        _videoSlider.maximumValue = duration;
        _videoSlider.value = CMTimeGetSeconds(_player.currentTime);
        
        [self videoSliderEnabled:YES];
    } else if (_videoSlider.isUserInteractionEnabled) {
        
        [self videoSliderEnabled:NO];
    }
}

#pragma mark - Actions

- (void)didPlayButtonSelected:(id)sender
{
    if (_player.currentItem != nil)
    {
        if (_player.rate == 0)
        {
            [_player play];
            _playButton.selected = YES;
            
        } else {
            [_player pause];
            _playButton.selected = NO;
            
        }
    }
}

- (void)didRestoreButtonSelected:(id)sender
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self sendActionsForEvent:AVPlayerOverlayEventPIPDeactivationRequest];

    if ([_delegate respondsToSelector:@selector(pipOverlayViewController:willPIPDeactivation:)])
        [_delegate pipOverlayViewController:self willPIPDeactivation:self.parentViewController];
}

- (void)didCloseButtonSelected:(id)sender
{
    __block UIViewController *parent = self.parentViewController; // AVPlayerViewController
    [UIView animateWithDuration:_animationDuration animations:^{
        parent.view.alpha = 0.0;
    } completion:^(BOOL finished) {
        
        [self sendActionsForEvent:AVPlayerOverlayEventPIPClosed];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:AVPlayerOverlayPIPClosedNotification object:self];
        
        if ([_delegate respondsToSelector:@selector(pipOverlayViewController:willPIPClosed:)])
            [_delegate pipOverlayViewController:self willPIPClosed:self.parentViewController];
        
        [parent.view removeFromSuperview], parent = nil; // release memory
    }];
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
}

- (void)didVideoSliderTouchDown:(id)sender
{
    _isVideoSliderMoving = YES;
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

#pragma mark - Events

- (void)showControls
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didCloseButtonSelected:) name:AVPlayerOverlayVCWillPIPBecomeActiveNotification object:nil];

    // show controls
    self.view.hidden = NO;
    [UIView animateWithDuration:_animationDuration animations:^{
        self.view.alpha = 1.0;
    }];
}

- (void)hideControls
{
    // hide controls
    [UIView animateWithDuration:_animationDuration animations:^{
        self.view.alpha = 0.0;
    } completion:^(BOOL finished) {
        self.view.hidden = YES;
    }];
}


@end
