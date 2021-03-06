//
//  QueryViewController.swift
//  Parse Dashboard for iOS
//
//  Copyright © 2017 Nathan Tannar.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//
//  Created by Nathan Tannar on 8/31/17.
//

import UIKit
import CoreData

protocol QueryDelegate: AnyObject {
    func query(didChangeWith query: String, searchKey: String)
}

class QueryViewController: TableViewController, UITextViewDelegate {
    
    // MARK: - Properties
    
    weak var delegate: QueryDelegate?
    
    private var schema: PFSchema
    private var keys = [String]()
    private var searchKey = String()
    private var query = String()
    
    var savedQueries: [Query] = []
    
    private var context: NSManagedObjectContext? {
        return (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer.viewContext
    }
    
    // MARK: - Initialization
    
    init(_ schma: PFSchema, searchKey: String, query: String) {
        schema = schma
        super.init(nibName: nil, bundle: nil)
        self.searchKey = searchKey
        self.query = query
        self.keys = schema.fields?.map { return $0.key } ?? []
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTableView()
        setupNavigationBar()
        getSavedQueries()
    }
    
    // MARK: - Data Storage
    
    private func getSavedQueries() {
        guard let context = context else { return }
        let request: NSFetchRequest<Query> = Query.fetchRequest()
        do {
            savedQueries = try context.fetch(request)
        } catch let error {
            self.handleError(error.localizedDescription)
        }
    }
    
    // MARK: - Setup
    
    private func setupTableView() {
        
        tableView.scrollIndicatorInsets.bottom = 5
        tableView.backgroundColor = .darkPurpleBackground
        tableView.estimatedRowHeight = 44
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.register(QueryHelpCell.self, forCellReuseIdentifier: QueryHelpCell.reuseIdentifier)
        tableView.register(QueryInputCell.self, forCellReuseIdentifier: QueryInputCell.reuseIdentifier)
    }
    
    private func setupNavigationBar() {
        
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.popoverPresentationController?.backgroundColor = .darkPurpleBackground
        navigationController?.navigationBar.barTintColor = .darkPurpleBackground
        navigationController?.navigationBar.tintColor = .white
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "Save"),
                                                           style: .plain,
                                                           target: self,
                                                           action: #selector(didSaveQuery))
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Apply",
                                                            style: .done,
                                                            target: self,
                                                            action: #selector(didApplyQuery))
        navigationItem.backBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: nil, action: nil)
    }
    
    @objc
    func didSaveQuery() {
        guard let context = context else { return }
        let queryObject = Query(entity: Query.entity(), insertInto: context)
        queryObject.constraint = query
        queryObject.searchKey = searchKey
        (UIApplication.shared.delegate as? AppDelegate)?.saveContext()
        savedQueries.append(queryObject)
        handleSuccess("Query Added")
        tableView.insertRows(at: [IndexPath(row: savedQueries.count - 1, section: 1)], with: .fade)
    }
    
    @objc
    func didApplyQuery() {
        dismiss(animated: true, completion: {
            self.delegate?.query(didChangeWith: self.query, searchKey: self.searchKey)
        })
    }
    
    // MARK: - UITableViewController
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 2 && indexPath.row == 0 {
            return 80
        } 
        return UITableViewAutomaticDimension
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 32
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = UITableViewHeaderFooterView()
        header.contentView.backgroundColor = .darkPurpleBackground
        header.textLabel?.textColor = .white
        header.textLabel?.font = UIFont.boldSystemFont(ofSize: 12)
        switch section {
        case 0:
            header.textLabel?.text = "Preview Key"
            return header
        case 1:
            header.textLabel?.text = "Saved Queries"
            return header
        case 2:
            header.textLabel?.text = "Current Query"
            return header
        default:
            return nil
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return keys.count
        } else if section == 1 {
            return savedQueries.count
        } else if section == 2 {
            return 3
        }
        return 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.section == 1 {
            
            let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
            cell.textLabel?.text = savedQueries[indexPath.row].constraint
            cell.textLabel?.font = UIFont.systemFont(ofSize: 12)
            cell.textLabel?.numberOfLines = 0
            let searchKey = savedQueries[indexPath.row].searchKey ?? .objectId
            cell.detailTextLabel?.text = Localizable.search.localized + " Key: " + searchKey
            cell.detailTextLabel?.font = UIFont.systemFont(ofSize: 12, weight: .light)
            return cell
            
        } else if indexPath.section == 2 {
            
            if indexPath.row == 0 {
                
                let cell = tableView.dequeueReusableCell(withIdentifier: QueryInputCell.reuseIdentifier, for: indexPath) as! QueryInputCell
                cell.delegate = self
                cell.textInput.text = query
                return cell
                
            } else if indexPath.row == 1 {
                
                let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
                cell.textLabel?.text = "Query Builder"
                cell.textLabel?.font = UIFont.systemFont(ofSize: 15)
                cell.detailTextLabel?.text = "A graphical way to make a basic query"
                cell.detailTextLabel?.font = UIFont.systemFont(ofSize: 12, weight: .light)
                cell.accessoryType = .disclosureIndicator
                return cell
                
            } else if indexPath.row == 2 {
                let cell = tableView.dequeueReusableCell(withIdentifier: QueryHelpCell.reuseIdentifier, for: indexPath) as! QueryHelpCell
                cell.leftText = ["$lt", "$lte", "$gt", "$gte\n", "$ne", "$in", "$inQuery\n", "$nin", "$exists", "$select\n", "$dontSelect\n", "$all\n", "$regex", "order", "limit\n\n", "skip\n", "keys\n", "include\n", "&"]
                cell.rightText = ["Less Than", "Less Than Or Equal To", "Greater Than", "Greater Than Or Equal To", "Not Equal To", "Contained In", "Contained in query results", "Not Contained in", "A value is set for the key", "Match key value to query result", "Ignore keys with value equal to query result", "Contains all of the given values", "Match regular expression", "Specify a field to sort by", "Limit the number of objects returned by the query", "Use with limit to paginate through results", "Restrict the fields returned by the query", "Use on Pointer columns to return the full object", "Append constraints"]
                return cell
            }
            
        } else if indexPath.row < keys.count {
            
            let cell = UITableViewCell()
            cell.tintColor = .logoTint
            cell.textLabel?.text = keys[indexPath.row]
            cell.textLabel?.font = UIFont.systemFont(ofSize: 14)
            cell.textLabel?.textColor = .darkGray
            cell.accessoryType = searchKey == keys[indexPath.row] ? .checkmark : .none
            return cell
        }
        return UITableViewCell()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 1 {
            
            guard let query = savedQueries[indexPath.row].constraint else { return }
            let searchKey = savedQueries[indexPath.row].searchKey ?? .objectId
            dismiss(animated: true, completion: {
                self.delegate?.query(didChangeWith: query, searchKey: searchKey)
            })
            
        } else if indexPath.section == 0 {
            toggleSearchKey(at: indexPath)
        } else if indexPath.section == 2 && indexPath.row == 1 {
            let builder = QueryBuilderViewController(for: keys)
            builder.delegate = self
            builder.schema = schema
            navigationController?.pushViewController(builder, animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section == 1
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        let editAction = UITableViewRowAction(style: .default, title: " Edit ", handler: { action, indexpath in
            
            self.query = self.savedQueries[indexPath.row].constraint ?? String()
            self.searchKey = self.savedQueries[indexPath.row].searchKey ?? .objectId
            self.tableView.reloadRows(at: [indexPath, IndexPath(row: 0, section: 2)], with: .none)
            self.tableView.reloadSections([0], with: .none)
        })
        editAction.backgroundColor = .darkPurpleAccent
        
        let deleteAction = UITableViewRowAction(style: .destructive, title: Localizable.delete.localized, handler: { _,_ in
            
            guard let context = self.context else { return }
            context.delete(self.savedQueries[indexPath.row])
            do {
                try context.save()
                self.handleSuccess("Query Deleted")
                self.savedQueries.remove(at: indexPath.row)
                self.tableView.deleteRows(at: [indexPath], with: .fade)
            } catch let error {
                self.handleError(error.localizedDescription)
            }
        })
        
        return [deleteAction, editAction]
    }
    
    // MARK: - User Actions
    
    func toggleSearchKey(at indexPath: IndexPath) {
        
        guard let cell = tableView.cellForRow(at: indexPath) else { return }
        let oldIndex = keys.index(of: searchKey)
        if cell.accessoryType == .checkmark {
            searchKey = .objectId
            cell.accessoryType = .none
        } else {
            searchKey = keys[indexPath.row]
            cell.accessoryType = .checkmark
        }
        if let row = oldIndex {
            let oldIndexPath = IndexPath(row: row, section: 0)
            guard oldIndexPath != indexPath, let cell = tableView.cellForRow(at: oldIndexPath) else { return }
            cell.accessoryType = .none
        }
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y < 10 {
            tableView.backgroundColor = .darkPurpleBackground
        } else {
            tableView.backgroundColor = .white
        }
    }
    
    // MARK: - UITextViewDelegate
    
    func textViewDidChange(_ textView: UITextView) {
        query = textView.text
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            textView.resignFirstResponder()
            return false
        }
        return true
    }
}

extension QueryViewController: QueryBuilderDelegate {
    
    func query(didChangeWith query: String) {
        self.query = query
        tableView.reloadRows(at: [IndexPath(row: 0, section: 2)], with: .none)
    }
}
