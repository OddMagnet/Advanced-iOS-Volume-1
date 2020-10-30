//
//  EventViewController.swift
//  TimeShare MessagesExtension
//
//  Created by Michael Brünen on 27.10.20.
//

import UIKit

class EventViewController: UIViewController,
                           UITableViewDelegate,
                           UITableViewDataSource {

    var dates = [Date]()
    var allVotes = [Int]()
    var ourVotes = [Int]()
    weak var delegate: MessagesViewController!

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var datePicker: UIDatePicker!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func addDate(_ sender: Any) {
        // add currently selected date to the arrays
        dates.append(datePicker.date)
        allVotes.append(0)
        ourVotes.append(1)

        // insert a new row for the array and scroll to it
        let newIndexPath = IndexPath(row: dates.count - 1 , section: 0)
        tableView.insertRows(at: [newIndexPath], with: .automatic)
        tableView.scrollToRow(at: newIndexPath, at: .bottom, animated: true)

        // flash scroll bar to notify user that a change has happened
        tableView.flashScrollIndicators()
    }

    @IBAction func saveSelectedDates(_ sender: Any) {
        // Sum up all votes
        var finalVotes = [Int]()
        for (index, votes) in allVotes.enumerated() {
            finalVotes.append(votes + ourVotes[index])
        }

        // then call the delegates createMessage method
        delegate.createMessage(with: dates, votes: finalVotes)
    }

    // MARK: - Table View Delegate
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dates.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // dequeue cell
        let cell = tableView.dequeueReusableCell(withIdentifier: "Date", for: indexPath)

        // get the corresponding date and format it
        let date = dates[indexPath.row]
        cell.textLabel?.text = DateFormatter.localizedString(from: date, dateStyle: .long, timeStyle: .short)

        // add checkmark if the user voted for this date
        if ourVotes[indexPath.row] == 1 {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }

        // add vote count if others voted for this date
        // thanks to optional chaining this will only be used in the VC that has a subtitle row style
        if allVotes[indexPath.row] > 0 {
            cell.detailTextLabel?.text = "Votes: \(allVotes[indexPath.row])"
        } else {
            cell.detailTextLabel?.text = ""
        }

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // deselect row since tapping a row should only toggle the users vote
        tableView.deselectRow(at: indexPath, animated: true)

        // get the cell
        if let cell = tableView.cellForRow(at: indexPath) {
            // check if the current vote status and toggle it's status
            if cell.accessoryType == .checkmark {
                cell.accessoryType = .none
                ourVotes[indexPath.row] = 0
            } else {
                cell.accessoryType = .checkmark
                ourVotes[indexPath.row] = 1
            }
        }
    }

    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
