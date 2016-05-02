//
//  AVPlayerVC.m
//
//  Created by Danilo Priore on 28/04/16.
//  Copyright © 2016 Prioregroup.com. All rights reserved.
//

#import <CoreMedia/CoreMedia.h>
#import <AVFoundation/AVFoundation.h>
#import "AVPlayerVC.h"
#import "AVPlayerOverlayVC.h"

@interface AVPlayerVC()

@property (nonatomic, strong) AVPlayerOverlayVC *overlayVC;

@end

@implementation AVPlayerVC

- (instancetype)init
{
    if (self = [super init]) {
        
        _overlayStoryboardId = @"AVPlayerOverlayVC";
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.showsPlaybackControls = NO;
    
    [[NSNotificationCenter defaultCenter] addObserverForName:AVPlayerVCSetVideoURLNotification
                                                      object:nil
                                                       queue:NULL
                                                  usingBlock:^(NSNotification * _Nonnull note) {
                                                      self.videoURL = note.object;
                                                  }];
    
    _overlayVC = [self.storyboard instantiateViewControllerWithIdentifier:_overlayStoryboardId];
    
    [self addChildViewController:_overlayVC];
    [self.view addSubview:_overlayVC.view];
    [_overlayVC didMoveToParentViewController:self];
    
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    _overlayVC.view.frame = self.view.bounds;
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
        
        self.player = [AVPlayer playerWithURL:videoURL];
    }
}

@end
