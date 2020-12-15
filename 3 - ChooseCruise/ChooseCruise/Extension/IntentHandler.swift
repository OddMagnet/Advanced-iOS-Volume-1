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
        let result = INRequestRideIntentResponse(code: .success, userActivity: nil)

        // create a status with a unique identified, containing pickup/dropoff location, the current phase and estimated time
        let status = INRideStatus()
        status.rideIdentifier = "UniqueStringHere"
        status.pickupLocation = intent.pickupLocation
        status.dropOffLocation = intent.dropOffLocation
        status.phase = .confirmed
        status.estimatedPickupDate = Date(timeIntervalSinceNow: 900)

        // create a vehicle for the pickup, add an image for maps and a location
        let vehicle = INRideVehicle()
        vehicle.mapAnnotationImage = INImage(named: "car")
        vehicle.location = intent.dropOffLocation!.location // same as dropOff location, for testing purposes

        // finally, assign the vehicle
        status.vehicle = vehicle
        // attach status to the result
        result.rideStatus = status
        // and call the completion handler
        completion(result)
    }
    func resolvePickupLocation(for intent: INRequestRideIntent, with completion: @escaping (INPlacemarkResolutionResult) -> Void) {
        let result: INPlacemarkResolutionResult

        if let requestedLocation = intent.pickupLocation {  // valid pickup location
            result = .success(with: requestedLocation)
        } else {                                            // invalid pickup location
            result = INPlacemarkResolutionResult.needsValue()
        }

        completion(result)
    }
    func resolveDropOffLocation(for intent: INRequestRideIntent, with completion: @escaping (INPlacemarkResolutionResult) -> Void) {
        let result: INPlacemarkResolutionResult

        if let requestedLocation = intent.dropOffLocation { // valid dropOff location
            result = .success(with: requestedLocation)
        } else {                                            // invalid dropOff location
            result = INPlacemarkResolutionResult.needsValue()
        }

        completion(result)
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
