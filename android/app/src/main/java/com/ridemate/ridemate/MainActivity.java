package com.ridemate.ridemate;

import android.content.Intent;
import io.flutter.embedding.android.FlutterFragmentActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterFragmentActivity {
    private static final String CHANNEL = "com.ridemate.stripe/payment";

    @Override
    public void configureFlutterEngine(FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
                .setMethodCallHandler((call, result) -> {
                    if (call.method.equals("startStripePayment")) {
                        int amount = call.argument("amount");
                        String applicantId = call.argument("applicantId");
                        String shiftId = call.argument("shiftId");
                        String ownerId = call.argument("ownerId");

                        Intent intent = new Intent(this, StripeActivity.class);
                        intent.putExtra("amount", amount);
                        intent.putExtra("applicantId", applicantId);
                        intent.putExtra("shiftId", shiftId);
                        intent.putExtra("ownerId", ownerId);

                        startActivity(intent);
                        result.success("launched");
                    } else {
                        result.notImplemented();
                    }
                });
    }
}
