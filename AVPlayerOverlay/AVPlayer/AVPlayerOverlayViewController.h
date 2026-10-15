//
//  AVPlayerOverlayViewController.h
//  AVPlayerOverlay
//
//  Created by Priore on 27/03/17.
//  Copyright © 2017 Priore. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AVPlayerOverlayAction.h"

@interface AVPlayerOverlayViewController : UIViewController

- (void)addTarget:(id)target action:(SEL)action forEvents:(AVPlayerOverlayEvents)event;
- (void)sendActionsForEvent:(AVPlayerOverlayEvents)event;
- (void)sendActionsForEvent:(AVPlayerOverlayEvents)event object:(id)object;

@end
