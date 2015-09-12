//
//  PGViewController.m
//  Pong
//
//  Created by Russell Ladd on 6/25/14.
//  Copyright (c) 2014 GRL5. All rights reserved.
//

#import "PGBallViewController.h"

#import "PGColorPickerView.h"
#import "PGBallScene.h"

@import SpriteKit;

NSString *const PGBallViewControllerColorKey = @"com.GilbertLadd.PGBallViewControllerColor";
NSString *const PGBallViewControllerPeerIDKey = @"com.GilbertLadd.PGBallViewControllerPeerID";

NSString *const PGBallViewControllerServiceType = @"grl5-balls";

@import MultipeerConnectivity;

@interface PGBallViewController () <MCSessionDelegate, MCBrowserViewControllerDelegate, PGBallSceneDelegate>

@property (nonatomic, strong) UIColor *color;

@property (nonatomic) MCSessionState sessionState;

@property (nonatomic, strong, readonly) MCPeerID *localPeer;

@property (nonatomic, strong) MCSession *session;

@property (nonatomic, strong) MCAdvertiserAssistant *advertiserAssistant;
@property (nonatomic, weak) MCBrowserViewController *browserViewController;

@property (nonatomic, weak) IBOutlet PGColorPickerView *colorPickerView;
@property (nonatomic, weak) IBOutlet UIButton *addFriendButton;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *connectingIndicator;

@property (nonatomic, readonly) SKView *skView;
@property (nonatomic, strong) PGBallScene *ballScene;

@end

@implementation PGBallViewController

#pragma mark - Object life cycle

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        
        _color = [self savedColor];
        
        if (!_color) _color = [UIColor colorWithRed:0.88 green:0.34 blue:0.88 alpha:1.0];
        
        [self startSession];
    }
    
    return self;
}

- (void)dealloc
{
    [self stopSession];
}

#pragma mark - Model

- (void)setColor:(UIColor *)color
{
    if (![_color isEqual:color]) {
        
        _color = color;
        
        [self updateViewTintColor];
        [self updateConnectingIndicatorColor];
        
        [self saveColor];
    }
}

- (void)saveColor
{
    CGFloat red, green, blue;
    [self.color getRed:&red green:&green blue:&blue alpha:NULL];
    
    NSDictionary *dictionary = @{@"r": @(red), @"g": @(green), @"b": @(blue)};
    
    [[NSUserDefaults standardUserDefaults] setObject:dictionary forKey:PGBallViewControllerColorKey];
}

- (UIColor *)savedColor
{
    NSDictionary *dictionary = [[NSUserDefaults standardUserDefaults] objectForKey:PGBallViewControllerColorKey];
    
    if (!dictionary) return nil;
    
    UIColor *color = [UIColor colorWithRed:[dictionary[@"r"] doubleValue] green:[dictionary[@"g"] doubleValue] blue:[dictionary[@"b"] doubleValue] alpha:1.0];
    
    return color;
}

- (void)setSessionState:(MCSessionState)sessionState
{
    if (_sessionState != sessionState) {
        
        _sessionState = sessionState;
        
        [self updateAdvertising];
        
        self.ballScene.connectedToPeer = (_sessionState == MCSessionStateConnected);
        
        [self updateAddFriendButtonImage];
        [self updateConnectingIndicatorVisible];
    }
}

@synthesize localPeer = _localPeer;

- (MCPeerID *)localPeer {
    
    if (!_localPeer) {
        
        NSData *data = [[NSUserDefaults standardUserDefaults] dataForKey:PGBallViewControllerPeerIDKey];
        
        NSString *deviceName = [[UIDevice currentDevice] name];
        
        if (data) {
            
            _localPeer = [NSKeyedUnarchiver unarchiveObjectWithData:data];
            
        }
        
        if (!data || ![_localPeer.displayName isEqualToString:deviceName]) {
            
            _localPeer = [[MCPeerID alloc] initWithDisplayName:deviceName];
            
            data = [NSKeyedArchiver archivedDataWithRootObject:_localPeer];
            
            [[NSUserDefaults standardUserDefaults] setObject:data forKey:PGBallViewControllerPeerIDKey];
        }
    }
    
    return _localPeer;
}

#pragma mark - Session

- (void)startSession
{
    self.session = [[MCSession alloc] initWithPeer:self.localPeer];
    self.session.delegate = self;
    
    self.advertiserAssistant = [[MCAdvertiserAssistant alloc] initWithServiceType:PGBallViewControllerServiceType discoveryInfo:nil session:self.session];
    
    [self.advertiserAssistant start];
}

- (void)stopSession
{
    [self.advertiserAssistant stop];
    self.advertiserAssistant = nil;
    
    self.session.delegate = nil;
    self.session = nil;
}

- (void)updateAdvertising {
    
    if (self.sessionState == MCSessionStateConnected) {
        [self.advertiserAssistant stop];
    } else {
        [self.advertiserAssistant start];
    }
}

#pragma mark - View life cycle

- (SKView *)skView
{
    return (SKView *)self.view;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Color picker view
    
    self.colorPickerView.color = self.color;
    
    // Add friend button
    
    [self updateAddFriendButtonImage];
    
    // Scene
    
    self.ballScene = [PGBallScene sceneWithSize:self.skView.bounds.size];
    self.ballScene.ballDelegate = self;
    
    [self.ballScene createBalls:10 color:self.color];
    
    // SKView
    
    self.skView.ignoresSiblingOrder = YES;
    
    [self.skView presentScene:self.ballScene];
    
    // View
    
    self.view.tintAdjustmentMode = UIViewTintAdjustmentModeNormal;
    
    [self updateViewTintColor];
    [self updateConnectingIndicatorColor];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
}

#pragma mark - View color

- (void)updateViewTintColor
{
    self.view.tintColor = self.color;
}

- (void)updateConnectingIndicatorColor
{
    self.connectingIndicator.color = self.color;
}

#pragma mark - Add friend button

- (void)updateAddFriendButtonImage
{
    UIImage *image;
    
    switch (self.sessionState) {
        case MCSessionStateNotConnected:
            image = [UIImage imageNamed:@"AddFriend"];
            break;
            
        case MCSessionStateConnected:
            image = [UIImage imageNamed:@"Eject"];
            break;
            
        default:
            break;
    }
    
    [self.addFriendButton setImage:image forState:UIControlStateNormal];
}

- (void)updateConnectingIndicatorVisible {
    
    if (self.sessionState == MCSessionStateConnecting) {
        [self.connectingIndicator startAnimating];
    } else {
        [self.connectingIndicator stopAnimating];
    }
}

#pragma mark - Touch

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    
    [self.colorPickerView setExpanded:NO animated:YES];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesEnded:touches withEvent:event];
    
    [touches enumerateObjectsUsingBlock:^(UITouch *touch, BOOL *stop) {
        
        CGPoint location = [touch locationInNode:self.ballScene];
        
        SKNode *node = [self.ballScene nodeAtPoint:location];
        
        if ([node.name isEqualToString:PGBallSceneBallNodeName]) {
            
            [node removeFromParent];
            
        } else {
            
            [self.ballScene createBallWithPosition:location velocity:CGVectorMake(0.0, 0.0) angularVelocity:0.0 color:self.color];
        }
    }];
}

#pragma mark - Status bar

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

#pragma mark - Actions

- (IBAction)colorPickerViewValueChanged:(PGColorPickerView *)colorPickerView
{
    UIColor *color = colorPickerView.color;
    
    [colorPickerView setExpanded:NO animated:YES delay:0.2 animations:^{
        
        self.color = color;
    }];
}

- (IBAction)addFriendTouchUpInside
{
    [self.colorPickerView setExpanded:NO animated:YES];
    
    if (self.sessionState == MCSessionStateConnected) {
        
        [self.session disconnect];
        
    } else if (self.sessionState == MCSessionStateNotConnected) {
        
        MCBrowserViewController *browserViewController = [[MCBrowserViewController alloc] initWithServiceType:@"grl5-balls" session:self.session];
        browserViewController.maximumNumberOfPeers = 2;
        browserViewController.delegate = self;
        
        [self presentViewController:browserViewController animated:YES completion:NULL];
        
        self.browserViewController = browserViewController;
    }
}

#pragma mark - Browser view controller delegate

- (void)browserViewControllerWasCancelled:(MCBrowserViewController *)browserViewController
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)browserViewControllerDidFinish:(MCBrowserViewController *)browserViewController
{
    
}

#pragma mark - Session delegate

- (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state
{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        
        if (state == MCSessionStateConnected || state == MCSessionStateConnecting) {
            
            [self dismissViewControllerAnimated:YES completion:NULL];
        }
        
        self.sessionState = state;
    }];
}

- (void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID
{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        
        NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:NULL];
        
        CGFloat x = [dictionary[@"x"] doubleValue];
        
        CGVector velocity = CGVectorMake([dictionary[@"v"][@"x"] doubleValue], [dictionary[@"v"][@"y"] doubleValue]);
        
        CGFloat angularVelocity = [dictionary[@"o"] doubleValue];
        
        UIColor *color = [UIColor colorWithRed:[dictionary[@"c"][@"r"] doubleValue] green:[dictionary[@"c"][@"g"] doubleValue] blue:[dictionary[@"c"][@"b"] doubleValue] alpha:1.0];
        
        [self.ballScene dropLostBallWithX:x velocity:velocity angularVelocity:angularVelocity color:color];
    }];
}

- (void)session:(MCSession *)session didReceiveStream:(NSInputStream *)stream withName:(NSString *)streamName fromPeer:(MCPeerID *)peerID
{
    
}

- (void)session:(MCSession *)session didStartReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID withProgress:(NSProgress *)progress
{
    
}

- (void)session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID atURL:(NSURL *)localURL withError:(NSError *)error
{
    
}

#pragma mark - Ball scene delegate

- (void)ballScene:(PGBallScene *)scene didLoseBallWithX:(CGFloat)x velocity:(CGVector)v angularVelocity:(CGFloat)o color:(UIColor *)color
{
    CGFloat red, green, blue;
    [color getRed:&red green:&green blue:&blue alpha:NULL];
    
    NSDictionary *dictionary = @{@"x": @(x),
                                 @"v": @{@"x": @(v.dx),
                                         @"y": @(v.dy)},
                                 @"o": @(o),
                                 @"c": @{@"r": @(red),
                                         @"g": @(green),
                                         @"b": @(blue)}};
    
    NSData *data = [NSJSONSerialization dataWithJSONObject:dictionary options:0 error:NULL];
    
    NSError *error;
    [self.session sendData:data toPeers:self.session.connectedPeers withMode:MCSessionSendDataReliable error:&error];
    
    if (error) {
        
        [scene dropLostBallWithX:x velocity:v angularVelocity:o color:color];
    }
}

@end
