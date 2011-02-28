@interface NSString (GSURL)
- (NSString *)escapedURLString;
@end

@implementation NSString (GSURL)
- (NSString *)escapedURLString {
	CFStringRef value = (CFStringRef)[self copy];
	// Escape even the "reserved" characters for URLs 
	// as defined in http://www.ietf.org/rfc/rfc2396.txt
	CFStringRef encodedValue = CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, 
																	   value,
																	   NULL, 
																	   (CFStringRef)@";/?:@&=+$,", 
																	   kCFStringEncodingUTF8);
	NSString *escapedString = [NSString stringWithFormat:@"%@", encodedValue];
	CFRelease(value);
	CFRelease(encodedValue);
	return escapedString;
}
@end