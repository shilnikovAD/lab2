import UIKit

class MainViewController: UITableViewController {

    private var sections: [Date] = []
    private var tasksBySection: [Date: [Task]] = [:]

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupTableView()
        loadData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadData()
    }

    private func setupNavigationBar() {
        title = "Задачи"
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Добавить",
            style: .plain,
            target: self,
            action: #selector(didTapAdd)
        )
    }

    private func setupTableView() {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "TaskCell")
        tableView.dragDelegate = self
        tableView.dropDelegate = self
        tableView.dragInteractionEnabled = true
    }

    private func loadData() {
        let data = TaskManager.shared.getSectionsAndTasks()
        sections = data.sections
        tasksBySection = data.tasksBySection
        tableView.reloadData()
    }

    @objc private func didTapAdd() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let vc = storyboard.instantiateViewController(withIdentifier: "TaskEditorVC") as? TaskEditorViewController else {
            print("❌ Не удалось создать TaskEditorViewController")
            return
        }
        vc.mode = .create
        navigationController?.pushViewController(vc, animated: true)
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let date = sections[section]
        let today = Calendar.current.startOfDay(for: Date())
        if date == today {
            return "Сегодня"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .long
            formatter.locale = Locale(identifier: "ru_RU")
            return formatter.string(from: date)
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let date = sections[section]
        return tasksBySection[date]?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TaskCell", for: indexPath)
        let date = sections[indexPath.section]
        guard let task = tasksBySection[date]?[indexPath.row] else { return cell }

        var config = cell.defaultContentConfiguration()
        config.text = task.title
        config.secondaryText = "\(task.timeString) - \(task.comment)"

        if task.status == .completed {
            let attributedString = NSAttributedString(
                string: task.title,
                attributes: [.strikethroughStyle: NSUnderlineStyle.single.rawValue]
            )
            config.attributedText = attributedString
        } else {
            config.text = task.title
        }

        cell.contentConfiguration = config
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let date = sections[indexPath.section]
        guard let task = tasksBySection[date]?[indexPath.row] else { return }

        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let vc = storyboard.instantiateViewController(withIdentifier: "TaskEditorVC") as? TaskEditorViewController else { return }
        vc.mode = .edit(task)
        navigationController?.pushViewController(vc, animated: true)
    }

    override func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let date = sections[indexPath.section]
        guard let task = tasksBySection[date]?[indexPath.row] else { return nil }

        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            let completeAction = UIAction(
                title: task.status == .active ? "Завершить" : "Активировать",
                image: UIImage(systemName: "checkmark.circle")
            ) { _ in
                var updatedTask = task
                updatedTask.status = task.status == .active ? .completed : .active
                TaskManager.shared.updateTask(updatedTask)
                self.loadData()
            }

            let editAction = UIAction(
                title: "Изменить",
                image: UIImage(systemName: "pencil")
            ) { _ in
                self.tableView(self.tableView, didSelectRowAt: indexPath)
            }

            let deleteAction = UIAction(
                title: "Удалить",
                image: UIImage(systemName: "trash"),
                attributes: .destructive
            ) { _ in
                TaskManager.shared.deleteTask(task)
                self.loadData()
            }

            return UIMenu(title: "", children: [completeAction, editAction, deleteAction])
        }
    }
}

// MARK: - Drag & Drop
extension MainViewController: UITableViewDragDelegate, UITableViewDropDelegate {
    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        let date = sections[indexPath.section]
        guard let task = tasksBySection[date]?[indexPath.row] else { return [] }
        let itemProvider = NSItemProvider(object: task.id.uuidString as NSString)
        let dragItem = UIDragItem(itemProvider: itemProvider)
        dragItem.localObject = task
        return [dragItem]
    }

    func tableView(_ tableView: UITableView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UITableViewDropProposal {
        return UITableViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
    }

    func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {
        guard let dragItem = coordinator.items.first?.dragItem,
              let sourceTask = dragItem.localObject as? Task,
              let destinationIndexPath = coordinator.destinationIndexPath else { return }

        let newDate = sections[destinationIndexPath.section]
        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute], from: sourceTask.date)
        var newDateComponents = calendar.dateComponents([.year, .month, .day], from: newDate)
        newDateComponents.hour = timeComponents.hour
        newDateComponents.minute = timeComponents.minute

        let updatedTask = Task(
            id: sourceTask.id,
            title: sourceTask.title,
            comment: sourceTask.comment,
            date: calendar.date(from: newDateComponents)!,
            status: sourceTask.status
        )
        TaskManager.shared.updateTask(updatedTask)
        loadData()
    }
}
