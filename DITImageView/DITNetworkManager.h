/*
 * DITNetworkManager.h
 */


#include <netinet/in.h>

#import <Foundation/Foundation.h>
#import <SystemConfiguration/SystemConfiguration.h>

extern NSString *const kNetworkStateChangedNotification;
extern NSString *const kNetworkStateChangedKey;

typedef enum {
	NotReachable = 0,
	ReachableViaWiFi,
	ReachableViaWWAN
} NetworkStatus;

/* Network state machine constants */
enum {
	kNetworkManagerDisconnected = 0, 	
	kNetworkManagerConnected    = 1
};

@interface DITNetworkManager : NSObject {
    
    SCNetworkReachabilityRef _networkAccessReachability;
    BOOL                     _hasNetwork;
    NetworkStatus            _networkStatus;
}

@property(assign) BOOL          hasNetwork;
@property(assign) NetworkStatus networkStatus;

/* Singleton access */
+ (DITNetworkManager*)defaultManager;

/* listen to network state related notifications on address 0.0.0.0 */
- (BOOL)installNetworkMonitoring;

@end
