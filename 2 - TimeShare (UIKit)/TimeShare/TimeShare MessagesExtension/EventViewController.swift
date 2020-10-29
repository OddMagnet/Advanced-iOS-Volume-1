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
    }

    // MARK: - Table View Delegate
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dates.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Date", for: indexPath)
        cell.textLabel?.text = "Date goes here"
        return cell
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
