package com.sTealth.wifi_direct_share

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.net.Uri
import android.os.Parcelable

class MainActivity: FlutterActivity() {
  override fun onCreate(savedInstanceState: Bundle?) {

     if (intent.getIntExtra("org.chromium.chrome.extra.TASK_ID", -1) == this.taskId) {
         this.finish()
         intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
         startActivity(intent);
     }
     super.onCreate(savedInstanceState)
 }
}
