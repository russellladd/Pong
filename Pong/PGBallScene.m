//
//  PGMyScene.m
//  Pong
//
//  Created by Russell Ladd on 6/25/14.
//  Copyright (c) 2014 GRL5. All rights reserved.
//

#import "PGBallScene.h"

NSString *const PGBallSceneBallNodeName = @"ball";

@import CoreMotion;

@interface PGBallScene ()

@property (nonatomic) NSInteger maxBalls;
@property (nonatomic) CGFloat ballRadius;

@property (nonatomic) SKTexture *ballTexture;

@property (nonatomic, strong) CMMotionManager *motionManager;

@end

@implementation PGBallScene

#pragma mark - Object life cycle

- (instancetype)initWithSize:(CGSize)size {
    
    self = [super initWithSize:size];
    
    if (self) {
        
        // Configure the scene
        
        self.backgroundColor = [SKColor blackColor];
        
        [self updateScenePhysicsBody];
        
        // Set ball metrics
        
        self.maxBalls = 150;
        self.ballRadius = 22.0;
        
        // Set the ball texture
        
        self.ballTexture = [SKTexture textureWithImageNamed:@"Ball"];
        
        // Configure the motion manager
        
        _motionManager = [[CMMotionManager alloc] init];
        
        [_motionManager startAccelerometerUpdates];
    }
    
    return self;
}

#pragma mark - Animation loop

- (void)update:(CFTimeInterval)currentTime {
    
    CMAccelerometerData *data = self.motionManager.accelerometerData;
    
    CMAcceleration acceleration = data.acceleration;
    
    self.physicsWorld.gravity = CGVectorMake(acceleration.x * 9.8, acceleration.y * 9.8);
}

- (void)didSimulatePhysics
{
    [self enumerateChildNodesWithName:PGBallSceneBallNodeName usingBlock:^(SKNode *node, BOOL *stop) {
        
        SKSpriteNode *ball = (SKSpriteNode *)node;
        
        if (ball.position.x > -self.ballRadius &&
            ball.position.x < self.size.width + self.ballRadius &&
            ball.position.y >= self.size.height + self.ballRadius) {
            
            CGFloat x = (ball.position.x - self.ballRadius) / (self.size.width - 2 * self.ballRadius);
            
            [self.ballDelegate ballScene:self didLoseBallWithX:x velocity:ball.physicsBody.velocity angularVelocity:ball.physicsBody.angularVelocity color:ball.color];
        }
        
        if (ball.position.x <= -self.ballRadius ||
            ball.position.x >= self.size.width + self.ballRadius ||
            ball.position.y <= -self.ballRadius ||
            ball.position.y >= self.size.height + self.ballRadius) {
            
            [ball removeFromParent];
        }
    }];
}

#pragma mark - Properties

- (void)setConnectedToPeer:(BOOL)connectedToPeer
{
    if (_connectedToPeer != connectedToPeer) {
        
        _connectedToPeer = connectedToPeer;
        
        [self updateScenePhysicsBody];
    }
}

#pragma mark - Scene physics body

- (void)updateScenePhysicsBody
{
    CGFloat height = self.size.height * (self.connectedToPeer ? 2.0 : 1.0);
    
    CGRect rect = CGRectMake(0.0, 0.0, self.size.width, height);
    
    self.physicsBody = [SKPhysicsBody bodyWithEdgeLoopFromRect:CGRectInset(rect, -1.0, -1.0)];
}

#pragma mark - Balls

- (void)createBalls:(NSUInteger)number color:(SKColor *)color
{
    for (NSUInteger i = 0; i < number; i++) {
        
        CGFloat x = arc4random() % 100 / 100.0 * self.size.width;
        CGFloat y = arc4random() % 100 / 100.0 * self.size.height;
        
        [self createBallWithPosition:CGPointMake(x, y) velocity:CGVectorMake(0.0, 0.0) angularVelocity:0.0 color:color];
    }
}

- (void)dropLostBallWithX:(CGFloat)x velocity:(CGVector)v angularVelocity:(CGFloat)o color:(UIColor *)color
{
    CGFloat invertedX = (self.size.width - 2 * self.ballRadius) * (1.0 - x) + self.ballRadius;
    CGPoint position = CGPointMake(invertedX, self.size.height + self.ballRadius);
    CGVector invertedVelocity = CGVectorMake(-v.dx, -v.dy);
    
    [self createBallWithPosition:position velocity:invertedVelocity angularVelocity:o color:color];
}

- (void)createBallWithPosition:(CGPoint)p velocity:(CGVector)v angularVelocity:(CGFloat)o color:(UIColor *)color
{
    if (self.children.count <= self.maxBalls) {
        
        SKSpriteNode *ball = [SKSpriteNode spriteNodeWithTexture:self.ballTexture];
        
        ball.name = PGBallSceneBallNodeName;
        
        ball.color = color;
        ball.colorBlendFactor = 1.0;
        
        ball.position = p;
        
        ball.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:self.ballRadius];
        ball.physicsBody.velocity = v;
        ball.physicsBody.angularVelocity = o;
        
        [self addChild:ball];
    }
}

@end
