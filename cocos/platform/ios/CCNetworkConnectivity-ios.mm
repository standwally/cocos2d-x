//
//  CCNetworkConnectivity-ios.mm
//  cocos2d_libs
//
//  Created by mystery on 20/04/2017.
//
//

#include "platform/CCPlatformConfig.h"
#if CC_TARGET_PLATFORM == CC_PLATFORM_IOS

#include "platform/CCNetworkConnectivity.h"
#include "Reachability.h"

NS_CC_BEGIN

bool NetworkConnectivity::isConnected()
{
    Reachability *reachability = [Reachability reachabilityForInternetConnection];
    [reachability startNotifier];
    
    NetworkStatus status = [reachability currentReachabilityStatus];
    
    if (status == NotReachable)
    {
        return false;
    }
    else if (status == ReachableViaWiFi)
    {
        return true;
    }
    else if (status == ReachableViaWWAN)
    {
        return true;
    }
    
    return false;
}

NS_CC_END

#endif // CC_PLATFORM_IOS
