//
//  PGMyScene.h
//  Pong
//

//  Copyright (c) 2014 GRL5. All rights reserved.
//

@import SpriteKit;

@class PGBallScene;

extern NSString *const PGBallSceneBallNodeName;

@protocol PGBallSceneDelegate <NSObject>

- (void)ballScene:(PGBallScene *)scene didLoseBallWithX:(CGFloat)x velocity:(CGVector)v angularVelocity:(CGFloat)o color:(SKColor *)color;

@end

@interface PGBallScene : SKScene

@property (nonatomic) BOOL connectedToPeer;

- (void)createBalls:(NSUInteger)number color:(SKColor *)color;
- (void)dropLostBallWithX:(CGFloat)x velocity:(CGVector)v angularVelocity:(CGFloat)o color:(SKColor *)color;
- (void)createBallWithPosition:(CGPoint)p velocity:(CGVector)v angularVelocity:(CGFloat)o color:(SKColor *)color;

@property (nonatomic, weak) id<PGBallSceneDelegate> ballDelegate;

@end
