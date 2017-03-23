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
    
    // PIP active/deactive notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didPipBecomeActiveNotification:) name:AVPlayerOverlayVCPIPDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willPipDeactivationNotification:) name:AVPlayerOverlayVCPIPWillDeactivationNotification object:nil];
    
}

- (void)dealloc
{
    _player = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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
    [[NSNotificationCenter defaultCenter] postNotificationName:AVPlayerPIPOverlayVCwillPIPDeactivationNotification object:self];
}

- (void)didCloseButtonSelected:(id)sender
{
    __block UIViewController *parent = self.parentViewController; // AVPlayerViewController
    [UIView animateWithDuration:_animationDuration animations:^{
        parent.view.alpha = 0.0;
    } completion:^(BOOL finished) {
        // release memory
        [parent.view removeFromSuperview], parent = nil;
    }];
}

#pragma mark - Notifications

- (void)didPipBecomeActiveNotification:(NSNotification*)note
{
    // show controls
    self.view.hidden = NO;
    [UIView animateWithDuration:_animationDuration animations:^{
        self.view.alpha = 1.0;
    }];
}

- (void)willPipDeactivationNotification:(NSNotification*)note
{
    // hide controls
    [UIView animateWithDuration:_animationDuration animations:^{
        self.view.alpha = 0.0;
    } completion:^(BOOL finished) {
        self.view.hidden = YES;
    }];
}


@end
