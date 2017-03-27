//
//  AVPlayerPIPOverlayVC.m
//  AVPlayerOverlay
//
//  Created by Danilo Priore on 22/03/17.
//  Copyright © 2017 Danilo Priore. All rights reserved.
//

#import "AVPlayerPIPOverlayVC.h"
#import "AVPlayerOverlayVC.h"

@import AVFoundation;
@import MediaPlayer;

@interface AVPlayerPIPOverlayVC ()

@end

@implementation AVPlayerPIPOverlayVC

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        
        _animationDuration = 0.3;
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
        
        if ([_delegate respondsToSelector:@selector(pipOverlayViewController:willPIPClosed:)])
            [_delegate pipOverlayViewController:self willPIPClosed:self.parentViewController];
        
        [parent.view removeFromSuperview], parent = nil; // release memory
    }];
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
