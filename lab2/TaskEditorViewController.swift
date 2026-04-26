import UIKit

// MARK: - Режимы работы редактора
enum EditorMode {
    case create          // Создание новой задачи
    case edit(Task)      // Редактирование существующей
}

class TaskEditorViewController: UIViewController {
    
    // MARK: - Properties
    var mode: EditorMode = .create
    private var currentTask: Task?
    
    // MARK: - IBOutlets (связи с элементами на Storyboard)
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var commentTextView: UITextView!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var completeButton: UIButton!
    @IBOutlet weak var deleteButton: UIButton!
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        configureForMode()
    }
    
    // MARK: - Setup
    private func setupUI() {
        title = "Редактор задач"
        view.backgroundColor = .systemBackground
        
        // Настройка TextView (как в лекции UIKit 3)
        commentTextView.layer.borderWidth = 0.5
        commentTextView.layer.borderColor = UIColor.lightGray.cgColor
        commentTextView.layer.cornerRadius = 8
        commentTextView.font = UIFont.systemFont(ofSize: 16)
        
        // Настройка DatePicker
        datePicker.datePickerMode = .dateAndTime
        datePicker.preferredDatePickerStyle = .wheels
    }
    
    private func configureForMode() {
        switch mode {
        case .create:
            // Режим создания - скрываем кнопки "Завершить" и "Удалить"
            completeButton.isHidden = true
            deleteButton.isHidden = true
            currentTask = nil
            
        case .edit(let task):
            // Режим редактирования - показываем все кнопки
            completeButton.isHidden = false
            deleteButton.isHidden = false
            currentTask = task
            
            // Заполняем поля данными задачи
            titleTextField.text = task.title
            commentTextView.text = task.comment
            datePicker.date = task.date
            
            // Меняем текст кнопки в зависимости от статуса
            let buttonTitle = task.status == .active ? "Завершить" : "Активировать"
            completeButton.setTitle(buttonTitle, for: .normal)
        }
    }
    
    // MARK: - Actions
    
    @IBAction func saveTapped(_ sender: UIButton) {
        // Проверяем, что заголовок не пустой
        guard let title = titleTextField.text, !title.isEmpty else {
            showAlert(message: "Введите заголовок задачи")
            return
        }
        
        // Создаём новую задачу
        let newTask = Task(
            id: currentTask?.id ?? UUID(),
            title: title,
            comment: commentTextView.text ?? "",   // ← НЕ commentTextField
            date: datePicker.date,
            status: currentTask?.status ?? .active
        )
        
        // Сохраняем в зависимости от режима
        if case .create = mode {
            TaskManager.shared.addTask(newTask)
        } else {
            TaskManager.shared.updateTask(newTask)
        }
        
        // Возвращаемся на предыдущий экран
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func completeTapped(_ sender: UIButton) {
        guard var task = currentTask else { return }
        
        // Меняем статус на противоположный
        task.status = task.status == .active ? .completed : .active
        
        // Обновляем задачу
        TaskManager.shared.updateTask(task)
        
        // Возвращаемся на предыдущий экран
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func deleteTapped(_ sender: UIButton) {
        guard let task = currentTask else { return }
        
        // Показываем подтверждение удаления
        let alert = UIAlertController(
            title: "Удалить задачу?",
            message: "Это действие нельзя отменить",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        alert.addAction(UIAlertAction(title: "Удалить", style: .destructive) { _ in
            TaskManager.shared.deleteTask(task)
            self.navigationController?.popViewController(animated: true)
        })
        
        present(alert, animated: true)
    }
    
    // MARK: - Helpers
    
    private func showAlert(message: String) {
        let alert = UIAlertController(
            title: "Ошибка",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
