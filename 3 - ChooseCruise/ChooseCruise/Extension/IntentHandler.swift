//
//  IntentHandler.swift
//  Extension
//
//  Created by Michael Brünen on 11.12.20.
//

import Intents
import UIKit

// INRidesharingDomainHandling was deprecated, so this class conforms to the listed protocols instead
class IntentHandler: INExtension,
                     INListRideOptionsIntentHandling,
                     INRequestRideIntentHandling,
                     INGetRideStatusIntentHandling,
                     INCancelRideIntentHandling,
                     INSendRideFeedbackIntentHandling
{
    // MARK: - INListRideOptionsIntentHandling
    func handle(intent: INListRideOptionsIntent, completion: @escaping (INListRideOptionsIntentResponse) -> Void) {
        let mini = INRideOption(name: "Mini Cooper", estimatedPickupDate: Date(timeIntervalSinceNow: 1000))
        let honda = INRideOption(name: "Honda Accord", estimatedPickupDate: Date(timeIntervalSinceNow: 800))
        let ferrari = INRideOption(name: "Ferrari F430", estimatedPickupDate: Date(timeIntervalSinceNow: 300))
        ferrari.disclaimerMessage = "This is bad for the environment"

        let result = INListRideOptionsIntentResponse(code: .success, userActivity: nil)
        result.expirationDate = Date(timeIntervalSinceNow: 3600)
        result.rideOptions = [mini, honda, ferrari]

        completion(result)
    }

    // MARK: - INRequestRideIntentHandling
    func handle(intent: INRequestRideIntent, completion: @escaping (INRequestRideIntentResponse) -> Void) {

    }
    func resolvePickupLocation(for intent: INRequestRideIntent, with completion: @escaping (INPlacemarkResolutionResult) -> Void) {

    }
    func resolveDropOffLocation(for intent: INRequestRideIntent, with completion: @escaping (INPlacemarkResolutionResult) -> Void) {

    }

    // MARK: - INGetRideStatusIntentHandling
    /// Gets called when the user asks where his ride is, for test purposes the result will always be `.success`. `userActivity` would be e.g. when the user asks to open the app for more information
    func handle(intent: INGetRideStatusIntent, completion: @escaping (INGetRideStatusIntentResponse) -> Void) {
        let result = INGetRideStatusIntentResponse(code: .success, userActivity: nil)
        completion(result)
    }
    func startSendingUpdates(for intent: INGetRideStatusIntent, to observer: INGetRideStatusIntentResponseObserver) {

    }
    func stopSendingUpdates(for intent: INGetRideStatusIntent) {

    }

    // MARK: - INCancelRideIntentHandling
    /// Gets called when the user cancels the ride, for test purposes the result will always be `.success`. `userActivity` would be e.g. when the user asks to open the app for more information
    func handle(cancelRide intent: INCancelRideIntent, completion: @escaping (INCancelRideIntentResponse) -> Void) {
        let result = INCancelRideIntentResponse(code: .success, userActivity: nil)
        completion(result)
    }

    // MARK: - INSendRideFeedbackIntentHandling
    /// Gets called when the user leaves feedback for the ride, for test purposes the result will always be `.success`. `userActivity` would be e.g. when the user asks to open the app for more information
    func handle(sendRideFeedback sendRideFeedbackintent: INSendRideFeedbackIntent, completion: @escaping (INSendRideFeedbackIntentResponse) -> Void) {
        let result = INSendRideFeedbackIntentResponse(code: .success, userActivity: nil)
        completion(result)
    }

}
