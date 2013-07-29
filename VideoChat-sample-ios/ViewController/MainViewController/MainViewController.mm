//
//  MainViewController.m
//  SimpleSample-videochat-ios
//
//  Created by QuickBlox team on 1/02/13.
//  Copyright (c) 2013 QuickBlox. All rights reserved.
//

#import "MainViewController.h"
#import "AppDelegate.h"
#import "RingBuffer.h"

@interface MainViewController ()
@end

static RingBuffer *ringBuffer;

@implementation MainViewController

@synthesize opponentID;
@synthesize captureSession;



- (void)dealloc{
    [opponentID release];
    [captureSession release];
    
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
    
    [self setupVideoCapture];
	[self setupAudioCapture];
}

- (void)viewDidUnload{
    
    [[QBChat instance] unregisterVideoChatInstance:self.videoChat];
    [self.videoChat release];
    self.videoChat = nil;
    
    
    callButton = nil;
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

#pragma mark -
#pragma mark Video and audio setup

-(void) setupVideoCapture{
	captureSession = [[AVCaptureSession alloc] init];
    
    __block NSError *error = nil;
    
    // set preset
    [self.captureSession setSessionPreset:AVCaptureSessionPresetHigh];
    
    
    // Setup the Video input
    AVCaptureDevice *videoDevice = [self frontFacingCamera];
    //
    AVCaptureDeviceInput *captureVideoInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
    if(error){
        QBDLogEx(@"deviceInputWithDevice Video error: %@", error);
    }else{
        if ([self.captureSession  canAddInput:captureVideoInput]){
            [self.captureSession addInput:captureVideoInput];
        }else{
            QBDLogEx(@"cantAddInput Video");
        }
    }
    
    // Setup Video output
    AVCaptureVideoDataOutput *videoCaptureOutput = [[AVCaptureVideoDataOutput alloc] init];
    videoCaptureOutput.alwaysDiscardsLateVideoFrames = YES;
    //
    // Set the video output to store frame in BGRA (It is supposed to be faster)
    NSString* key = (NSString*)kCVPixelBufferPixelFormatTypeKey;
    NSNumber* value = [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA];
    NSDictionary* videoSettings = [NSDictionary dictionaryWithObject:value forKey:key];
    [videoCaptureOutput setVideoSettings:videoSettings];
    /*And we create a capture session*/
    if([self.captureSession canAddOutput:videoCaptureOutput]){
        [self.captureSession addOutput:videoCaptureOutput];
    }else{
        QBDLogEx(@"cantAddOutput");
    }
    [videoCaptureOutput release];
    
	
    // set FPS
    int framesPerSecond = 20;
    AVCaptureConnection *conn = [videoCaptureOutput connectionWithMediaType:AVMediaTypeVideo];
    if (conn.isVideoMinFrameDurationSupported){
        conn.videoMinFrameDuration = CMTimeMake(1, framesPerSecond);
    }
    if (conn.isVideoMaxFrameDurationSupported){
        conn.videoMaxFrameDuration = CMTimeMake(1, framesPerSecond);
    }
    
    /*We create a serial queue to handle the processing of our frames*/
    dispatch_queue_t callbackQueue= dispatch_queue_create("cameraQueue", NULL);
    [videoCaptureOutput setSampleBufferDelegate:self queue:callbackQueue];
    dispatch_release(callbackQueue);
    
    // Add preview layer
    AVCaptureVideoPreviewLayer *prewLayer = [[[AVCaptureVideoPreviewLayer alloc] initWithSession:self.captureSession] autorelease];
	[prewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    CGRect layerRect = [[myVideoView layer] bounds];
	[prewLayer setBounds:layerRect];
	[prewLayer setPosition:CGPointMake(CGRectGetMidX(layerRect),CGRectGetMidY(layerRect))];
    myVideoView.hidden = NO;
    [myVideoView.layer addSublayer:prewLayer];
	
	
    /*We start the capture*/
    [self.captureSession startRunning];

}

-(void) setupAudioCapture{
	// setup audio
	QBAudioSession *audioManager = [QBAudioSession audioManager];
	[audioManager initializeInputUnit];
	[audioManager routeToSpeaker];
	//
	ringBuffer = new RingBuffer(32768, 2);
	
	[audioManager play];
	[audioManager setInputBlock:^(float *data, UInt32 numFrames, UInt32 numChannels){
		
		[self.videoChat processVideoChatCaptureAudioData:data numFrames:numFrames numChannels:numChannels];
	}];
	
}   

- (void)captureOutput:(AVCaptureOutput *)captureOutput  didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
	[self.videoChat processVideoChatCaptureVideoSample:sampleBuffer];
}

- (AVCaptureDevice *) cameraWithPosition:(AVCaptureDevicePosition) position{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if ([device position] == position) {
            return device;
        }
    }
    return nil;
}

- (AVCaptureDevice *) backFacingCamera{
    return [self cameraWithPosition:AVCaptureDevicePositionBack];
}

- (AVCaptureDevice *) frontFacingCamera{
    return [self cameraWithPosition:AVCaptureDevicePositionFront];
}

#pragma mark
#pragma mark Logic

- (IBAction)call:(id)sender{
    // Call
    if(callButton.tag == 101){
        callButton.tag = 102;
    
        // Call user by ID
        //
		// Create video chat
		self.videoChat = [[QBChat instance] createAndRegisterVideoChatInstance];
		self.videoChat.viewToRenderOpponentVideoStream = opponentVideoView;
		self.videoChat.viewToRenderOwnVideoStream = myVideoView;
		// setup custom capture
		self.videoChat.isUseCustomAudioChatSession = YES;
		self.videoChat.isUseCustomVideoChatCaptureSession = YES;
		
        [self.videoChat callUser:[opponentID integerValue] conferenceType:QBVideoChatConferenceTypeAudio];
        
        callButton.hidden = YES;
        callingActivityIndicator.hidden = NO;

    // Finish
    }else{
        callButton.tag = 101;
        
        // Finish call
        //
        [self.videoChat finishCall];
        
//        myVideoView.hidden = YES;
        opponentVideoView.image = [UIImage imageNamed:@"person.png"];
        AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
        [callButton setTitle:appDelegate.currentUser == 1 ? @"Call User2" : @"Call User1" forState:UIControlStateNormal];
        
        opponentVideoView.layer.borderWidth = 1;
        
        [startingCallActivityIndicator stopAnimating];
		
		[[QBChat instance] unregisterVideoChatInstance:self.videoChat];
        self.videoChat = nil;
    }
}

- (void)reject{
    // Reject call
    //
    if(self.videoChat == nil){
        self.videoChat = [[QBChat instance] createAndRegisterVideoChatInstanceWithSessionID:self.currentSessionID];
    }
    [self.videoChat rejectCallWithOpponentID:[opponentID integerValue]];
    //
    //
    [[QBChat instance] unregisterVideoChatInstance:self.videoChat];
    self.videoChat = nil;
	
    callButton.hidden = NO;
    [ringingPlayer release];
    ringingPlayer = nil;
}

- (void)accept{
    // Accept call
    //
	if(self.videoChat == nil){
        self.videoChat = [[QBChat instance] createAndRegisterVideoChatInstanceWithSessionID:self.currentSessionID];
        self.videoChat.viewToRenderOpponentVideoStream = opponentVideoView;
        self.videoChat.viewToRenderOwnVideoStream = myVideoView;
		// setup custom capture
		self.videoChat.isUseCustomAudioChatSession = YES;
		self.videoChat.isUseCustomVideoChatCaptureSession = YES;
    }
	
    [self.videoChat acceptCallWithOpponentID:[self.opponentID integerValue]	conferenceType:QBVideoChatConferenceTypeAudio];
    
	callButton.hidden = NO;
    [callButton setTitle:@"Hang up" forState:UIControlStateNormal];
    callButton.tag = 102;
    
    opponentVideoView.layer.borderWidth = 0;
    
    [startingCallActivityIndicator startAnimating];
    
//     myVideoView.hidden = NO;
    
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

-(void) chatDidReceiveCallRequestFromUser:(NSUInteger)userID withSessionID:(NSString*)sessionID conferenceType:(enum QBVideoChatConferenceType)conferenceType{
    NSLog(@"chatDidReceiveCallRequestFromUser %d", userID);
    
	 if (self.callAlert == nil) {
		 AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
		 NSString *message = [NSString stringWithFormat:@"%@ is calling. Would you like to answer?", appDelegate.currentUser == 1 ? @"User 2" : @"User 1"];
		 self.callAlert = [[UIAlertView alloc] initWithTitle:@"Call" message:message delegate:self cancelButtonTitle:@"Decline" otherButtonTitles:@"Accept", nil];
		 [self.callAlert show];
	 }
	
	// hide call alert if opponent has canceled call
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideCallAlert) object:nil];
    [self performSelector:@selector(hideCallAlert) withObject:nil afterDelay:4];
	
	[self.currentSessionID release];
	self.currentSessionID = [sessionID retain];
	
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
    callingActivityIndicator.hidden = YES;
    
    callButton.tag = 101;
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"QuickBlox VideoChat" message:@"User isn't answering. Please try again." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    [alert show];
    [alert release];
}

-(void) chatCallDidRejectByUser:(NSUInteger)userID{
     NSLog(@"chatCallDidRejectByUser %d", userID);
    
    callButton.hidden = NO;
    callingActivityIndicator.hidden = YES;
    
    callButton.tag = 101;
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"QuickBlox VideoChat" message:@"User has rejected your call." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    [alert show];
    [alert release];
}

-(void) chatCallDidAcceptByUser:(NSUInteger)userID{
    NSLog(@"chatCallDidAcceptByUser %d", userID);
    
    callingActivityIndicator.hidden = YES;
    
    opponentVideoView.layer.borderWidth = 0;
    
    callButton.hidden = NO;
    [callButton setTitle:@"Hang up" forState:UIControlStateNormal];
    callButton.tag = 102;
    
//     myVideoView.hidden = NO;
    
    [startingCallActivityIndicator startAnimating];
    
}

-(void) chatCallDidStopByUser:(NSUInteger)userID status:(NSString *)status{
    NSLog(@"chatCallDidStopByUser %d purpose %@", userID, status);
    
    if([status isEqualToString:kStopVideoChatCallStatus_OpponentDidNotAnswer]){
        self.callAlert.delegate = nil;
        [self.callAlert dismissWithClickedButtonIndex:0 animated:YES];
        self.callAlert = nil;
        
        [ringingPlayer release];
        ringingPlayer = nil;
    
    }else{
//        myVideoView.hidden = YES;
        opponentVideoView.image = [UIImage imageNamed:@"person.png"];
        opponentVideoView.layer.borderWidth = 1;
        AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
        [callButton setTitle:appDelegate.currentUser == 1 ? @"Call User2" : @"Call User1" forState:UIControlStateNormal];
        callButton.tag = 101;
		
		[[QBChat instance] unregisterVideoChatInstance:self.videoChat];
        self.videoChat = nil;
    }
}

-(void) chatCallDidStartWithUser:(NSUInteger)userID sessionID:(NSString *)sessionID{
    [startingCallActivityIndicator stopAnimating];
}

-(void)didReceiveAudioData:(float *)data lenght:(NSUInteger)lenght channels:(int)channels{
	
	ringBuffer->AddNewInterleavedFloatData(data, lenght, channels);
	
	QBAudioSession *audioManager = [QBAudioSession audioManager];
	__weak __block QBAudioSession *__weakAudioSession = audioManager;
	
	if([audioManager outputBlock] == nil){
		[audioManager setOutputBlock:^(float *outData, UInt32 numFrames, UInt32 numChannels) {
			
			// read if exist unread frames
			if(ringBuffer->NumUnreadFrames(0) > 0){
				ringBuffer->FetchInterleavedData(outData, numFrames, numChannels);
			}else{
				[__weakAudioSession setOutputBlock:nil];
			}
			
			// Correction (if have to much unread data)
			if(ringBuffer->NumUnreadFrames(0) > 256 * 12) {// 0.032*12 = 384ms max delay
				ringBuffer->Clear();
			}
		}];
	}
}

- (void)chatDidEexceedWriteQueueMaxOperationsThresholdWithCount:(int)operationsInQueue{
    NSLog(@"operationsInQueue %d", operationsInQueue);
    
    [self.videoChat drainWriteQueue];
}

#pragma mark -
#pragma mark UIAlertView

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    switch (buttonIndex) {
			// Reject
        case 0:
            [self reject];
            break;
			// Accept
        case 1:
            [self accept];
            break;
            
        default:
            break;
    }
    
    self.callAlert = nil;
}

- (void)hideCallAlert{
    [self.callAlert dismissWithClickedButtonIndex:-1 animated:YES];
    self.callAlert = nil;
    
    callButton.hidden = NO;
}

@end
