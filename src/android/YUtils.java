package com.yaz;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaPlugin;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import android.app.Activity;
import android.app.AlertDialog;
import android.content.Context;
import android.content.res.Resources;
import android.graphics.Typeface;
import android.os.Build;
import android.text.Editable;
import android.text.TextWatcher;
import android.view.KeyEvent;
import android.view.LayoutInflater;
import android.view.View;
import android.view.inputmethod.EditorInfo;
import android.widget.EditText;
import android.widget.LinearLayout;
import android.widget.TextView;
import android.view.inputmethod.InputMethodManager;
import android.view.View;
import android.view.View.OnClickListener;
import java.util.HashMap;
import java.util.Map;

public class YUtils extends CordovaPlugin {
    CallbackContext currentContext = null;

    private String _STATUS_CANCEL_PRESSED = "0";
    private String _STATUS_PIN_ENTERED_SUCCESS = "1";
    private String _STATUS_PIN_IS_EMPTY = "2";
    private String _STATUS_PIN_IS_SHORT = "3";
    private String _STATUS_IS_ALREADY_OPENED = "4";
    private String _STATUS_PIN_IS_VALIDATED = "5";

    private FakeR R;

    @Override
    public void pluginInitialize() {
        super.pluginInitialize();

        R = new FakeR(this.cordova.getActivity());
    }


    @Override
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
        currentContext = callbackContext;
        if(action.equals("getDeviceName")) {
            this.getDeviceName(callbackContext);
            return true;
        }
        if(action.equals("promptPin")) {
            this.promptPin(args, callbackContext);
            return true;
        }
        if(action.equals("validatePin")) {
            this.validatePin(args, callbackContext);
            return true;
        }
        return false;
    }

    private void getDeviceName(CallbackContext callbackContext) {
        String deviceName = Build.MODEL;
        if(deviceName != null && deviceName.length() > 0){
            callbackContext.success(deviceName);
        }else{
            callbackContext.error("No device name");
        }
    }

    private void promptPin(final JSONArray args, final CallbackContext callbackContext) throws JSONException {

        final String title = args.getString(0).length() == 0
                ? ""
                : args.getString(0);
        final String message = args.getString(1).length() == 0
                ? "Enter Pin code"
                : args.getString(1);
        final int minLength = args.getString(2).length() == 0
                ? 4
                : args.getInt(2);


        cordova.getActivity().runOnUiThread(new Runnable() {
            public void run() {
                YUtils.this.showEnterPasswordPrompt(
                        title,
                        message,
                        minLength,
                        false,
                        "",
                        "",
                        callbackContext,
                        args
                );
            }
        });
    }

    private void validatePin(final JSONArray args, final CallbackContext callbackContext) throws JSONException {

        final String pin = args.getString(0).length() == 0
                ? ""
                : args.getString(0);
        final String title = args.getString(1).length() == 0
                ? ""
                : args.getString(0);
        final String message = args.getString(2).length() == 0
                ? "Enter Pin code"
                : args.getString(1);
        final String validationMessage = args.getString(3).length() == 0
                ? "Pin code is not valid"
                : args.getString(2);

        final int minLength = pin.length();


        cordova.getActivity().runOnUiThread(new Runnable() {
            public void run() {
                YUtils.this.showEnterPasswordPrompt(
                        title,
                        message,
                        minLength,
                        true,
                        validationMessage,
                        pin,
                        callbackContext,
                        args);
            }
        });
    }

    private void showEnterPasswordPrompt(
            String title,
            String message,
            final int minLength,
            final boolean isValidate,
            final String validationMessage,
            final String providedPin,
            final CallbackContext callbackContext,
            final  JSONArray args
    ) {

        // Create the builder for the dialog.
        Activity activity = YUtils.this.cordova.getActivity();
        AlertDialog.Builder builder = new AlertDialog.Builder(activity,
                AlertDialog.THEME_DEVICE_DEFAULT_LIGHT);

        // Grab the dialog layout XML resource pointer.
        int dialogResource = R.getId("layout", "yutils_enter_password_dialog");

        // Inflate the layout XML to get the layout object.
        LayoutInflater inflater = this.cordova.getActivity().getLayoutInflater();
        final LinearLayout dialogLayout = (LinearLayout) inflater.inflate(dialogResource, null);
        builder.setView(dialogLayout);

        // Configure the buttons and title/message.
        builder.setNegativeButton(android.R.string.cancel, null);
        builder.setPositiveButton(android.R.string.ok, null);
        builder.setTitle(title);
        builder.setMessage(message);

        // Create the dialog.
        final AlertDialog dialog = builder.create();
        dialog.setCancelable(false);
        dialog.setCanceledOnTouchOutside(false);

        // Obtain references to the input field.

        EditText etPin = (EditText) dialogLayout
                .findViewById(R.getId("id", "Pin"));
        final TextView etValidate = (TextView) dialogLayout
                .findViewById(R.getId("id", "Validation"));

        // Set color to be visible on all android versions
        Resources resources = cordova.getActivity().getResources();
        int promptInputTextColor = resources.getColor(android.R.color.primary_text_light);
        etPin.setTextColor(promptInputTextColor);

        // Configure the type-face for the input.

        etPin.setTypeface(Typeface.DEFAULT);

        // Wire up an event that will handle the "Done" or return key press on the last field.
        etPin.setOnEditorActionListener(new TextView.OnEditorActionListener() {

            @Override
            public boolean onEditorAction(TextView v, int actionId, KeyEvent event) {

                if (actionId == EditorInfo.IME_ACTION_DONE
                        || actionId == EditorInfo.IME_ACTION_NEXT) {
                    validateEnterPassword(
                            minLength,
                            dialog,
                            dialogLayout,
                            callbackContext,
                            isValidate,
                            validationMessage,
                            providedPin
                    );
                    return true;
                }

                return false;
            }
        });

        // Listen text change
        etPin.addTextChangedListener(new TextWatcher() {
            @Override
            public void afterTextChanged(Editable s) {
                if(etValidate.getVisibility() == View.VISIBLE){
                    etValidate.setText("");
                    etValidate.setVisibility(View.GONE);
                }
            }

            @Override
            public void beforeTextChanged(CharSequence s, int start, int count, int after) {}

            @Override
            public void onTextChanged(CharSequence s, int start, int before, int count) {}
        });

        // Open the dialog and focus the first field.
        dialog.show();
        etPin.requestFocus();

        // Wire up the handlers for the buttons.

        dialog.getButton(AlertDialog.BUTTON_POSITIVE).setOnClickListener(new OnClickListener() {
            @Override
            public void onClick(View v) {
                validateEnterPassword(
                        minLength,
                        dialog,
                        dialogLayout,
                        callbackContext,
                        isValidate,
                        validationMessage,
                        providedPin
                );
            }
        });

        dialog.getButton(AlertDialog.BUTTON_NEGATIVE).setOnClickListener(new OnClickListener() {
            @Override
            public void onClick(View v) {
                dialog.dismiss();

                Map<String, Object> resultMap = new HashMap<String, Object>();
                resultMap.put("status", _STATUS_CANCEL_PRESSED);
                resultMap.put("pin", "");
                resultMap.put("message", "Cancel is pressed");

                callbackContext.success(new JSONObject(resultMap));
            }
        });

        // Automatically show the keyboard for the first field.
        this.showKeyboardForField(activity, etPin);
    }


    private void validateEnterPassword(
            int minLength,
            AlertDialog dialog,
            LinearLayout dialogLayout,
            CallbackContext callbackContext,
            boolean isValidate,
            String validateMessage,
            String providedPin
    ) {

        // Obtain references to the input field.

        EditText etPin = dialogLayout
                .findViewById(R.getId("id", "Pin"));

        TextView etValidate = dialogLayout
                .findViewById(R.getId("id", "Validation"));

        // Grab the password value.

        String enteredPin = etPin.getText().toString();

        // Perform validation.

        if (enteredPin.length() < 1){
            String message = "Pin code is required";
            etValidate.setText(message);
            etValidate.setVisibility(View.VISIBLE);
            etPin.requestFocus();
            return;
        }

        if (minLength != -1 && enteredPin.length() < minLength) {
            String message = String.format("The pin needs to be at least %d characters long.", minLength);
            etValidate.setText(message);
            etValidate.setVisibility(View.VISIBLE);
            etPin.requestFocus();
            return;
        }

        Map<String, Object> resultMap = new HashMap<String, Object>();


        if(isValidate){
            if(enteredPin.equals(providedPin)){
                resultMap.put("status", _STATUS_PIN_IS_VALIDATED);
                resultMap.put("pin", enteredPin);
                resultMap.put("message", "Pin is validated");
            }else{
                etValidate.setText(validateMessage);
                etValidate.setVisibility(View.VISIBLE);
                etPin.requestFocus();
                return;
            }
        }else{
            resultMap.put("status", _STATUS_PIN_ENTERED_SUCCESS);
            resultMap.put("pin", enteredPin);
            resultMap.put("message", "Pin is entered");
        }

        // If validation passed, invoke the plugin callback with the results.

        dialog.dismiss();

        callbackContext.success(new JSONObject(resultMap));
    }

    private void showKeyboardForField(final Context context, final EditText textField) {

        textField.postDelayed(new Runnable() {
            @Override
            public void run() {
                InputMethodManager inputManager = (InputMethodManager)
                        context.getSystemService(Context.INPUT_METHOD_SERVICE);

                inputManager.showSoftInput(textField, 0);
            }
        }, 200);
    }

}