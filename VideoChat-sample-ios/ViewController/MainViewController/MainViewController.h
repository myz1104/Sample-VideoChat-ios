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


@interface MainViewController : UIViewController <QBChatDelegate, AVAudioPlayerDelegate,
AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate, UIAlertViewDelegate>{
    
    IBOutlet UIButton *callButton;
    IBOutlet UIActivityIndicatorView *callingActivityIndicator;
    IBOutlet UIActivityIndicatorView *startingCallActivityIndicator;
    IBOutlet UIImageView *opponentVideoView;
    IBOutlet UIImageView *myVideoView;
    IBOutlet UINavigationBar *navBar;
    
    AVAudioPlayer *ringingPlayer;
}
@property (retain) QBVideoChat		*videoChat;
@property (retain) NSString			*currentSessionID;
@property (retain) NSNumber			*userIDToCall;
@property (assign) int opponentID;
@property (retain) AVCaptureSession *captureSession;
@property (retain) UIAlertView		*callAlert;

- (IBAction)call:(id)sender;

@end
