//
//  AVPlayerVC.m
//
//  Created by Danilo Priore on 28/04/16.
//  Copyright © 2016 Prioregroup.com. All rights reserved.
//
#define SYSTEM_VERSION_LESS_THAN(v) ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)

#import "AVPlayerVC.h"

@import CoreMedia;
@import AVFoundation;

@implementation AVPlayerVC

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        
        _videoBackground = NO;
        _overlayStoryboardId = @"AVPlayerOverlayVC";
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.showsPlaybackControls = NO;
    
    if (_videoBackground) {
        // audio/video background
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
        [[AVAudioSession sharedInstance] setActive:YES error:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationWillResignActiveNotification:)
                                                     name:UIApplicationWillResignActiveNotification
                                                   object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationWillEnterForegroundNotification:)
                                                     name:UIApplicationWillEnterForegroundNotification
                                                   object:nil];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(avPlayerVCSetVideoURLNotification:)
                                                 name:AVPlayerVCSetVideoURLNotification
                                               object:nil];

    _overlayVC = [self.storyboard instantiateViewControllerWithIdentifier:_overlayStoryboardId];
    
    [self addChildViewController:_overlayVC];
    [self.view addSubview:_overlayVC.view];
    [_overlayVC didMoveToParentViewController:self];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    [self becomeFirstResponder];
    
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
    [self resignFirstResponder];
    
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    _overlayVC.view.frame = self.view.bounds;
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (void)setPlayer:(AVPlayer *)player
{
    [super setPlayer:player];
    
    _overlayVC.player = self.player;
}

- (void)setVideoURL:(NSURL *)videoURL
{
    @synchronized (self) {
        _videoURL = videoURL;

        if (_videoURL != nil) {
            
            AVAsset *asset = [self.player.currentItem asset];
            if ([asset isKindOfClass:[AVURLAsset class]]) {
                NSURL *current_url = [(AVURLAsset*)asset URL];
                if ([current_url.absoluteString isEqualToString:_videoURL.absoluteString])
                    return;
            }
            
            NSDictionary *options = _userAgent.length > 0 ? @{@"AVURLAssetHTTPHeaderFieldsKey" : @{@"User-Agent": _userAgent}} : nil;
            AVURLAsset *url_asset = [AVURLAsset URLAssetWithURL:_videoURL options:options];
            AVPlayerItem *item = [AVPlayerItem playerItemWithAsset:url_asset];
            
            // workaround for iOS 8.0 video error -11800
            if(self.player == nil || SYSTEM_VERSION_LESS_THAN(@"9.0")) {
                self.player = [AVPlayer playerWithPlayerItem:item];
            } else {
                [self.player replaceCurrentItemWithPlayerItem:item];
            }
        } else {
            [self.player replaceCurrentItemWithPlayerItem:nil];
        }
        
    }
}

- (void)remoteControlReceivedWithEvent:(UIEvent *)event
{
    
#ifdef DEBUG
    NSLog(@"Remote control event %i subtype %i", (int)event.type, (int)event.subtype);
#endif

    if (event.type == UIEventTypeRemoteControl && self.player) {
        switch (event.subtype) {
            case UIEventSubtypeRemoteControlPlay:
            case UIEventSubtypeRemoteControlPause:
            case UIEventSubtypeRemoteControlStop:
            case UIEventSubtypeRemoteControlTogglePlayPause:
                [_overlayVC didPlayButtonSelected:self];
                break;
            default:
                break;
        }
    }
}

- (void)dealloc
{
    _overlayVC = nil;
    
    [self.player pause], self.player = nil;
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Video (only audio) on background

- (void)playInBackground:(BOOL)play
{
    static BOOL isPlay;
    
    isPlay = self.player.rate != 0;
    AVPlayerItem *playerItem = [self.player currentItem];
    
    NSArray *tracks = [playerItem tracks];
    for (AVPlayerItemTrack *playerItemTrack in tracks)
    {
        // find video tracks
        if ([playerItemTrack.assetTrack hasMediaCharacteristic:AVMediaCharacteristicVisual])
        {
            playerItemTrack.enabled = !play;
            break;
        }
    }
    
    if (isPlay)
        [self.player performSelector:@selector(play) withObject:nil afterDelay:1.0];
}

#pragma mark - Notifications

- (void)applicationWillResignActiveNotification:(NSNotification*)note
{
    [self playInBackground:YES];
}

- (void)applicationWillEnterForegroundNotification:(NSNotification*)note
{
    [self playInBackground:NO];
}

- (void)avPlayerVCSetVideoURLNotification:(NSNotification*)note
{
    self.videoURL = note.object;
    [_overlayVC loadSubtitlesWithURL:note.userInfo[kAVPlayerVCSubtitleURL]];
}

@end
