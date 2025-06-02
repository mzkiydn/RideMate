package com.ridemate.ridemate;

import android.content.Intent;
import androidx.activity.result.ActivityResultLauncher;
import androidx.activity.result.contract.ActivityResultContracts;
import io.flutter.embedding.android.FlutterFragmentActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;
import androidx.annotation.NonNull;

public class MainActivity extends FlutterFragmentActivity {
    private static final String CHANNEL = "com.ridemate.stripe/payment";
    private MethodChannel.Result pendingResult;

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), "com.ridemate.stripe/payment")
                .setMethodCallHandler((call, result) -> {
                    if (call.method.equals("startStripePayment")) {
                        String amount = (String) call.argument("amount");
                        String applicantId = (String) call.argument("applicantId");
                        String shiftId = (String) call.argument("shiftId");
                        String ownerId = (String) call.argument("ownerId");

                        Intent intent = new Intent(this, StripeActivity.class);
                        intent.putExtra("amount", amount);
                        intent.putExtra("applicantId", applicantId);
                        intent.putExtra("shiftId", shiftId);
                        intent.putExtra("ownerId", ownerId);
                        startActivityForResult(intent, 1);
                    } else {
                        result.notImplemented();
                    }
                });

    }

    private final ActivityResultLauncher<Intent> launcher =
            registerForActivityResult(new ActivityResultContracts.StartActivityForResult(), result -> {
                if (pendingResult != null) {
                    if (result.getResultCode() == RESULT_OK) {
                        pendingResult.success(true);
                    } else {
                        pendingResult.success(false);
                    }
                    pendingResult = null;
                }
            });
}
