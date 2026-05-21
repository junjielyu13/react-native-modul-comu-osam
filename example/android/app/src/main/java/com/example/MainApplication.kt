package com.example

import android.app.Application
import com.facebook.react.PackageList
import com.facebook.react.ReactApplication
import com.facebook.react.ReactHost
import com.facebook.react.ReactNativeApplicationEntryPoint.loadReactNative
import com.facebook.react.defaults.DefaultReactHost.getDefaultReactHost
import cat.bcn.osam.reactnative.DefaultOSAMWrappersFactory
import cat.bcn.osam.reactnative.OSAMConfiguration

class MainApplication : Application(), ReactApplication {

  override val reactHost: ReactHost by lazy {
    getDefaultReactHost(
      context = applicationContext,
      packageList =
        PackageList(this).packages.apply {
          // Packages that cannot be autolinked yet can be added manually here, for example:
          // add(MyReactNativePackage())
        },
    )
  }

  override fun onCreate() {
    super.onCreate()
    // Must run before loadReactNative — OSAMPackage's no-arg constructor reads
    // OSAMConfiguration.wrappersFactory at construction time, which happens
    // when reactHost is first accessed inside loadReactNative.
    OSAMConfiguration.wrappersFactory = DefaultOSAMWrappersFactory(debug = true)
    loadReactNative(this)
  }
}
