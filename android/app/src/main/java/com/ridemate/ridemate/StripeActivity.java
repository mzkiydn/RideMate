package com.ridemate.ridemate;

import android.content.Intent;
import android.os.Bundle;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import io.flutter.embedding.android.FlutterFragmentActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.dart.DartExecutor;
import io.flutter.plugin.common.MethodChannel;

import com.stripe.android.PaymentConfiguration;
import com.stripe.android.paymentsheet.PaymentSheet;
import com.stripe.android.paymentsheet.PaymentSheetResult;

public class StripeActivity extends FlutterFragmentActivity {

    private static final String CHANNEL = "com.ridemate.ridemate/payment";
    private MethodChannel.Result pendingResult;
    private PaymentSheet paymentSheet;
    private String clientSecret;
    private FlutterEngine flutterEngine;

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        // ✅ Stripe init
        PaymentConfiguration.init(
                getApplicationContext(),
                "pk_test_51RIw55R0B0Zzi8hZV4ag1Iwk1wKcnVpD4acBDsITfyGgyznwLoeqEvBedMVqWM0sEbGDchiPx1xLyfzLICYxQrfJ00vmhMzCOy"
        );

        clientSecret = getIntent().getStringExtra("clientSecret");
        paymentSheet = new PaymentSheet(this, this::onPaymentSheetResult);

        // ✅ Manually create FlutterEngine and set a secondary entrypoint
        flutterEngine = new FlutterEngine(this);

        DartExecutor.DartEntrypoint dartEntrypoint =
                new DartExecutor.DartEntrypoint("flutter_assets/lib/stripe_entrypoint.dart", "stripeMain");

        flutterEngine.getDartExecutor().executeDartEntrypoint(dartEntrypoint);

        // ✅ Setup MethodChannel
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
                .setMethodCallHandler((call, result) -> {
                    if (call.method.equals("startStripeActivity")) {
                        pendingResult = result;
                        startStripePayment();
                    } else {
                        result.notImplemented();
                    }
                });
    }

    private void startStripePayment() {
        paymentSheet.presentWithPaymentIntent(
                clientSecret,
                new PaymentSheet.Configuration("RideMate Payment")
        );
    }

    private void onPaymentSheetResult(@NonNull PaymentSheetResult paymentSheetResult) {
        if (pendingResult == null) return;

        if (paymentSheetResult instanceof PaymentSheetResult.Completed) {
            pendingResult.success("success");
        } else if (paymentSheetResult instanceof PaymentSheetResult.Canceled) {
            pendingResult.error("canceled", "Payment canceled", null);
        } else if (paymentSheetResult instanceof PaymentSheetResult.Failed) {
            PaymentSheetResult.Failed failed = (PaymentSheetResult.Failed) paymentSheetResult;
            pendingResult.error("failed", failed.getError().getMessage(), null);
        }
        pendingResult = null;
        finish();
    }

    @Override
    protected void onDestroy() {
        if (flutterEngine != null) {
            flutterEngine.destroy();
        }
        super.onDestroy();
    }
}
