//
//  AVPlayerPIPOverlayVC.h
//  AVPlayerOverlay
//
//  Created by Danilo Priore on 22/03/17.
//  Copyright © 2017 Danilo Priore. All rights reserved.
//

#import "AVPlayerOverlayViewController.h"

@class AVPlayer;
@protocol AVPlayerPIPOverlayVCDelegate;

IB_DESIGNABLE
@interface AVPlayerPIPOverlayVC : AVPlayerOverlayViewController

@property (nonatomic, weak) IBOutlet UIView *playerBarView;
@property (nonatomic, weak) IBOutlet UIButton *playButton;
@property (nonatomic, weak) IBOutlet UIButton *restoreButton;
@property (nonatomic, weak) IBOutlet UIButton *closeButton;

@property (nonatomic, assign) IBInspectable CGFloat animationDuration;

@property (nonatomic, weak) AVPlayer *player;

@property (nonatomic, assign) id<AVPlayerPIPOverlayVCDelegate> delegate;

- (void)didPlayButtonSelected:(id)sender;
- (void)didRestoreButtonSelected:(id)sender;
- (void)didCloseButtonSelected:(id)sender;

- (void)showControls;
- (void)hideControls;

@end

@protocol AVPlayerPIPOverlayVCDelegate <NSObject>

- (void)pipOverlayViewController:(UIViewController*)viewController willPIPClosed:(id)sender;
- (void)pipOverlayViewController:(UIViewController*)viewController willPIPDeactivation:(id)sender;

@end
