/*

File: TCPServer.h
Abstract: A TCP server that listens on an arbitrary port.
 
 Based on the way this class has been used in the past (I'm not 100% about this):
 To start the server, call -start:, then -enableBonjourWithDomain:applicationProtocol:name:
 To stop  the server, call -stop
 
*/

#import <Foundation/Foundation.h>

//CLASSES:

@class TCPServer;

//ERRORS:

//NSString * const TCPServerErrorDomain;

typedef enum {
    kTCPServerCouldNotBindToIPv4Address = 1,
    kTCPServerCouldNotBindToIPv6Address = 2,
    kTCPServerNoSocketsAvailable = 3,
} TCPServerErrorCode;

//PROTOCOLS:

@protocol TCPServerDelegate <NSObject>
@optional
- (void) serverDidEnableBonjour:(TCPServer*)server withName:(NSString*)name;
- (void) server:(TCPServer*)server didNotEnableBonjour:(NSDictionary *)errorDict;
- (void) didAcceptConnectionForServer:(TCPServer*)server inputStream:(NSInputStream *)istr outputStream:(NSOutputStream *)ostr;
@end

//CLASS INTERFACES:

// TODO: make sure we implement NSNetServiceDelegate methods
@interface TCPServer : NSObject <NSNetServiceDelegate> {
@private
	id _delegate;
    uint16_t _port;
	CFSocketRef _ipv4socket;
	NSNetService* _netService;
}

- (BOOL)isStopped;
- (BOOL)start:(NSError **)error;
- (BOOL)stop;
- (BOOL)enableBonjourWithDomain:(NSString*)domain applicationProtocol:(NSString*)protocol name:(NSString*)name; //Pass "nil" for the default local domain - Pass only the application protocol for "protocol" e.g. "myApp"
- (void)disableBonjour;

@property(assign) id<TCPServerDelegate> delegate;

+ (NSString*) bonjourTypeFromIdentifier:(NSString*)identifier;

@end
