//
//  MainViewController.m
//  CGArcTimer
//
//  Created by Dan Lichty on 11-08-22.
//  Copyright 2011 Dan Lichty. All rights reserved.
//

#import "MainViewController.h"

#define kAnimationDuration 5.0

@implementation MainViewController

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	UIImage *sourceImage = [UIImage imageNamed:@"sprite"];
	if (sourceImage.scale != [[UIScreen mainScreen] scale])
	{
		// To preserve the pixel-y quality of the sprite on the Retina display, we need to
		// create our own high-res version, otherwise Core Graphics scales the original
		// sprite without using the nearest neighbour method
		
		CGFloat factor = [[UIScreen mainScreen] scale] / sourceImage.scale;
		CGImageRef imageRef = sourceImage.CGImage;
		
		// Need to do this for indexed 8-bit PNGs ( http://stackoverflow.com/questions/2457116/iphone-changing-cgimagealphainfo-of-cgimage )
		CGColorSpaceRef genericCS = CGColorSpaceCreateDeviceRGB();
		CGContextRef genericContext = CGBitmapContextCreate(NULL, sourceImage.size.width, sourceImage.size.height, CGImageGetBitsPerComponent(imageRef), sourceImage.size.width * CGImageGetBitsPerPixel(imageRef) * 8, genericCS, kCGImageAlphaPremultipliedFirst);
		CGColorSpaceRelease(genericCS);
		CGRect destRect = CGRectMake(0, 0, sourceImage.size.width, sourceImage.size.height);
		CGContextDrawImage(genericContext, destRect, imageRef);
		CGImageRef genericImageRef = CGBitmapContextCreateImage(genericContext);
		CGContextRelease(genericContext);
		
		
		// Scale standard-res image 2x to prevent antialiasing
		CGSize newSize = CGSizeApplyAffineTransform(sourceImage.size, CGAffineTransformMakeScale(factor, factor));
		CGRect newRect = CGRectIntegral(CGRectMake(0, 0, newSize.width, newSize.height));
		
		CGContextRef ctx = CGBitmapContextCreate(NULL, newRect.size.width, newRect.size.height, CGImageGetBitsPerComponent(genericImageRef), CGImageGetBytesPerRow(genericImageRef), CGImageGetColorSpace(genericImageRef), CGImageGetBitmapInfo(genericImageRef));
		CGContextSetInterpolationQuality(ctx, kCGInterpolationNone);
		CGContextDrawImage(ctx, newRect, genericImageRef);
		CGImageRelease(genericImageRef);
		
		CGImageRef newImageRef = CGBitmapContextCreateImage(ctx);
		spriteImage = [[UIImage imageWithCGImage:newImageRef scale:[[UIScreen mainScreen] scale] orientation:UIImageOrientationUp] retain];
		
		CGContextRelease(ctx);
		CGImageRelease(newImageRef);
	}
	else
	{
		spriteImage = [sourceImage retain];
	}
	
	[self performSelector:@selector(reset)];
	
	arcLayer = [[CALayer layer] retain];
	
	// Minimum radius of circle to surround sprite
	CGFloat radius = sqrtf(powf(spriteImage.size.width / 2, 2) + powf(spriteImage.size.height / 2, 2)) + 2;
	
	arcLayer.frame = CGRectIntegral(CGRectMake(self.view.frame.size.width / 2 - radius, 10, radius * 2, radius * 2));
	arcLayer.delegate = self;
	arcLayer.contentsScale = [[UIScreen mainScreen] scale];
	
	[self.view.layer addSublayer:arcLayer];
	
	UIButton *resetButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	[resetButton addTarget:self action:@selector(reset) forControlEvents:UIControlEventTouchUpInside];
	[resetButton setTitle:@"Reset" forState:UIControlStateNormal];
	CGFloat buttonWidth = 100;
	CGFloat buttonHeight = 40;
	resetButton.frame = CGRectMake(
																 self.view.frame.size.width / 2 - buttonWidth / 2,
																 self.view.frame.size.height - 10 - buttonHeight,
																 buttonWidth,
																 buttonHeight);
	[self.view addSubview:resetButton];
}

- (void)viewDidUnload
{
	[arcLayer removeFromSuperlayer];
	[arcLayer release], arcLayer = nil;
	
	[displayLink invalidate];
	displayLink = nil;
	
	[spriteImage release], spriteImage = nil;
}

- (void)reset
{
	if (displayLink)
	{
		[displayLink invalidate];
	}
	
	displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayUpdated)];
	[displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	displayLink.frameInterval = 2;
	
	startTime = CACurrentMediaTime();
	completionPercent = 0.0;
}

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx
{
	CGRect rect = CGContextGetClipBoundingBox(ctx);
	CGFloat spriteDim = 160;
	CGRect spriteRect = CGRectMake(40, 40, spriteDim, spriteDim);
	CGSize size = rect.size;
	
	CGContextClearRect(ctx, rect);
	
	// Start sector at top of circle
	CGFloat radius = size.width / 2;
	CGFloat circleStart = -0.5 * M_PI;
	CGFloat fullCircle = 2 * M_PI;
	
	// Draw sprite
	UIGraphicsPushContext(ctx);
	[spriteImage drawInRect:spriteRect];
	UIGraphicsPopContext();
	
	if (completionPercent != 1.0)
	{
		// Draw translucent white circle sector
		CGMutablePathRef path = CGPathCreateMutable();
		CGPathMoveToPoint(path, NULL, size.width / 2, size.height / 2);
		CGPathAddArc(path, NULL, size.width / 2, size.height / 2, radius, circleStart, circleStart + completionPercent * fullCircle, true);
		CGPathCloseSubpath(path);
		
		CGContextSetBlendMode(ctx, kCGBlendModeSourceAtop);
		
		CGContextSetFillColorWithColor(ctx, [[[UIColor whiteColor] colorWithAlphaComponent:0.8] CGColor]);
		CGContextAddPath(ctx, path);
		CGContextDrawPath(ctx, kCGPathFill);
		
		CGPathRelease(path);
	}
	
	// Draw blue circle sector underneath sprite
	CGContextSetBlendMode(ctx, kCGBlendModeDestinationOver);
	
	CGMutablePathRef inversePath = CGPathCreateMutable();
	CGPathMoveToPoint(inversePath, NULL, size.width / 2, size.height / 2);
	CGPathAddArc(inversePath, NULL, size.width / 2, size.height / 2, radius, circleStart, circleStart + completionPercent * fullCircle, false);
	CGPathCloseSubpath(inversePath);
	
	CGContextSetFillColorWithColor(ctx, [[[UIColor blueColor] colorWithAlphaComponent:0.1] CGColor]);
	CGContextAddPath(ctx, inversePath);
	CGContextFillPath(ctx);
	CGPathRelease(inversePath);
}

- (void)displayUpdated
{
	CFTimeInterval delta = displayLink.timestamp - startTime;
	
	completionPercent = delta / kAnimationDuration;
	
	if (completionPercent >= 1)
	{
		completionPercent = 1.0;
		[displayLink invalidate];
		displayLink = nil;
	}
	
	[arcLayer setNeedsDisplay];
}

- (void)dealloc
{
	[displayLink invalidate];
		
	[displayLink release];
	[arcLayer release];
	[spriteImage release];
	
	[super dealloc];
}

@end
