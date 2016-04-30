//
//  AVPlayerOverlayVC.h
//
//  Created by Danilo Priore on 28/04/16.
//  Copyright © 2016 Prioregroup.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AVPlayer;

@interface AVPlayerOverlayVC : UIViewController

@property (nonatomic, weak) IBOutlet UIView *playerBarView;
@property (nonatomic, weak) IBOutlet UIButton *playButton;
@property (nonatomic, weak) IBOutlet UIButton *playBigButton;
@property (nonatomic, weak) IBOutlet UIButton *volumeButton;
@property (nonatomic, weak) IBOutlet UIButton *fullscreenButton;
@property (nonatomic, weak) IBOutlet UISlider *videoSlider;
@property (nonatomic, weak) IBOutlet UISlider *volumeSlider;

@property (nonatomic, weak) AVPlayer *player;

@end
