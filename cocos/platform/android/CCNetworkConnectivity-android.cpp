#include "platform/CCPlatformConfig.h"
#if CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID

#include "platform/CCNetworkConnectivity.h"
#include <string.h>
#include <android/log.h>
#include <jni.h>
#include "platform/android/jni/JniHelper.h"

static const std::string helperClassName = "org/cocos2dx/lib/Cocos2dxHelper";

NS_CC_BEGIN

bool NetworkConnectivity::isConnected()
{
	return JniHelper::callStaticBooleanMethod(helperClassName, "isConnected");
}

NS_CC_END

#endif // CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID