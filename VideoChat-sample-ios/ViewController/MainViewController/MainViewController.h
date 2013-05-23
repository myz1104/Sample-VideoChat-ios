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
AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate>{
    
    IBOutlet UIButton *callButton;
    IBOutlet UIButton *callAcceptButton;
    IBOutlet UIButton *callRejectButton;
    IBOutlet UILabel *ringigngLabel;
    IBOutlet UIActivityIndicatorView *callingActivityIndicator;
    IBOutlet UIActivityIndicatorView *startingCallActivityIndicator;
    IBOutlet UIImageView *opponentVideoView;
    IBOutlet UIImageView *myVideoView;
    IBOutlet UINavigationBar *navBar;
    
    AVAudioPlayer *ringingPlayer;
    
    QBVideoChat *videoChat;
}

@property (retain) NSNumber *opponentID;
@property (retain) AVCaptureSession *captureSession;

- (IBAction)call:(id)sender;
- (IBAction)reject:(id)sender;
- (IBAction)accept:(id)sender;

@end
