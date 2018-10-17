var cordova = window.cordova;

var YUtils = {
    getDeviceName: function(successCallback, errorCallback) {
        cordova.exec(
            successCallback,
            errorCallback,
            "YUtils",
            "getDeviceName",
            []
        );
    },
    promptPin: function(successCallback, errorCallback, title, message, pinLength) {
        cordova.exec(
                    successCallback,
                    errorCallback,
                    "YUtils",
                    "promptPin",
                    [
                        title || '',
                        message || '',
                        pinLength ? pinLength.toString() : ''
                    ]
        );
    },
    validatePin: function(successCallback, errorCallback, pin, title, message, validationMessage) {
        cordova.exec(
                    successCallback,
                    errorCallback,
                    "YUtils",
                    "validatePin",
                    [
                        pin || '',
                        title || '',
                        message || '',
                        validationMessage || ''
                    ]
        );
    }
};

module.exports = YUtils;
