package org.cocos2dx.lib;

import android.content.Context;
import android.net.ConnectivityManager;
import android.net.NetworkInfo;
import android.telephony.TelephonyManager;

public class Cocos2dxNetworkConnectivity {
	private static final String TAG = "Cocos2dxNetworkConnectivity";

	private final Context mContext;

	public Cocos2dxNetworkConnectivity(final Context context) {
		this.mContext = context;
	}

	public NetworkInfo getNetworkInfo() {
		ConnectivityManager connectivityManager = (ConnectivityManager)this.mContext.getSystemService(Context.CONNECTIVITY_SERVICE);
		return connectivityManager.getActiveNetworkInfo();
	}

	public boolean isConnected() {
		NetworkInfo info = this.getNetworkInfo();
		return (info != null && info.isConnected());
	}
}