//
//  CCNetworkConnectivity.h
//  cocos2d_libs
//
//  Created by mystery on 20/04/2017.
//
//

#ifndef CCNetworkConnectivity_h
#define CCNetworkConnectivity_h

#include "platform/CCPlatformMacros.h"

NS_CC_BEGIN

class CC_DLL NetworkConnectivity
{
public:
    static bool isConnected();
    
private:
    CC_DISALLOW_IMPLICIT_CONSTRUCTORS(NetworkConnectivity);
};

NS_CC_END

#endif /* CCNetworkConnectivity_h */
