//
//  EventViewController.swift
//  TimeShare MessagesExtension
//
//  Created by Michael Brünen on 27.10.20.
//

import UIKit

class EventViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var datePicker: UIDatePicker!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func addDate(_ sender: Any) {
    }

    @IBAction func saveSelectedDates(_ sender: Any) {
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
