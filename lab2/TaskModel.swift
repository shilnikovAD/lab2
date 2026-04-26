import Foundation

// Перечисление для статуса задачи
enum TaskStatus: String, Codable {
    case active = "Активна"
    case completed = "Выполнена"
}

// Структура задачи
struct Task: Identifiable, Equatable, Hashable, Codable {
    var id: UUID = UUID()
    var title: String
    var comment: String
    var date: Date
    var status: TaskStatus = .active
    
    // Вспомогательные свойства для группировки
    var dateOnly: Date {
        return Calendar.current.startOfDay(for: date)
    }
    
    var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
