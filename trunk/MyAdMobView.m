/**
 * AdMobSampleProgrammaticAdAppDelegate.m
 * AdMob iPhone SDK publisher code.
 */

#import "AdMobView.h"
#import "MyAdMobView.h"

@implementation MyAdMobView

- (id)initWithFrame:(CGRect)frame {
	if ((self = [super initWithFrame:frame])) {
		// Request an ad
		[self requestAd:nil];
	}
	return self;
}

- (void)dealloc {
  [adMobAd release];
  //[window release];
  [super dealloc];
}

#pragma mark -
#pragma mark AdMobDelegate methods

- (NSString *)publisherId {
  return @"a1495733b0233f1"; // this should be prefilled; if not, get it from www.admob.com
}

- (UIColor *)adBackgroundColor {
  return [UIColor colorWithRed:0 green:0 blue:0 alpha:1]; // this should be prefilled; if not, provide a UIColor
}

- (UIColor *)adTextColor {
  return [UIColor colorWithRed:1 green:1 blue:1 alpha:1]; // this should be prefilled; if not, provide a UIColor
}

- (BOOL)mayAskForLocation {
	return NO;//YES; // this should be prefilled; if not, see AdMobProtocolDelegate.h for instructions
}

- (void)requestAd:(NSTimer *)timer {
	adMobAd = [AdMobView requestAdWithDelegate:self]; // start a new ad request
	[adMobAd retain]; // this will be released when it loads (or fails to load)
	//[self addSubview:adMobAd];
}

// Sent when an ad request loaded an ad; this is a good opportunity to attach
// the ad view to the hierachy.
- (void)didReceiveAd:(AdMobView *)adView {
	NSLog(@"AdMob: Did receive ad");
	adMobAd.frame = CGRectMake(0, 0/*432*/, 320, 48); // put the ad at the bottom of the screen
	[self addSubview:adMobAd];
	autoslider = [NSTimer scheduledTimerWithTimeInterval:AD_REFRESH_PERIOD target:self selector:@selector(refreshAd:) userInfo:nil repeats:YES];
	NSLog(@"AdMob: Finished displaying ad");
}

// Request a new ad. If a new ad is successfully loaded, it will be animated into location.
- (void)refreshAd:(NSTimer *)timer {
  [adMobAd requestFreshAd];
}

// Sent when an ad request failed to load an ad
- (void)didFailToReceiveAd:(AdMobView *)adView {
	NSLog(@"AdMob: Did fail to receive ad");
	[adMobAd release];
	adMobAd = nil;
	// we could start a new ad request here, but in the interests of the user's battery life, let's not

	[NSTimer scheduledTimerWithTimeInterval:AD_REFRESH_PERIOD target:self selector:@selector(requestAd:) userInfo:nil repeats:NO];
	
	// Request an ad
	//adMobAd = [AdMobView requestAdWithDelegate:self]; // start a new ad request
	//[adMobAd retain]; // this will be released when it loads (or fails to load)	
}
/*
- (BOOL)useTestAd {
	return YES;
}
*/
@end