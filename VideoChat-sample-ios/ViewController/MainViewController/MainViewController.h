//
//  MainViewController.h
//  SimpleSample-videochat-ios
//
//  Created by QuickBlox team on 1/02/13.
//  Copyright (c) 2013 QuickBlox. All rights reserved.
//
//
// This class demonstrates how to work with VideoChat API.
// It shows how to setup video conference between 2 users
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@class QBVideoView;
@interface MainViewController : UIViewController <QBChatDelegate, AVAudioPlayerDelegate, UIAlertViewDelegate>{
    IBOutlet UIButton *callButton;
    IBOutlet UILabel *ringigngLabel;
    IBOutlet UIActivityIndicatorView *callingActivityIndicator;
    IBOutlet UIActivityIndicatorView *startingCallActivityIndicator;
    IBOutlet QBVideoView *opponentVideoView;
    IBOutlet QBVideoView *myVideoView;
    IBOutlet UINavigationBar *navBar;
    IBOutlet UISegmentedControl *audioOutput;
    IBOutlet UISegmentedControl *videoOutput;
    
    AVAudioPlayer *ringingPlayer;
    
    //
    NSUInteger videoChatOpponentID;
    enum QBVideoChatConferenceType videoChatConferenceType;
    NSString *sessionID;
}

@property (retain) NSNumber *opponentID;
@property (retain) QBWebRTCVideoChat *videoChat;
@property (retain) UIAlertView *callAlert;

- (IBAction)call:(id)sender;
- (void)reject;
- (void)accept;

@end
