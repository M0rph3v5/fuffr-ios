//
//  AppViewController.m
//  FuffrBox
//
//  Created by Fuffr on 21/03/14.
//  Copyright (c) 2014 Fuffr. All rights reserved.
//

#import "AppViewController.h"

#import <FuffrLib/FFRTapGestureRecognizer.h>
#import <FuffrLib/FFRLongPressGestureRecognizer.h>
#import <FuffrLib/FFRSwipeGestureRecognizer.h>
#import <FuffrLib/FFRPinchGestureRecognizer.h>
#import <FuffrLib/FFRPanGestureRecognizer.h>
#import <FuffrLib/FFRRotationGestureRecognizer.h>
#import <FuffrLib/FFRLeftRightPluggableGestureRecognizer.h>

@implementation AppViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        // Add custom initialization if needed.
    }
    return self;
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

	CGRect bounds;

	CGRect viewBounds = self.view.bounds;

	CGFloat toolbarOffsetY = 0;
	CGFloat toolbarHeight = 40;

	// Back button.

	UIButton* buttonBack = [UIButton buttonWithType: UIButtonTypeSystem];
    [buttonBack setFrame: CGRectMake(3, toolbarOffsetY, 40, toolbarHeight)];
	[buttonBack setTitle: @"Back" forState: UIControlStateNormal];
	[buttonBack
		addTarget: self
		action: @selector(onButtonBack:)
		forControlEvents: UIControlEventTouchUpInside];
    [self.view addSubview: buttonBack];

	// URL field.

	bounds = CGRectMake(50, toolbarOffsetY + 1, 0, toolbarHeight);
	bounds.size.width = viewBounds.size.width - 90;
	self.urlField = [[UITextField alloc] initWithFrame: bounds];
	[self setSavedURL];
	self.urlField.clearButtonMode = UITextFieldViewModeNever;
	[self.urlField setKeyboardType: UIKeyboardTypeURL];
	self.urlField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    [self.view addSubview: self.urlField];

	// Go button.

	bounds = CGRectMake(0, toolbarOffsetY, 40, toolbarHeight);
	bounds.origin.x = viewBounds.size.width - 40;
	UIButton* buttonGo = [UIButton buttonWithType: UIButtonTypeSystem];
    [buttonGo setFrame: bounds];
	[buttonGo setTitle: @"Go" forState: UIControlStateNormal];
	[buttonGo
		addTarget: self
		action: @selector(onButtonGo:)
		forControlEvents: UIControlEventTouchUpInside];
    [self.view addSubview: buttonGo];

	// Web view.

	bounds = viewBounds;
	//bounds = CGRectOffset(bounds, 0, 20);
	//bounds = CGRectInset(bounds, 0, 50);
	bounds.origin.y = toolbarHeight;
	bounds.size.height -= bounds.origin.y;

	self.webView = [[UIWebView alloc] initWithFrame: bounds];

	// Set properties of the web view.
    self.webView.autoresizingMask =
		UIViewAutoresizingFlexibleHeight |
		UIViewAutoresizingFlexibleWidth;
	self.webView.scalesPageToFit = NO; //YES;
	// http://stackoverflow.com/questions/2442727/strange-padding-margin-when-using-uiwebview
	// http://stackoverflow.com/questions/18947872/ios7-added-new-whitespace-in-uiwebview-removing-uiwebview-whitespace-in-ios7
	self.automaticallyAdjustsScrollViewInsets = NO;
	self.webView.scrollView.bounces = NO;
	[self.webView setBackgroundColor:[UIColor greenColor]];
	[self.webView loadHTMLString:@"<html><body style='background:rgb(100,200,255);font-family:sans-serif;'><h1>Welcome to FuffrBox</h1><h3>Play games and make your own apps for Fuffr!</h3><h3>Enter url to page and select go.</h3></body></html>" baseURL:nil];

    [self.view addSubview: self.webView];

	self.view.multipleTouchEnabled = YES;
}

#pragma clang diagnostic push
#pragma GCC diagnostic ignored "-Wundeclared-selector"

-(void) enableWebGL
{
	id webDocumentView = [self.webView performSelector: @selector(_browserView)];
    id backingWebView = [webDocumentView performSelector: @selector(webView)];

	// Cannot use performSelector: since _setWebGLEnabled: takes
	// a primitibe BOOL param. Therefore using NSInvocation.
	// Compiler raises error if sending _setWebGLEnabled: in the normal way.
	SEL selector = NSSelectorFromString(@"_setWebGLEnabled:");
	BOOL flag = YES;
	void* value = &flag;
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:
		[backingWebView methodSignatureForSelector: selector]];
    [invocation setSelector: selector];
    [invocation setTarget: backingWebView];
    [invocation setArgument: value atIndex: 2];
    [invocation invoke];
}

#pragma clang diagnostic pop

-(void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear: animated];

	[self enableWebGL];

	// Connect to Fuffr and setup touch events.
	[self setupFuffr];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void) setupFuffr
{
	[self connectToFuffr];
	[self setupTouches];
}

- (void) connectToFuffr
{
	// Get a reference to the touch manager.
	FFRTouchManager* manager = [FFRTouchManager sharedManager];

	// Connect to Fuffr, the onSuccess method will be
	// called when connection is established.
	// Support for onError is not complete.
	[manager
		connectToFuffrNotifying: self
		onSuccess: @selector(fuffrConnected)
		onError: nil];
}

- (void) setupTouches
{
	//[[FFRTouchManager sharedManager] unregisterTouchMethods];

    [[NSNotificationCenter defaultCenter]
		addObserver: self
		selector: @selector(touchesBegan:)
		name: FFRTrackingBeganNotification
		object: nil];
    [[NSNotificationCenter defaultCenter]
		addObserver: self
		selector: @selector(touchesMoved:)
		name: FFRTrackingMovedNotification
		object: nil];
    [[NSNotificationCenter defaultCenter]
		addObserver: self
		selector: @selector(touchesEnded:)
		name: FFRTrackingEndedNotification
		object: nil];
}

- (void) onButtonBack: (id)sender
{
	[self.webView goBack];
}

- (void) onButtonGo: (id)sender
{
	[self.view endEditing: YES];

	NSString* urlString = self.urlField.text;

	if (![urlString hasPrefix: @"http://"])
	{
		urlString = [NSString stringWithFormat:@"http://%@", urlString];
	}

	[self saveURL: urlString];

	NSURL* url = [NSURL URLWithString: urlString];
	NSURLRequest* request = [NSURLRequest
		requestWithURL: url
		cachePolicy: NSURLRequestReloadIgnoringLocalAndRemoteCacheData
		timeoutInterval: 10];
	[self.webView loadRequest: request];
}

- (void) saveURL: (NSString*)url
{
	[[NSUserDefaults standardUserDefaults]
		setObject: url
		forKey: @"FuffrBoxSavedURL"];
}

- (void) setSavedURL
{
	NSString* url = [[NSUserDefaults standardUserDefaults]
		stringForKey: @"FuffrBoxSavedURL"];
	if (url)
	{
		self.urlField.text = url;
	}
	else
	{
		self.urlField.text = @"fuffr.com";
	}
}

- (void) fuffrConnected
{
	NSLog(@"fuffrConnected");
}

- (void) touchesBegan: (NSNotification*)data
{
    NSSet* touches = data.object;
	[self callJS: @"fuffr.onTouchesBegan" withTouches: touches];
}

- (void) touchesMoved: (NSNotification*)data
{
    NSSet* touches = data.object;
	[self callJS: @"fuffr.onTouchesMoved" withTouches: touches];
}

- (void) touchesEnded: (NSNotification*)data
{
    NSSet* touches = data.object;
	[self callJS: @"fuffr.onTouchesEnded" withTouches: touches];
}

// Example call: fuffr.onTouchesBegan([{...},{...},...])
- (void)callJS: (NSString*) functionName withTouches: (NSSet*)touches
{
	NSString* script = [NSString stringWithFormat:
		@"try{%@(%@)}catch(err){}",
		functionName,
		[self touchesAsJsArray: touches]];
NSLog(@"calljs %@", functionName);
	dispatch_async(dispatch_get_main_queue(),
	^{
		[self.webView stringByEvaluatingJavaScriptFromString: script];
    });
}

- (NSString*) touchesAsJsArray: (NSSet*)touches
{
	NSMutableString* arrayString = [NSMutableString stringWithCapacity: 300];

	[arrayString appendString: @"["];

	int counter = (int)touches.count;
	for (FFRTouch* touch in touches)
	{
		[arrayString appendString: [self touchAsJsObject: touch]];
		if (--counter > 0)
		{
			[arrayString appendString: @","];
		}
	}

	[arrayString appendString: @"]"];

	return arrayString;
}

- (NSString*) touchAsJsObject: (FFRTouch*)touch
{
	return [NSString stringWithFormat:
		@"{id:%d,side:%d,x:%f,y:%f,prevx:%f,prevy:%f,normx:%f,normy:%f}",
		(int)touch.identifier,
		touch.side,
		touch.location.x,
		touch.location.y,
		touch.previousLocation.x,
		touch.previousLocation.y,
		touch.normalizedLocation.x,
		touch.normalizedLocation.y];
}

@end
