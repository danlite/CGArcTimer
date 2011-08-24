//
//  CGArcTimerAppDelegate.m
//  CGArcTimer
//
//  Created by Dan Lichty on 11-08-22.
//  Copyright 2011 Dan Lichty. All rights reserved.
//

#import "CGArcTimerAppDelegate.h"
#import "MainViewController.h"

@implementation CGArcTimerAppDelegate


@synthesize window=_window;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	MainViewController *mainVC = [[MainViewController alloc] init];
	[self.window addSubview:mainVC.view];
	
	[self.window makeKeyAndVisible];
	return YES;
}

- (void)dealloc
{
	[_window release];
	[super dealloc];
}

@end
