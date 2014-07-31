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

@import MultipeerConnectivity;

@interface PGBallViewController () <MCBrowserViewControllerDelegate, MCSessionDelegate, PGBallSceneDelegate>

@property (nonatomic, strong) UIColor *color;

@property (nonatomic) BOOL connectedToPeer;

@property (nonatomic, strong) MCPeerID *localPeer;

@property (nonatomic, strong) MCSession *session;

@property (nonatomic, strong) MCAdvertiserAssistant *advertiserAssistant;
@property (nonatomic, weak) MCBrowserViewController *browserViewController;

@property (nonatomic, weak) IBOutlet PGColorPickerView *colorPickerView;
@property (nonatomic, weak) IBOutlet UIButton *addFriendButton;

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
        
        [self startNewSession];
    }
    
    return self;
}

- (void)dealloc
{
    [self endCurrentSession];
}

#pragma mark - Model

- (void)setColor:(UIColor *)color
{
    if (![_color isEqual:color]) {
        
        _color = color;
        
        [self updateViewTintColor];
        
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

- (void)setConnectedToPeer:(BOOL)connectedToPeer
{
    if (_connectedToPeer != connectedToPeer) {
        
        _connectedToPeer = connectedToPeer;
        
        self.ballScene.connectedToPeer = _connectedToPeer;
        
        [self updateAddFriendButtonImage];
    }
}

#pragma mark - Session

- (void)endCurrentSession
{
    [self.advertiserAssistant stop];
    self.advertiserAssistant = nil;
    
    self.session.delegate = nil;
    self.session = nil;
    
    self.localPeer = nil;
}

- (void)startNewSession
{
    self.localPeer = [[MCPeerID alloc] initWithDisplayName:[[UIDevice currentDevice] name]];
    
    self.session = [[MCSession alloc] initWithPeer:self.localPeer];
    self.session.delegate = self;
    
    self.advertiserAssistant = [[MCAdvertiserAssistant alloc] initWithServiceType:@"grl5-balls" discoveryInfo:nil session:self.session];
    
    [self.advertiserAssistant start];
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
    self.ballScene.delegate = self;
    
    [self.ballScene createBalls:10 color:self.color];
    
    // SKView
    
    self.skView.ignoresSiblingOrder = YES;
    
    [self.skView presentScene:self.ballScene];
    
    // View
    
    self.view.tintAdjustmentMode = UIViewTintAdjustmentModeNormal;
    
    [self updateViewTintColor];
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

#pragma mark - View tint color

- (void)updateViewTintColor
{
    self.view.tintColor = self.color;
}

#pragma mark - Add friend button

- (void)updateAddFriendButtonImage
{
    NSString *imageName = _connectedToPeer ? @"Eject" : @"AddFriend";
    
    UIImage *image = [[UIImage imageNamed:imageName] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    
    [self.addFriendButton setImage:image forState:UIControlStateNormal];
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
    
    if (self.connectedToPeer) {
        
        [self.session disconnect];
        
    } else {
        
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
        
        if (state == MCSessionStateConnected) {
            
            self.connectedToPeer = YES;
            
            [self dismissViewControllerAnimated:YES completion:NULL];
            
        } else if (state == MCSessionStateNotConnected) {
            
            self.connectedToPeer = NO;
            
            [self endCurrentSession];
            [self startNewSession];
        }
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
