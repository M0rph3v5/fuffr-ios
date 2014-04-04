//
//  FFRPanGestureRecognizer.m
//  FuffrLib
//
//  Created by Fuffr on 2013-11-11.
//  Copyright (c) 2013 Fuffr. All rights reserved.
//

#import "FFRPanGestureRecognizer.h"
#import "FFRTouch.h"

@implementation FFRPanGestureRecognizer

#pragma mark - Touch handling

- (id) init
{
	self = [super init];

    if (self)
	{
        self.maximumTouchDistance = 0;
		self.translation = CGSizeMake(0,0);
		self.touch = nil;
    }

    return self;
}

-(bool) isValidPanTouch: (NSSet*)touches
{
	// If there is one touch we are panning.
	if ([touches count] == 1)
	{
		return true;
	}
	// If are two touches we are panning if the distance is small.
	else if ([touches count] >= 2)
	{
		NSArray* touchArray = [touches allObjects];
		FFRTouch* touch1 = [touchArray objectAtIndex: 0];
		FFRTouch* touch2 = [touchArray objectAtIndex: 1];
		CGFloat distance = [self
			distanceBetween: touch1.location
			andPoint: touch2.location];
		//NSLog(@"Distance in pan: %f", distance);
		if (distance < self.maximumTouchDistance)
		{
			return true;
		}
	}

	return true;
}

-(void) logTouchData: (NSSet*)touches
{
	// If there is one touch we are panning.
	if ([touches count] == 1)
	{
		return;
	}

	NSArray* touchArray = [touches allObjects];
	FFRTouch* touch1 = [touchArray objectAtIndex: 0];
	FFRTouch* touch2 = [touchArray objectAtIndex: 1];
	CGFloat distance = [self
			distanceBetween: touch1.location
			andPoint: touch2.location];
	NSLog(@"Dist: %f", distance);
	//NSLog(@"  pos1: %f %f", touch1.location.x, touch1.location.y);
	//NSLog(@"  pos2: %f %f", touch2.location.x, touch2.location.y);
}

- (void) touchesBegan: (NSSet*)touches
{
    LOGMETHOD

	//NSLog(@"touchesBegan: %i", (int)touches.count);

	NSArray* touchArray = [touches allObjects];

	if (self.touch == nil)
	{
		// Start tracking the first touch.
		self.touch = [touchArray objectAtIndex: 0];
		self.startPoint = self.touch.location;
		self.translation = CGSizeMake(0,0);
		self.state = UIGestureRecognizerStateBegan;
	}

	// Set backup touch.
	self.touch2 = nil;
	for (FFRTouch* touch in touches)
	{
		if (touch != self.touch)
		{
			//NSLog(@"  Got second touch point");
			self.touch2 = touch;
			break;
		}
	}
}

-(void) touchesMoved:(NSSet*)touches
{
    LOGMETHOD

	//[self logTouchData: touches];

	// Check that the tracked touch is valid.
	if (self.touch == nil || self.touch.phase != UITouchPhaseMoved)
	{
		return;
	}

/*
	// Check that any other touches are close enough for this
	// to be a panning gesture.
	if (! [self isValidPanTouch: touches])
	{
		return;
	}
*/
	self.translation = CGSizeMake(
		self.touch.location.x - self.startPoint.x,
		self.touch.location.y - self.startPoint.y);
	self.state = UIGestureRecognizerStateChanged;
	[self performAction];
}

-(void) touchesEnded: (NSSet*)touches
{
    LOGMETHOD

	//NSLog(@"touchesEnded: %i", (int)touches.count);

	for (FFRTouch* touch in touches)
	{
		assert(touch.phase == UITouchPhaseEnded);
	}

	if (self.touch != nil && self.touch.phase == UITouchPhaseEnded)
	{
		if (self.touch2 != nil && self.touch2.phase != UITouchPhaseEnded)
		{
			// Switch to second touch point.
			/*NSLog(@"  Swithing touch points offset: %i %i",
				(int)(self.touch2.location.x - self.touch.location.x),
				(int)(self.touch2.location.y - self.touch.location.y)
				);*/
			self.startPoint = CGPointMake(
				self.startPoint.x + (self.touch2.location.x - self.touch.location.x),
				self.startPoint.y + (self.touch2.location.y - self.touch.location.y));
			self.touch = self.touch2;
			self.touch2 = nil;
		}
		else
		{
			self.state = UIGestureRecognizerStateEnded;
			[self performAction];
			self.touch = nil;
		}
	}
}

@end
