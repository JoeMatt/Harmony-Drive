//
//  ViewController.swift
//  Example
//
//  Created by Riley Testut on 1/23/18.
//  Copyright © 2018 Riley Testut. All rights reserved.
//

import CoreData
import UIKit

import Harmony
#if canImport(Harmony_Drive)
    import Harmony_Drive
#endif

import Roxas

class ViewController: UITableViewController {
    private var persistentContainer: NSPersistentContainer!

    private var changeToken: Data?

    private var syncCoordinator: SyncCoordinator!

    private lazy var dataSource = self.makeDataSource()

    override func viewDidLoad() {
        super.viewDidLoad()

        let model = NSManagedObjectModel.mergedModel(from: nil)!
        let harmonyModel = NSManagedObjectModel.harmonyModel(byMergingWith: [model])!

        persistentContainer = RSTPersistentContainer(name: "Harmony Example", managedObjectModel: harmonyModel)
        persistentContainer.loadPersistentStores { _, error in
            print("Loaded with error:", error as Any)

            self.tableView.dataSource = self.dataSource
        }

        #if canImport(Harmony_Drive)
            syncCoordinator = SyncCoordinator(service: DriveService.shared, persistentContainer: persistentContainer)
        #endif
        syncCoordinator.start { result in
            do {
                _ = try result.value()

                print("Started Sync Coordinator")
            } catch {
                print("Failed to start Sync Coordinator.", error)
            }
        }

        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.syncDidFinish(_:)), name: SyncCoordinator.didFinishSyncingNotification, object: syncCoordinator)

        #if canImport(Harmony_Drive)
            DriveService.shared.clientID = "1075055855134-qilcmemb9e2pngq0i1n0ptpsc0pq43vp.apps.googleusercontent.com"

            DriveService.shared.authenticateInBackground { result in
                switch result {
                case .success: print("Background authentication successful")
                case let .failure(error): print(error.localizedDescription)
                }
            }
        #endif
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

private extension ViewController {
    func makeDataSource() -> RSTFetchedResultsTableViewDataSource<Homework> {
        let fetchRequest = Homework.fetchRequest() as NSFetchRequest<Homework>
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Homework.identifier, ascending: true)]

        let dataSource = RSTFetchedResultsTableViewDataSource(fetchRequest: fetchRequest, managedObjectContext: persistentContainer.viewContext)
        dataSource.proxy = self
        dataSource.cellConfigurationHandler = { cell, homework, _ in
            cell.textLabel?.text = homework.name
            cell.detailTextLabel?.numberOfLines = 3
            cell.detailTextLabel?.text = "ID: \(homework.identifier ?? "nil")\nCourse Name: \(homework.course?.name ?? "nil")\nCourse ID: \(homework.course?.name ?? "nil")"
        }

        return dataSource
    }
}

private extension ViewController {
    @IBAction func authenticate(_: UIBarButtonItem) {
        #if canImport(Harmony_Drive)
            DriveService.shared.authenticate(withPresentingViewController: self) { result in
                switch result {
                case .success: print("Authentication successful")
                case let .failure(error): print(error.localizedDescription)
                }
            }
        #endif
    }

    @IBAction func addHomework(_: UIBarButtonItem) {
        persistentContainer.performBackgroundTask { context in
            let course = Course(context: context)
            course.name = "CSCI-170"
            course.identifier = "CSCI-170"

            let homework = Homework(context: context)
            homework.name = UUID().uuidString
            homework.identifier = UUID().uuidString
            homework.dueDate = Date()
            homework.course = course

            let fileURL = Bundle.main.url(forResource: "Project1", withExtension: "pdf")!
            try! FileManager.default.copyItem(at: fileURL, to: homework.fileURL!)

            try! context.save()
        }
    }

    @IBAction func sync(_: UIBarButtonItem) {
        syncCoordinator.sync()
    }

    @objc func syncDidFinish(_ notification: Notification) {
        guard let result = notification.userInfo?[SyncCoordinator.syncResultKey] as? Result<[Result<Void>]> else { return }

        do {
            _ = try result.value()

            print("Sync Succeeded")
        } catch {
            print("Sync Failed:", error)
        }
    }
}

extension ViewController {
    override func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        let homework = dataSource.item(at: indexPath)

        persistentContainer.performBackgroundTask { context in
            let homework = context.object(with: homework.objectID) as! Homework
            homework.name = UUID().uuidString

            try! context.save()
        }
    }

    override func tableView(_: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }

        let homework = dataSource.item(at: indexPath)

        persistentContainer.performBackgroundTask { context in
            let homework = context.object(with: homework.objectID) as! Homework
            context.delete(homework)

            try! context.save()
        }
    }
}
