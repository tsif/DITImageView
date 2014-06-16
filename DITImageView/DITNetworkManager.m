/*
 * DITNetworkManager.m
 */


#import "DITNetworkManager.h"

NSString *const kNetworkStateChangedNotification = @"kNetworkStateChangedNotification";
NSString *const kNetworkStateChangedKey          = @"kNetworkStateChangedKey";

static DITNetworkManager *_defaultManager           = NULL;

/* Network monitoring callback */
static void NetworkReachabilityCallback(SCNetworkReachabilityRef	target, SCNetworkReachabilityFlags	flags, void *info) {
    
    BOOL isReachable     = flags & kSCNetworkFlagsReachable;
    BOOL needsConnection = flags & kSCNetworkFlagsConnectionRequired;
    
	DITNetworkManager *tmpManager = (__bridge DITNetworkManager*)info;
	
    if (isReachable && !needsConnection) {
		tmpManager.hasNetwork = YES;
		[[NSNotificationCenter defaultCenter] postNotificationName:kNetworkStateChangedNotification object:nil userInfo:
         [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:kNetworkStateChangedKey]];
	} else {
		tmpManager.hasNetwork = NO;		
		[[NSNotificationCenter defaultCenter] postNotificationName:kNetworkStateChangedNotification object:nil userInfo:
         [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:kNetworkStateChangedKey]];
	} 
    
    SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithName(NULL, [@"google.com" UTF8String]);
    SCNetworkReachabilityGetFlags(reachability, &flags);
    
    tmpManager.networkStatus = NotReachable;
	if ((flags & kSCNetworkReachabilityFlagsConnectionRequired) == 0) 	{
		/* if target host is reachable and no connection is required then we'll assume (for now) that your on Wi-Fi */
		tmpManager.networkStatus = ReachableViaWiFi;
	}
	
	
	if ((((flags & kSCNetworkReachabilityFlagsConnectionOnDemand ) != 0) ||
         (flags & kSCNetworkReachabilityFlagsConnectionOnTraffic) != 0)) {
        // and the connection is on-demand (or on-traffic) if the
        // calling application is using the CFSocketStream or higher APIs         
        if ((flags & kSCNetworkReachabilityFlagsInterventionRequired) == 0) {
            /* and no [user] intervention is needed */
            tmpManager.networkStatus = ReachableViaWiFi;
        }
    }
	
	if ((flags & kSCNetworkReachabilityFlagsIsWWAN) == kSCNetworkReachabilityFlagsIsWWAN) {
		// but WWAN connections are OK if the calling application
		// is using the CFNetwork (CFSocketStream?) APIs.
		tmpManager.networkStatus = ReachableViaWWAN;
	}
}

@interface DITNetworkManager()
-(void)_removeNetworkMonitoring;
-(void)_postInitialStateNotification;
@end

@implementation DITNetworkManager

@synthesize hasNetwork    = _hasNetwork;
@synthesize networkStatus = _networkStatus;

#pragma mark - LIFE CYCLE

/* Access to singleton */
+ (DITNetworkManager*)defaultManager {    
    
	@synchronized (self) {
		if (_defaultManager == nil) {
			_defaultManager = [[DITNetworkManager alloc] init];
		}
	}
    return _defaultManager;
}

- (id)init {
    
    self = [super init];
    if (self) {
        _hasNetwork = YES;
    }    
    
    return self;
}

#pragma mark == NETWORK MONITORING ==

- (BOOL) installNetworkMonitoring {
    
    BOOL result = YES;
	Boolean tmpBool;
	struct sockaddr_in zeroAddress;
	SCNetworkReachabilityContext context = {0, (__bridge void *) self, NULL, NULL, NULL};
	SCNetworkReachabilityFlags	flags;
    
	
	/* the assumption is that this can not be done twice */
	if(_networkAccessReachability) { 
        result = NO; 
        return result; 
    } 
	
	/* install reachability on address 0.0.0.0 */
    bzero(&zeroAddress, sizeof(zeroAddress));
    zeroAddress.sin_len = sizeof(zeroAddress);
    zeroAddress.sin_family = AF_INET;		    
    _networkAccessReachability = SCNetworkReachabilityCreateWithAddress(NULL, (struct sockaddr *)&zeroAddress);
	if(!_networkAccessReachability) { 
        result = NO; 
        return result; 
    } 
	
	/* set callback and schedule it on the runloop */
	tmpBool = SCNetworkReachabilitySetCallback(_networkAccessReachability, NetworkReachabilityCallback, &context);
	if(!tmpBool) { 
		result = NO; 
        return result; 
    } 
	
    tmpBool = SCNetworkReachabilityScheduleWithRunLoop(_networkAccessReachability, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
	if(!tmpBool) { 
        result = NO;
        return result; 
    } 
	
	tmpBool = SCNetworkReachabilityScheduleWithRunLoop(_networkAccessReachability, CFRunLoopGetCurrent(), (CFStringRef) UITrackingRunLoopMode);
	if(!tmpBool) { 
        result = NO; 
        return result; 
    } 
    
	tmpBool = SCNetworkReachabilityGetFlags(_networkAccessReachability, &flags);
	if(!tmpBool) { 
        result = NO; 
        return result; 
    } 
	
	BOOL isReachable = flags & kSCNetworkFlagsReachable;
    BOOL needsConnection = flags & kSCNetworkFlagsConnectionRequired;
    self.hasNetwork = (isReachable && !needsConnection) ? YES : NO;
	
    SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithName(NULL, [@"google.com" UTF8String]);
    SCNetworkReachabilityGetFlags(reachability, &flags);
    
    self.networkStatus = NotReachable;
	if ((flags & kSCNetworkReachabilityFlagsConnectionRequired) == 0) 	{
		/* if target host is reachable and no connection is required then we'll assume (for now) that your on Wi-Fi */
		self.networkStatus = ReachableViaWiFi;
	}
	
	
	if ((((flags & kSCNetworkReachabilityFlagsConnectionOnDemand ) != 0) ||
         (flags & kSCNetworkReachabilityFlagsConnectionOnTraffic) != 0)) {
        // and the connection is on-demand (or on-traffic) if the
        // calling application is using the CFSocketStream or higher APIs         
        if ((flags & kSCNetworkReachabilityFlagsInterventionRequired) == 0) {
            /* and no [user] intervention is needed */
            self.networkStatus = ReachableViaWiFi;
        }
    }
	
	if ((flags & kSCNetworkReachabilityFlagsIsWWAN) == kSCNetworkReachabilityFlagsIsWWAN) {
		// but WWAN connections are OK if the calling application
		// is using the CFNetwork (CFSocketStream?) APIs.
		self.networkStatus = ReachableViaWWAN;
	}
    
    [self performSelector:@selector(_postInitialStateNotification) withObject:nil afterDelay:0.1f];
    
	return result;	
}

-(void)_postInitialStateNotification {
    
    if(self.hasNetwork == YES) {
		[[NSNotificationCenter defaultCenter] postNotificationName:kNetworkStateChangedNotification object:nil userInfo:
         [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:kNetworkStateChangedKey]];
	} else {
		[[NSNotificationCenter defaultCenter] postNotificationName:kNetworkStateChangedNotification object:nil userInfo:
         [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:kNetworkStateChangedKey]];
	}     
}

/* Remove installed reachability and set it to NULL  */
-(void) _removeNetworkMonitoring {
    
	Boolean tmpBool;
	
	if(_networkAccessReachability) {
		tmpBool = SCNetworkReachabilityUnscheduleFromRunLoop(_networkAccessReachability, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
		if(!tmpBool) { 
        } 
		
		tmpBool = SCNetworkReachabilityUnscheduleFromRunLoop(_networkAccessReachability, CFRunLoopGetCurrent(), (CFStringRef) UITrackingRunLoopMode);
		if(!tmpBool) { 
        } 
		
		tmpBool = SCNetworkReachabilitySetCallback(_networkAccessReachability, NULL, NULL);
		if(!tmpBool) { 
        } 
		
		CFRelease(_networkAccessReachability);			
		_networkAccessReachability = NULL;
		
	}
}

@end
