//
//  MainViewController.m
//  SimpleSample-videochat-ios
//
//  Created by QuickBlox team on 1/02/13.
//  Copyright (c) 2013 QuickBlox. All rights reserved.
//

#import "MainViewController.h"
#import "AppDelegate.h"

@interface MainViewController ()
@end
@implementation MainViewController


@synthesize opponentID;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)dealloc{
    [opponentID release];
    
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    opponentVideoView.layer.borderWidth = 1;
    opponentVideoView.layer.borderColor = [[UIColor grayColor] CGColor];
    opponentVideoView.layer.cornerRadius = 5;
    
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    navBar.topItem.title = appDelegate.currentUser == 1 ? @"User 1" : @"User 2";
    [callButton setTitle:appDelegate.currentUser == 1 ? @"Call User2" : @"Call User1" forState:UIControlStateNormal];
}

- (void)viewDidUnload{
    callButton = nil;
    callAcceptButton = nil;
    callRejectButton = nil;
    ringigngLabel = nil;
    callingActivityIndicator = nil;
    myVideoView = nil;
    opponentVideoView = nil;
    navBar = nil;
    startingCallActivityIndicator = nil;
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    // Start sending chat presence
    //
    [QBChat instance].delegate = self;
    [NSTimer scheduledTimerWithTimeInterval:30 target:[QBChat instance] selector:@selector(sendPresence) userInfo:nil repeats:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)call:(id)sender{
    // Call
    if(callButton.tag == 101){
        callButton.tag = 102;
    
        // Call user by ID
        //
        [[QBChat instance] callUser:[opponentID integerValue] conferenceType:QBVideoChatConferenceTypeAudioAndVideo];
        
        callButton.hidden = YES;
        ringigngLabel.hidden = NO;
        ringigngLabel.text = @"Calling...";
        ringigngLabel.frame = CGRectMake(128, 375, 90, 37);
        callingActivityIndicator.hidden = NO;

    // Finish
    }else{
        callButton.tag = 101;
        
        // Finish call
        //
        [[QBChat instance] finishCall];
        
        myVideoView.hidden = YES;
        opponentVideoView.image = [UIImage imageNamed:@"person.png"];
        AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
        [callButton setTitle:appDelegate.currentUser == 1 ? @"Call User2" : @"Call User1" forState:UIControlStateNormal];
        
        opponentVideoView.layer.borderWidth = 1;
        
        [startingCallActivityIndicator stopAnimating];
    }
}

- (IBAction)reject:(id)sender{
    // Reject call
    //
    [[QBChat instance] rejectCall];
    
    callButton.hidden = NO;
    callAcceptButton.hidden = YES;
    callRejectButton.hidden = YES;
    ringigngLabel.hidden = YES;
    
    [ringingPlayer release];
    ringingPlayer = nil;
}

- (IBAction)accept:(id)sender{
    // Accept call
    //
    [[QBChat instance] acceptCall];
    
    callAcceptButton.hidden = YES;
    callRejectButton.hidden = YES;
    ringigngLabel.hidden = YES;
    callButton.hidden = NO;
    [callButton setTitle:@"Hang up" forState:UIControlStateNormal];
    callButton.tag = 102;
    
    opponentVideoView.layer.borderWidth = 0;
    
    [startingCallActivityIndicator startAnimating];
    
     myVideoView.hidden = NO;
    
    [ringingPlayer release];
    ringingPlayer = nil;
}


#pragma mark -
#pragma mark AVAudioPlayerDelegate

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag{
    [ringingPlayer release];
    ringingPlayer = nil;
}


#pragma mark -
#pragma mark QBChatDelegate 
//
// VideoChat delegate

-(void) chatDidReceiveCallRequestFromUser:(NSUInteger)userID conferenceType:(enum QBVideoChatConferenceType)conferenceType{
    NSLog(@"chatDidReceiveCallRequestFromUser %d", userID);
    
    callButton.hidden = YES;
    callAcceptButton.hidden = NO;
    callRejectButton.hidden = NO;
    ringigngLabel.hidden = NO;
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    ringigngLabel.text = [NSString stringWithFormat:@"%@ is calling. Would you like to answer?", appDelegate.currentUser == 1 ? @"User 2" : @"User 1"];
    ringigngLabel.frame = CGRectMake(0, 418, 320, 20);
    
    // Play music
    if(ringingPlayer == nil){
        NSString *path =[[NSBundle mainBundle] pathForResource:@"ringing" ofType:@"wav"];
        NSURL *url = [NSURL fileURLWithPath:path];
        ringingPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:NULL];
        ringingPlayer.delegate = self;
        [ringingPlayer setVolume:1.0];
        [ringingPlayer play];
    }
}

-(void) chatCallUserDidNotAnswer:(NSUInteger)userID{
    NSLog(@"chatCallUserDidNotAnswer %d", userID);
    
    callButton.hidden = NO;
    callAcceptButton.hidden = YES;
    callRejectButton.hidden = YES;
    ringigngLabel.hidden = YES;
    callingActivityIndicator.hidden = YES;
    
    callButton.tag = 101;
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"QuickBlox VideoChat" message:@"User isn't answering. Please try again." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    [alert show];
    [alert release];
}

-(void) chatCallDidRejectByUser:(NSUInteger)userID{
     NSLog(@"chatCallDidRejectByUser %d", userID);
    
    callButton.hidden = NO;
    ringigngLabel.hidden = YES;
    callingActivityIndicator.hidden = YES;
    
    callButton.tag = 101;
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"QuickBlox VideoChat" message:@"User has rejected your call." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    [alert show];
    [alert release];
}

-(void) chatCallDidAcceptByUser:(NSUInteger)userID{
    NSLog(@"chatCallDidAcceptByUser %d", userID);
    
    ringigngLabel.hidden = YES;
    callingActivityIndicator.hidden = YES;
    
    opponentVideoView.layer.borderWidth = 0;
    
    callButton.hidden = NO;
    [callButton setTitle:@"Finish call" forState:UIControlStateNormal];
    callButton.tag = 102;
    
     myVideoView.hidden = NO;
    
    [startingCallActivityIndicator startAnimating];
}

-(void) chatCallDidStopByUser:(NSUInteger)userID purpose:(NSString *)purpose{
    NSLog(@"chatCallDidStopByUser %d purpose %@", userID, purpose);
    
    if([purpose isEqualToString:kStopVideoChatCallPurpose_OpponentDidNotAnswer]){
        callButton.hidden = NO;
        callAcceptButton.hidden = YES;
        callRejectButton.hidden = YES;
        ringigngLabel.hidden = YES;
        
        [ringingPlayer release];
        ringingPlayer = nil;
    
    }else if([purpose isEqualToString:kStopVideoChatCallPurpose_Manually]){
        myVideoView.hidden = YES;
        opponentVideoView.image = [UIImage imageNamed:@"person.png"];
        opponentVideoView.layer.borderWidth = 1;
        AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
        [callButton setTitle:appDelegate.currentUser == 1 ? @"Call User2" : @"Call User1" forState:UIControlStateNormal];
        callButton.tag = 101;
    }
}

- (void)chatCallDidStartWithUser:(NSUInteger)userID{
    [startingCallActivityIndicator stopAnimating];
}

- (UIImageView *) viewToRenderOpponentVideoStream{
    NSLog(@"viewToRenderOpponentVideoStream");
    return opponentVideoView;
}

- (UIImageView *) viewToRenderOwnVideoStream{
    NSLog(@"viewToRenderOwnVideoStreamw");
    return myVideoView;
}

@end
