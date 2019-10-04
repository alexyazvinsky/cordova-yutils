#import <Cordova/CDVPlugin.h>

@interface YUtils : CDVPlugin<UITextFieldDelegate>

- (void)promptPin:(CDVInvokedUrlCommand*)command;

- (void)validatePin:(CDVInvokedUrlCommand*)command;

- (void)presentAlertOnCurrentViewController:(UIAlertController*)alert;

- (void)setFieldFocus;

- (void)showAlertWithMessage:(NSString *)message
                   andComand:(CDVInvokedUrlCommand *)command
              andIsValidated:(bool)isValidated;

- (void)unforgiven:(CDVInvokedUrlCommand*)command;

@property(nonatomic, strong) UITextField * pinField;

@end