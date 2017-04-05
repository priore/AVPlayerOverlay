//
//  AVPlayerOverlayAction.h
//  AVPlayerOverlay
//
//  Created by Danilo Priore on 27/03/17.
//  Copyright © 2017 Danilo Priore. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_OPTIONS(NSUInteger, AVPlayerOverlayEvents) {
    AVPlayerOverlayEventWillFullScreenMode,
    AVPlayerOverlayEventDidFullScreenMode,
    AVPlayerOverlayEventWillNormalScreenMode,
    AVPlayerOverlayEventDidNormalScreenMode,
    AVPlayerOverlayEventAirPlayInUse,
    AVPlayerOverlayEventAirPlayBecomePresent,
    AVPlayerOverlayEventAirPlayResignPresent,
    AVPlayerOverlayEventWillPIPBecomeActive,
    AVPlayerOverlayEventDidPIPBecomeActive,
    AVPlayerOverlayEventWillPIPDeactivation,
    AVPlayerOverlayEventDidPIPDeactivation,
    AVPlayerOverlayEventPIPDeactivationRequest,
    AVPlayerOverlayEventPIPClosed,
    AVPlayerOverlayEventPeriodicTimeObserver
};

@interface AVPlayerOverlayAction : NSObject

@property (nonatomic, weak) id target;
@property (nonatomic, assign) SEL action;
@property (nonatomic, assign) AVPlayerOverlayEvents event;

@end
