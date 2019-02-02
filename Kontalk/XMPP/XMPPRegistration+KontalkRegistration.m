//
//  Kontalk iOS client
//  Copyright (C) 2018 Kontalk Devteam <devteam@kontalk.org>
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.

#import "XMPPRegistration+KontalkRegistration.h"

@implementation XMPPRegistration (KontalkRegistration)

/**
 * This extension is used to register to the Kontalk service.
 * It uses XEP-0077: In-band registration with a few more form fields to include some stuff such as verification code, phone number and public key
 *
 * @link {https://github.com/kontalk/specs/blob/master/register.md}
 *
 *
 * <iq to='prime.kontalk.net' id='80zgA-18' type='set'>
 * <query xmlns='jabber:iq:register'>
 * <x xmlns='jabber:x:data' type='submit'>
 * <field var='FORM_TYPE' type='hidden'>
 * <value>jabber:iq:register</value>
 * </field>
 * <field label='Phone number' var='phone' type='text-single'>
 * <value>+15555215554</value>
 * </field>
 * </x>
 * </query>
 * </iq>
 *
 */
- (BOOL)numberValidation:(NSString *)phoneNumber acceptTerms:(BOOL)terms forceRegistration:(BOOL)force
{
    dispatch_block_t block = ^{
        @autoreleasepool {
            
            DDXMLElement *query = [DDXMLElement elementWithName:@"query" xmlns:@"jabber:iq:register"];
            
            DDXMLElement *x = [DDXMLElement elementWithName:@"x" xmlns:@"jabber:x:data"];
            [x addAttributeWithName:@"type" stringValue:@"submit"];
            
            [query addChild:x];
            
            DDXMLElement *field = [DDXMLElement elementWithName:@"field"];
            [field addAttributeWithName:@"var" stringValue:@"FORM_TYPE"];
            [field addAttributeWithName:@"type" stringValue:@"hidden"];
            
            DDXMLElement *formType = [DDXMLElement elementWithName:@"value"];
            formType.stringValue = @"jabber:iq:register";
            
            [field addChild:formType];
            [x addChild:field];
            
            DDXMLElement *fieldPhone = [DDXMLElement elementWithName:@"field"];
            [fieldPhone addAttributeWithName:@"label" stringValue:@"Phone number"];
            [fieldPhone addAttributeWithName:@"var" stringValue:@"phone"];
            [fieldPhone addAttributeWithName:@"type" stringValue:@"text-single"];

            DDXMLElement *telephoneNumber = [DDXMLElement elementWithName:@"value"];
            telephoneNumber.stringValue = phoneNumber;
            [fieldPhone addChild:telephoneNumber];

            [x addChild:fieldPhone];

            DDXMLElement *fieldGdpr = [DDXMLElement elementWithName:@"field"];
            [fieldGdpr addAttributeWithName:@"var" stringValue:@"accept-terms"];
            [fieldGdpr addAttributeWithName:@"type" stringValue:@"boolean"];
            
            DDXMLElement *gdpr = [DDXMLElement elementWithName:@"value"];
            if (terms) {
                gdpr.stringValue = @"true";
            } else {
                gdpr.stringValue = @"false";
            }
            
            [fieldGdpr addChild:gdpr];
             
            [x addChild:fieldGdpr];
            
            if (force) {
                DDXMLElement *forceRegistration = [DDXMLElement elementWithName:@"field"];
                [forceRegistration addAttributeWithName:@"label" stringValue:@"Force registration"];
                [forceRegistration addAttributeWithName:@"var" stringValue:@"force"];
                [forceRegistration addAttributeWithName:@"type" stringValue:@"boolean"];
                
                DDXMLElement *force = [DDXMLElement elementWithName:@"value"];
                force.stringValue = @"true";
                [forceRegistration addChild:force];
                
                [x addChild:forceRegistration];
            }
            
            XMPPIQ *iq = [XMPPIQ iqWithType:@"set" to:[XMPPJID jidWithString:xmppStream.hostName] elementID:@"80zgA-18" child:query];
            
            [xmppIDTracker addElement:iq
                            target:self
                             selector:@selector(handleNumberValidationIQ:withInfo:)
                              timeout:60];
            
            [self.xmppStream sendElement:iq];
        }
    };
    
    if (dispatch_get_specific(moduleQueueTag))
        block();
    else
        dispatch_async(moduleQueue, block);

    return YES;
}

/**
 * This extension is used to register to the Kontalk service.
 * It uses XEP-0077: In-band registration with a few more form fields to include some stuff such as verification code, phone number and public key
 *
 * @link {https://github.com/kontalk/specs/blob/master/register.md}
 *
 *
 * <iq to='prime.kontalk.net' id='80zgA-25' type='set'>
 * <query xmlns='jabber:iq:register'>
 * <x xmlns='jabber:x:data' type='submit'>
 * <field var='FORM_TYPE' type='hidden'>
 * <value>http://kontalk.org/protocol/register#code</value>
 * </field>
 * <field label='Validation code' var='code' type='text-single'>
 * <value>839775</value>
 * </field>
 * </x>
 * </query>
 * </iq>
 *
 */
- (BOOL)codeValidation:(NSString *)validationCode
{
    dispatch_block_t block = ^{
        @autoreleasepool {
            
            DDXMLElement *query = [DDXMLElement elementWithName:@"query" xmlns:@"jabber:iq:register"];
            
            DDXMLElement *x = [DDXMLElement elementWithName:@"x" xmlns:@"jabber:x:data"];
            [x addAttributeWithName:@"type" stringValue:@"submit"];
            
            [query addChild:x];
            
            DDXMLElement *field = [DDXMLElement elementWithName:@"field"];
            [field addAttributeWithName:@"var" stringValue:@"FORM_TYPE"];
            [field addAttributeWithName:@"type" stringValue:@"hidden"];
            
            DDXMLElement *formType = [DDXMLElement elementWithName:@"value"];
            formType.stringValue = @"http://kontalk.org/protocol/register#code";
            
            [field addChild:formType];
            [x addChild:field];
            
            DDXMLElement *fieldValidationCode = [DDXMLElement elementWithName:@"field"];
            [fieldValidationCode addAttributeWithName:@"label" stringValue:@"Validation code"];
            [fieldValidationCode addAttributeWithName:@"var" stringValue:@"code"];
            [fieldValidationCode addAttributeWithName:@"type" stringValue:@"text-single"];
            
            DDXMLElement *code = [DDXMLElement elementWithName:@"value"];
            code.stringValue = validationCode;
            [fieldValidationCode addChild:code];
            
            [x addChild:fieldValidationCode];
            
            XMPPIQ *iq = [XMPPIQ iqWithType:@"set" to:[XMPPJID jidWithString:xmppStream.hostName] elementID:@"80zgA-25" child:query];
            
            [xmppIDTracker addElement:iq
                               target:self
                             selector:@selector(handleCodeValidationIQ:withInfo:)
                              timeout:60];
            
            [self.xmppStream sendElement:iq];
        }
    };
    
    if (dispatch_get_specific(moduleQueueTag))
        block();
    else
        dispatch_async(moduleQueue, block);
    
    return YES;
}

/**
 * This method handles the response received (or not received) after calling numberValidation.
 */
- (void)handleNumberValidationIQ:(XMPPIQ *)iq withInfo:(XMPPBasicTrackingInfo *)info
{
    dispatch_block_t block = ^{
        @autoreleasepool {
            DDXMLElement *errorElem = [iq elementForName:@"error"];
            
            if (errorElem) {
                
                [multicastDelegate numberValidationFailed:self
                                                  withError:errorElem];
                return;
            }
            
            NSString *type = [iq type];
            
            if ([type isEqualToString:@"result"]) {
                [multicastDelegate numberValidationSuccessful:self];
            } else {
                // this should be impossible to reach, but just for safety's sake...
                [multicastDelegate numberValidationFailed:self withError:nil];
            }
        }
    };
    
    if (dispatch_get_specific(moduleQueueTag))
        block();
    else
        dispatch_async(moduleQueue, block);
}

/**
 * This method handles the response received (or not received) after calling codeValidation.
 */
- (void)handleCodeValidationIQ:(XMPPIQ *)iq withInfo:(XMPPBasicTrackingInfo *)info
{
    dispatch_block_t block = ^{
        @autoreleasepool {
            DDXMLElement *errorElem = [iq elementForName:@"error"];
            
            if (errorElem) {
                
                [multicastDelegate codeValidationFailed:self
                                                withError:errorElem];
                return;
            }
            
            NSString *type = [iq type];
            
            if ([type isEqualToString:@"result"]) {
                DDXMLElement *query = [iq elementForName:@"query"];
                DDXMLElement *x = [query elementForName:@"x"];
                NSArray<DDXMLElement *> *fields = [x elementsForName:@"field"];
                for (DDXMLElement *field in fields) {
                    NSString *var = [field attributeStringValueForName:@"var"];
                    if ([var isEqualToString:@"publickey"]) {
                        [multicastDelegate codeValidationSuccessful:self :[field stringValue]];
                    }
                }
                [multicastDelegate codeValidationFailed:self withError:nil];
            } else {
                // this should be impossible to reach, but just for safety's sake...
                [multicastDelegate codeValidationFailed:self withError:nil];
            }
        }
    };
    
    if (dispatch_get_specific(moduleQueueTag))
        block();
    else
        dispatch_async(moduleQueue, block);
}

@end
