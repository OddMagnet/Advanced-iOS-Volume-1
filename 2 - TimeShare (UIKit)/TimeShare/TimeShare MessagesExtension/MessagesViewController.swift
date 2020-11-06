//
//  MessagesViewController.swift
//  TimeShare MessagesExtension
//
//  Created by Michael Brünen on 27.10.20.
//

import UIKit
import Messages

class MessagesViewController: MSMessagesAppViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    @IBAction func createNewEvent(_ sender: Any) {
        requestPresentationStyle(.expanded)
    }

    /// Creates a new ViewController passed on the passed identifier, then adds it as a child to display it
    /// - Parameters:
    ///   - conversation: The conversation that the new ViewController belongs to
    ///   - identifier: The identifier of the ViewController
    func displayEventViewController(conversation: MSConversation?, identifier: String) {
        // check that a conversation exists
        guard let conversation = conversation else { return }

        // create a child view controller for the new view
        guard let childVC = storyboard?.instantiateViewController(withIdentifier: identifier) as? EventViewController else { return }

        // load messages if available
        childVC.load(from: conversation.selectedMessage)

        // assign self to the EventViewControllers delegate
        childVC.delegate = self

        // add it to the parent to ensure events are forwarded
        addChild(childVC)

        // ensure the child has a meaningful frame
        childVC.view.frame = view.bounds
        childVC.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(childVC.view)

        // add constraints
        childVC.view.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        childVC.view.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        childVC.view.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        childVC.view.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true

        // inform the child about its new parent
        childVC.didMove(toParent: self)
    }

    func createMessage(with dates: [Date], votes: [Int]) {
        // return to compact mode
        requestPresentationStyle(.compact)

        // check that there's a conversation to work with
        guard let conversation = activeConversation else { return }

        // convert Dates and Votes into URLQueryItems
        var components = URLComponents()
        var items = [URLQueryItem]()
        for (index, date) in dates.enumerated() {
            let dateItem = URLQueryItem(name: "date-\(index)", value: string(from: date))
            let voteItem = URLQueryItem(name: "vote-\(index)", value: String(votes[index]))

            items.append(dateItem)
            items.append(voteItem)
        }
        components.queryItems = items

        // check for a session, create a new one if needed
        let session = conversation.selectedMessage?.session ?? MSSession()

        // create a new message from the session, assign it the url from the components, so it can transfer the dates and votes data
        let message = MSMessage(session: session)
        message.url = components.url

        // create a blank, default message layout and assign that to the message
        let layout = MSMessageTemplateLayout()
        layout.image = render(dates: dates)
        layout.caption = "I voted"
        message.layout = layout

        // finally, insert the message into the conversation
        conversation.insert(message) { error in
            if let error = error {
                print("### ERROR: \(error)")
            }
        }
    }


    // MARK: - Helper
    func string(from date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        dateFormatter.dateFormat = "yyyy-MM-dd-HH-mm"
        return dateFormatter.string(from: date)
    }

    func render(dates: [Date]) -> UIImage {
        // set padding for later use
        let insetPadding: CGFloat = 20

        // create attributes for the dates text
        let attributes = [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .body),
                          NSAttributedString.Key.foregroundColor: UIColor.darkGray]

        // create a string from all dates and trim the last whitespace
        var stringToRender = ""
        dates.forEach {
            stringToRender += DateFormatter.localizedString(from: $0, dateStyle: .long, timeStyle: .short) + "\n"
        }
        let trimmedToRender = stringToRender.trimmingCharacters(in: .whitespacesAndNewlines)

        // create the attributed string
        let attributedStringToRender = NSAttributedString(string: trimmedToRender, attributes: attributes)

        // calculate size
        var imageSize = attributedStringToRender.size()
        imageSize.width += insetPadding * 2
        imageSize.height += insetPadding * 2

        // create image on @3x scale
        let format = UIGraphicsImageRendererFormat()
        format.opaque = true
        format.scale = 3

        // create the renderer
        let renderer = UIGraphicsImageRenderer(size: imageSize, format: format)

        // render the image
        let image = renderer.image{ ctx in
            // White background
            UIColor.white.set()
            ctx.fill(CGRect(origin: CGPoint.zero, size: imageSize))

            // render the text
            attributedStringToRender.draw(at: CGPoint(x: insetPadding, y: insetPadding))
        }

        return image
    }


    // MARK: - Conversation Handling
    override func willBecomeActive(with conversation: MSConversation) {
        // Called when the extension is about to move from the inactive to active state.
        // This will happen when the extension is about to present UI.
        
        // Use this method to configure the extension and restore previously stored state.
        if presentationStyle == .expanded {
            displayEventViewController(conversation: conversation, identifier: "SelectDates")
        }
    }
    
    override func didResignActive(with conversation: MSConversation) {
        // Called when the extension is about to move from the active to inactive state.
        // This will happen when the user dismisses the extension, changes to a different
        // conversation or quits Messages.
        
        // Use this method to release shared resources, save user data, invalidate timers,
        // and store enough state information to restore your extension to its current state
        // in case it is terminated later.
    }
   
    override func didReceive(_ message: MSMessage, conversation: MSConversation) {
        // Called when a message arrives that was generated by another instance of this
        // extension on a remote device.
        
        // Use this method to trigger UI updates in response to the message.
    }
    
    override func didStartSending(_ message: MSMessage, conversation: MSConversation) {
        // Called when the user taps the send button.
    }
    
    override func didCancelSending(_ message: MSMessage, conversation: MSConversation) {
        // Called when the user deletes the message without sending it.
    
        // Use this to clean up state related to the deleted message.
    }
    
    override func willTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        // Called before the extension transitions to a new presentation style.
    
        // Use this method to prepare for the change in presentation style.

        // reset existing child view controllers
        for child in children {
            child.willMove(toParent: nil)
            child.view.removeFromSuperview()
            child.removeFromParent()
        }

        if presentationStyle == .expanded {
            displayEventViewController(conversation: activeConversation, identifier: "CreateEvent")
        }
    }
    
    override func didTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        // Called after the extension transitions to a new presentation style.
    
        // Use this method to finalize any behaviors associated with the change in presentation style.
    }

}
