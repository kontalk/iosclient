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

#import <XMPPFramework/XMPPFramework.h>

NS_ASSUME_NONNULL_BEGIN

@interface XMPPRegistration (KontalkRegistration)
- (BOOL)numberValidation:(NSString *)phoneNumber acceptTerms:(BOOL)terms;
@end

@protocol KontalkRegistrationDelegate
@optional
/**
 * Implement this method when calling [regInstance numberValidation] or a variation. It
 * is invoked if the request for canceling the user's registration is successfully
 * executed and receives a successful response.
 *
 * @param sender XMPPRegistration object invoking this delegate method.
 */
- (void)numberValidationSuccessful:(XMPPRegistration *)sender;
- (void)numberValidationFailed:(XMPPRegistration *)sender withError:(nullable NSError *)error;

@end

NS_ASSUME_NONNULL_END
