/**
 * AdMobSampleProgrammaticAdAppDelegate.h
 * AdMob iPhone SDK publisher code.
 */

#define AD_REFRESH_PERIOD 60.0 // display fresh ads once per minute

#import <UIKit/UIKit.h>
#import "AdMobDelegateProtocol.h";

@class AdMobView;

@interface MyAdMobView : UIView <AdMobDelegate> {

  AdMobView *adMobAd;   // the actual ad; self.view is the location where the ad will be placed
  NSTimer *autoslider; // timer to slide in fresh ads

}

- (void)requestAd:(NSTimer *)timer;

@end