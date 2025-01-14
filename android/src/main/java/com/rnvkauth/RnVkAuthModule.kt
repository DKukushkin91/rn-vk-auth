package com.rnvkauth

import android.view.ViewGroup
import com.facebook.react.bridge.Callback
import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.module.annotations.ReactModule
import com.vk.id.VKID
import com.vk.id.onetap.xml.OneTapBottomSheet

@ReactModule(name = RnVkAuthModule.NAME)
class RnVkAuthModule(reactContext: ReactApplicationContext) : NativeRnVkAuthSpec(reactContext) {
  override fun getName() = NAME

  override fun initialize(params: ReadableMap, promise: Promise) {
    if (params.hasKey("loggingEnabled")) {
      VKID.logsEnabled = params.getBoolean("loggingEnabled")
      promise.resolve("VKID initialize success")
    } else {
      promise.reject("VKID", "initialize error")
    }
  }

  override fun toggleOneTapBottomSheet(
    params: ReadableMap,
    fetchApi: Callback,
    promise: Promise
  ) {
    val currentActivity = reactApplicationContext.currentActivity

    if (currentActivity === null) {
      promise.reject("VKID", "Activity is null")
      return
    }

    currentActivity.runOnUiThread {
      try {
        val rootView = currentActivity.findViewById<ViewGroup>(android.R.id.content)

        val existingBottomSheet = rootView.findViewById<OneTapBottomSheet>(R.id.vkid_bottom_sheet)

        if (existingBottomSheet != null) {
          rootView.removeView(existingBottomSheet)
        }

        val bottomSheetView =  OneTapBottomSheet(currentActivity)
        bottomSheetView.id = R.id.vkid_bottom_sheet

        rootView.addView(bottomSheetView)

        bottomSheetView.show()
      } catch (error: Exception) {
        promise.reject("OneTapBottomSheet", "Failed to toggle bottom sheet ${error.message}")
      }
    }
  }

  override fun logout(promise: Promise?) {
    TODO("Not yet implemented")
  }


  companion object {
    const val NAME = "RnVkAuth"
  }
}
