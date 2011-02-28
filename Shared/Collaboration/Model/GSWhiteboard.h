/*
     File: Product.h
 Abstract: Simple class to represent a product, with a product type and name.
  Version: 1.4
 */
#import "GSConnection.h"

@protocol GSWhiteboard <NSObject>

- (id)initWithName:(NSString *)name;

- (NSString *)name;

- (GSConnectionType)type;

@optional

- (id)source;
- (id <GSConnection>)connection;
- (void)initiateConnection;
- (void)resetStateForNewConnection;
- (void)send:(NSString *)message;
- (void)sendLargeDataByChunks:(NSString*)message;
- (void)sendDisconnectMessage;
- (void)disconnect;
- (void)processStoredMessages;
@end


@interface GSWhiteboard : NSObject <GSWhiteboard>  {
	GSConnectionType _type;
	NSString *_name;
}
@property (nonatomic, assign) GSConnectionType type;
@property (nonatomic, copy) NSString *name;

+ (id)whiteboardWithType:(GSConnectionType)type name:(NSString *)name;
//+ (GSWhiteboard *)whiteboard:(NSString *)name source:(id)source;

+ (NSUInteger)whiteboardCount;

@end
