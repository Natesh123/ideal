package co.idealtraders.userapp

import android.os.Bundle
import androidx.activity.enableEdgeToEdge
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // enableEdgeToEdge() must be called before super.onCreate()
        // This replaces the deprecated setStatusBarColor / setNavigationBarColor APIs
        // and satisfies the Android 15 edge-to-edge requirement.
        enableEdgeToEdge()
        super.onCreate(savedInstanceState)
    }
}