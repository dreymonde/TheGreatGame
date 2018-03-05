# Avenues

**Avenues** is a new approach to an old and famous problem – asynchronous loading of a resource, the most common example of which is populating an image from a remote location. The main advantage of **Avenues** is that it makes the whole process much more transparent and controllable.

In contrast to other libraries which solves the same problem, **Avenues** doesn't sacrifice "right" for "neat". Instead, **Avenues** is highly customizable, unopiniated about your business-logic, and very transparent. You can use it as a simple out-of-the-box solution, or you can get your hands dirty and customize it to fully fit your needs.

After all, **Avenues** is a really small, component-based project, so if you need even more controllable solution – build one yourself! Our source code is there to help.

## Usage

```swift
struct Entry {
    let text: String
    let imageURL: URL
}

final class ExampleTableViewController : UITableViewController {
    
    var entries: [Entry] = []
    
    let avenue = UIImageAvenue() // Avenue<URL, UIImage>
    
    override func viewDidLoad() {
        tableView.register(EntryTableViewCell.self, forCellReuseIdentifier: "example")
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return entries.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "example", for: indexPath) as! EntryTableViewCell
        let entry = entries[indexPath.row]
        cell.entryLabel.text = entry.text
        avenue.register(cell.entryImageView, for: entry.imageURL)
    }
    
}
```