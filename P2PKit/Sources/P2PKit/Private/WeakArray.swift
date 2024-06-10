//
//  WeakArray.swift

private class WeakRef {
    weak var ref: AnyObject?
    init(_ ref: AnyObject) {
        self.ref = ref
    }
}

class WeakArray<T> {
    var items: [T?] {
        get {
            return _items.map { $0.ref as? T }
        }
    }
    private var _items = [WeakRef]()

    /// Inserts a given element if it's not already present.
    /// - Parameter item: An element to insert into the ordered set..
    func add(_ item: AnyObject) {
        assert(item is T)
        _items = _items.filter { $0.ref != nil }
        if !_items.contains(where: { $0.ref === item }) {
            _items.append(WeakRef(item))
        }
    }
    
    /// Removes an element
    ///  - Parameter item: An element to remove from the set.
    func remove(_ item: AnyObject) {
        assert(item is T)
        _items.removeAll { $0.ref === item }
    }
    
    /// Inserts a given element if it's not already present.
    /// - Parameter item: An element to insert into the set.
    func removeAll(where predicate: (T) -> Bool) {
        _items.removeAll {
            if let value = $0.ref as? T {
                return predicate(value)
            } else {
                return false
            }
        }
    }
}

extension WeakArray: Collection {
    var startIndex: Int { return _items.startIndex }
    var endIndex: Int { return _items.endIndex }

    subscript(_ index: Int) -> T? {
        return _items[index].ref as! T
    }

    func index(after idx: Int) -> Int {
        return _items.index(after: idx)
    }
}
