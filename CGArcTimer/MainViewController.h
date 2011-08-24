//
//  MainViewController.h
//  CGArcTimer
//
//  Created by Dan Lichty on 11-08-22.
//  Copyright 2011 Dan Lichty. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@interface MainViewController : UIViewController {
	UIImage *spriteImage;
	CADisplayLink *displayLink;
	CALayer *arcLayer;
	
	CFTimeInterval startTime;
	CGFloat completionPercent;
}

@end
