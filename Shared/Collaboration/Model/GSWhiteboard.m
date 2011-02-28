
#import "GSWhiteboard.h"
#import APP_DELEGATE
#import "GSConnectionController.h"
#import "GSLocalWhiteboard.h"
#if INTERNET_INCLUDING
#import "GSInternetWhiteboard.h"
#import "GSInternetConnection.h"
#endif
#import "GSWhiteboardUser.h"

@implementation GSWhiteboard

@synthesize type = _type, name = _name;

// backward compatibility - will remove
+ (id)whiteboardWithType:(GSConnectionType)type name:(NSString *)name {
	if (type == GSConnectionTypeLocal) {
		return [[GSLocalWhiteboard alloc] initWithName:name];
	} 
#if INTERNET_INCLUDING	
	else if (type == GSConnectionTypeInternet) {
		return [[GSInternetWhiteboard alloc] initWithName:name];
	}
#endif
	return nil;
//	GSWhiteboard *newProduct = [[[self alloc] init] autorelease];
//	newProduct.type = type;
//	newProduct.name = name;
//	return newProduct;
}

static int whiteboardCount = 0;
- (id)init {
	if ((self = [super init])) {
		whiteboardCount ++;
	}
	return self;
}

- (id)initWithName:(NSString *)name {
	if ((self = [self init])) {
		_name = [name copy];
	}
	return self;
}


- (void)dealloc
{
	[_name release];
	whiteboardCount --;
	[super dealloc];
}

+ (NSUInteger)whiteboardCount {
	return whiteboardCount;
}

- (NSString *)description {
	return [NSString stringWithFormat:@"WB: type: %d; name: %@", _type, _name];
}

@end


