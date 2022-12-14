//
//  WatchlistViewController.swift
//  TheMovieManager
//
//  Created by Perla Jimenez on 15/08/2022.
//

import UIKit
import CoreData

class WatchlistViewController: UIViewController {
    // MARK: Outlets
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    private var blockOperations = [BlockOperation]()
    
    // MARK: Properties
    var fetchedResultsController:NSFetchedResultsController<Movie>!
    
    // Mark: Helper methods
    fileprivate func setUpFetchResultsController() {
        let fetchRequest: NSFetchRequest<Movie> = Movie.fetchRequest()
        
        let sortDescriptor = NSSortDescriptor(key: "releaseDate", ascending: false)
        
        fetchRequest.predicate = NSPredicate(format: "watchlist = true")
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: DataController.shared.viewContext, sectionNameKeyPath: nil, cacheName: "movies-watchlist")
        
        fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("Fetch for watchlist could not be performed \(error.localizedDescription)")
        }
    }
    
    fileprivate func startLoading(_ loading: Bool) {
        if loading {
            activityIndicator.startAnimating()
        } else {
            guard activityIndicator.isAnimating else {
                return
            }
            
            activityIndicator.stopAnimating()
        }
        
    }
    
    // MARK: LifeCycles
    override func viewDidLoad() {
        super.viewDidLoad()
        startLoading(true)
        
        setUpFetchResultsController()
    
        // Update records
        TMDBClient.getWatchlist() { movies, error in
            self.startLoading(false)
            
            movies.forEach() {
                (item) in
                item.saveOrUpdateMovie(watchList: true)
            }
            
            if let error = error {
                guard self.fetchedResultsController.sections?[0].numberOfObjects ?? 0 < 1 else {
                    // Don't show error message if cached data already exists
                    return
                }
                self.alertError(title: "Failed to load your watchlist", message: error.localizedDescription)
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            let detailVC = segue.destination as! MovieDetailViewController
            
            if let selectedIndex = tableView.indexPathForSelectedRow {
                detailVC.movie = fetchedResultsController.object(at: selectedIndex)
                
                tableView.deselectRow(at: selectedIndex, animated: true)
            }
        }
    }
    
    deinit {
        blockOperations.forEach{ $0.cancel() }
        blockOperations.removeAll(keepingCapacity: false)
    }
    
}

// Mark: TableView Delegates
extension WatchlistViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController.sections?.count ?? 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MovieTableViewCell")!
        
        let movie = fetchedResultsController.object(at: indexPath)
        let placeHolder = UIImage(named: "PosterPlaceholder")
        
        cell.textLabel?.text = movie.title
        cell.imageView?.image = placeHolder
        
        if let posterPath = movie.posterPath {
            cell.imageView?.kf.setImage(with: K.ProductionServer.resolvePoster(posterPath), placeholder: placeHolder) {
                result in
                switch result {
                case .success:
                    cell.setNeedsLayout()
                    break
                default:
                    break
                }
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "showDetail", sender: nil)
    }
    
}


// Mark: NSFetchedResultsControllerDelegate
extension WatchlistViewController: NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            startLoading(false)
            
            blockOperations.append(BlockOperation(block: { [weak self] in
                if let this = self {
                    this.tableView.insertRows(at: [newIndexPath!], with: .fade)
                }
            }))
            break
        case .update:
            blockOperations.append(BlockOperation(block: { [weak self] in
                if let this = self {
                    this.tableView.reloadRows(at: [indexPath!], with: .automatic)
                }
            }))
            break
        case .delete:
            blockOperations.append(BlockOperation(block: { [weak self] in
                if let this = self {
                    this.tableView.deleteRows(at: [indexPath!], with: .fade)
                }
            }))
            
        default: break
        }
    }
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        blockOperations.removeAll(keepingCapacity: false)
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.performBatchUpdates({ () -> Void in
            blockOperations.forEach { $0.start() }
        }, completion: { (finished) -> Void in
            self.blockOperations.removeAll(keepingCapacity: false)
        })
    }
}
