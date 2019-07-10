#import "YUtils.h"
#import <Cordova/CDVPlugin.h>
#import <sys/utsname.h>

@implementation YUtils

BOOL showKeyboard = NO;
UIAlertController * currentAlert = nil;

NSString * _STATUS_CANCEL_PRESSED = @"0";
NSString * _STATUS_PIN_ENTERED_SUCCESS = @"1";
NSString * _STATUS_PIN_IS_EMPTY = @"2";
NSString * _STATUS_PIN_IS_SHORT = @"3";
NSString * _STATUS_IS_ALREADY_OPENED = @"4";
NSString * _STATUS_PIN_IS_VALIDATED = @"5";

- (void)promptPin:(CDVInvokedUrlCommand *)command
{
    NSString* title = [command.arguments objectAtIndex:0];
    NSString* message = [command.arguments objectAtIndex:1];
    NSString* pinLength = [command.arguments objectAtIndex:2];
    
    int minLength = [pinLength length] != 0 ? [pinLength intValue] : 4;
    title = [title length] != 0 ? title : @"";
    message = [message length] != 0 ? message : @"Please enter Pin Code";
    
    [self showPromptByCommand:command
                withTitle:title
                withMessage:message
                withValidation: NO
                andMinLength:minLength
                andPin:nil
                andValidationMessage:nil];
}

- (void)validatePin:(CDVInvokedUrlCommand *)command
{
    NSString* pin = [command.arguments objectAtIndex:0];
    NSString* title = [command.arguments objectAtIndex:1];
    NSString* message = [command.arguments objectAtIndex:2];
    NSString* validationMessage = [command.arguments objectAtIndex:3];
    
    int minLength = [pin length];
    title = [title length] != 0 ? title : @"";
    message = [message length] != 0 ? message : @"Please enter Pin Code";
    validationMessage = [validationMessage length] != 0 ? message : @"Pin code is not valid";
    
    [self showPromptByCommand:command
                    withTitle:title
                    withMessage:message
                    withValidation: YES
                    andMinLength:minLength
                    andPin:pin
                    andValidationMessage:validationMessage];
}

- (void)showPromptByCommand:(CDVInvokedUrlCommand*)command 
             withTitle:(NSString*)title
             withMessage:(NSString*)message
             withValidation:(bool)isValidate 
             andMinLength:(int)minLength
             andPin:(NSString*)providedPin
             andValidationMessage:(NSString*)validationPinMessage
{
    NSString *callbackId = command.callbackId;

    if(currentAlert != nil){
        NSDictionary *dictionary = @{ @"status": _STATUS_IS_ALREADY_OPENED,
                                      @"pin": @"",
                                      @"message": @"Prompt dialog is opened" };
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                      messageAsDictionary:dictionary];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
        return;
    }
    
    UIAlertController *prompt = [UIAlertController alertControllerWithTitle:title
                                                                    message:message
                                                             preferredStyle:UIAlertControllerStyleAlert];
    currentAlert = prompt;
    
    // The action for the user OK-ing the confirm password dialog.
    UIAlertAction *promptOkAction = [UIAlertAction actionWithTitle:@"OK"
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction * action)
                                     {
                                         [self cleanGlobalParams: prompt];
                                         
                                         // Grab the pin code that was entered.
                                         NSString *pin = prompt.textFields[0].text;
                                         
                                         // Ensure the user entered a pin code.
                                         if (!pin || [pin isEqualToString:@""]) {
                                             NSString *validationMessage = @"Pin code is required";
                                             [self showAlertWithMessage:validationMessage
                                                              andComand:command
                                                         andIsValidated:isValidate];
                                             return;
                                         }
                                         
                                         if (minLength != -1 && pin.length < minLength) {
                                             NSString *validationMessage = [[NSString alloc] initWithFormat:@"The pin needs to be at least %d digits long.", minLength];
                                             [self showAlertWithMessage:validationMessage
                                                              andComand:command
                                                         andIsValidated:isValidate];
                                             return;
                                         }
                                         
                                         if(isValidate){
                                            if(pin == providedPin){
                                                NSDictionary *dictionary = @{ @"status": _STATUS_PIN_IS_VALIDATED,
                                                                        @"pin": pin,
                                                                        @"message": @"Pin is validated" };
                                                CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                                                        messageAsDictionary:dictionary];
                                                [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
                                            }else{
                                                [self showAlertWithMessage:validationPinMessage
                                                                 andComand:command
                                                            andIsValidated:isValidate];
                                            }
                                         }else{
                                            NSDictionary *dictionary = @{ @"status": _STATUS_PIN_ENTERED_SUCCESS,
                                                                       @"pin": pin,
                                                                       @"message": @"Pin is entered" };
                                            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                                                       messageAsDictionary:dictionary];
                                            [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
                                         }
                                     }];
    
    // The action for the user cancelling the enter password dialog.
    UIAlertAction* promptCancelAction = [UIAlertAction actionWithTitle:@"Cancel"
                                                                 style:UIAlertActionStyleDefault
                                                               handler:^(UIAlertAction * action)
                                         {
                                             [self cleanGlobalParams: prompt];
                                             
                                             // If the user decides to cancel, send back a result with cancel flag set to true.
                                             
                                             NSDictionary *dictionary = @{ @"status": _STATUS_CANCEL_PRESSED,
                                                                           @"pin": @"",
                                                                           @"message": @"Cancel is pressed" };
                                             
                                             CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                                                           messageAsDictionary:dictionary];
                                             [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
                                         }];
    
    [prompt addAction:promptOkAction];
    [prompt addAction:promptCancelAction];
    
    // Build the input field.
    
    [prompt addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        _pinField = textField;
        _pinField.delegate = self;
        CGFloat yourSelectedFontSize = 16.0 ;
        UIFont *yourNewSameStyleFont = [textField.font fontWithSize:yourSelectedFontSize];
        textField.font = yourNewSameStyleFont ;
        textField.placeholder = @"Pin code";
        textField.secureTextEntry = @YES;
        textField.textAlignment = NSTextAlignmentCenter;
        textField.keyboardType = UIKeyboardTypeNumberPad;
    }];
    
    // Show the prompt dialog.
    [self presentAlertOnCurrentViewController:prompt];

}

- (void)showAlertWithMessage:(NSString *)message
                   andComand:(CDVInvokedUrlCommand *)command
              andIsValidated:(bool)isValidated{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@""
                                                                    message:message
                                                             preferredStyle:UIAlertControllerStyleAlert];
    currentAlert = alert;
    UIAlertAction *promptOkAction = [UIAlertAction actionWithTitle:@"OK"
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction * action)
                                     {
                                         [self cleanGlobalParams: alert];
                                         if(isValidated){
                                             [self validatePin: command];
                                         }else{
                                             [self promptPin: command];
                                         }
                                     }];
    
    [alert addAction:promptOkAction];
    
    [self presentAlertOnCurrentViewController:alert];
}


- (void)setFieldFocus {
    [_pinField becomeFirstResponder];
}

- (void)cleanGlobalParams:(UIAlertController*)alert {
    if(alert){
        [alert.view endEditing:YES];
        [alert dismissViewControllerAnimated:true completion:nil];
        alert = nil;
    }
    
    _pinField = nil;
    currentAlert = nil;
    showKeyboard = NO;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    if (showKeyboard) {
        return YES;
    } else {
        showKeyboard = YES;
        [self performSelector: @selector(setFieldFocus)
                   withObject:nil
                   afterDelay: 0.4];
        return NO;
    }
}

/**
 * Helper used to ensure the given alert controller is presented on the active view controller.
 */
- (void)presentAlertOnCurrentViewController:(UIAlertController*)alert {
    // Grab the view controller that is currently presented.
    UIViewController *currentViewController = [[[UIApplication sharedApplication] delegate] window].rootViewController;
    UIViewController *keyRootController = [UIApplication sharedApplication].keyWindow.rootViewController;
    
    // Now present the alert on the view controller that is currently presenting.
    if (currentViewController) {
        // Note that since Cordova's view controller may not be the one that is currently
        // presented (eg if another plugin that uses native controllers such as the InAppBrowser
        // is currently presenting) we have to do some extra checking. So here we dig down
        // and find the current view controller.
        if (currentViewController.presentedViewController != nil){
            currentViewController = currentViewController.presentedViewController;
        }else if(keyRootController.presentedViewController != nil){
            currentViewController = keyRootController.presentedViewController;
        }
        [currentViewController presentViewController:alert animated:YES completion:nil];
    }
    else {
        // Fallback and present on Cordova's view controller.
        [self.viewController presentViewController:alert animated:YES completion:nil];
    }
}

@end
