package com.justonedev.BoxBreathe

import com.ryanheise.audioservice.AudioServiceActivity

// audio_service requires the activity to provide its shared FlutterEngine —
// AudioServiceActivity supplies that; a plain FlutterActivity throws
// "The Activity class declared in your AndroidManifest.xml is wrong..."
// as soon as AudioService.init() runs.
class MainActivity : AudioServiceActivity()
