package com.ridemate.ridemate;

import android.content.Intent;
import android.os.Bundle;
import androidx.activity.ComponentActivity;

import com.stripe.android.PaymentConfiguration;
import com.stripe.android.paymentsheet.PaymentSheet;
import com.stripe.android.paymentsheet.PaymentSheetResult;

public class StripeActivity extends ComponentActivity {

    private PaymentSheet paymentSheet;
    private String clientSecret = "SecretKey";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        PaymentConfiguration.init(
                getApplicationContext(),
                "pk_test_51RIw55R0B0Zzi8hZV4ag1Iwk1wKcnVpD4acBDsITfyGgyznwLoeqEvBedMVqWM0sEbGDchiPx1xLyfzLICYxQrfJ00vmhMzCOy"
        );

        paymentSheet = new PaymentSheet(this, this::onPaymentSheetResult);

        paymentSheet.presentWithPaymentIntent(
                clientSecret,
                new PaymentSheet.Configuration("RideMate Payment")
        );
    }

    private void onPaymentSheetResult(PaymentSheetResult result) {
        Intent returnIntent = new Intent();

        if (result instanceof PaymentSheetResult.Completed) {
            setResult(RESULT_OK, returnIntent);
        } else {
            setResult(RESULT_CANCELED, returnIntent);
        }

        finish();
    }
}
