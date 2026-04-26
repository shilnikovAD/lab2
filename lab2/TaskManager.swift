import Foundation

class TaskManager {
    
    // MARK: - Singleton (одиночка)
    static let shared = TaskManager()
    
    // MARK: - Properties
    private let userDefaultsKey = "tasks"
    private(set) var tasks: [Task] = []
    
    // MARK: - Init
    private init() {
        loadTasks()
    }
    
    // MARK: - Public Methods (CRUD операции)
    
    func addTask(_ task: Task) {
        tasks.append(task)
        saveTasks()
    }
    
    func updateTask(_ task: Task) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index] = task
            saveTasks()
        }
    }
    
    func deleteTask(_ task: Task) {
        tasks.removeAll { $0.id == task.id }
        saveTasks()
    }
    
    // MARK: - Сортировка и группировка для UITableView
    func getSectionsAndTasks() -> (sections: [Date], tasksBySection: [Date: [Task]]) {
        
        // 1. Сортируем задачи (сначала активные, потом по времени)
        let sortedTasks = tasks.sorted {
            if $0.status != $1.status {
                return $0.status == .active
            }
            return $0.date < $1.date
        }
        
        // 2. Группируем по дате
        let grouped = Dictionary(grouping: sortedTasks, by: { $0.dateOnly })
        
        // 3. Сортируем секции так, чтобы текущая дата была первой
        let today = Calendar.current.startOfDay(for: Date())
        var sections = grouped.keys.sorted()
        
        if let todayIndex = sections.firstIndex(of: today) {
            sections.remove(at: todayIndex)
            sections.insert(today, at: 0)
        }
        
        return (sections, grouped)
    }
    
    // MARK: - Private Helpers
    
    private func saveTasks() {
        if let encoded = try? JSONEncoder().encode(tasks) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
    
    private func loadTasks() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else {
            tasks = getDemoTasks()
            return
        }
        
        guard let savedTasks = try? JSONDecoder().decode([Task].self, from: data) else {
            tasks = getDemoTasks()
            return
        }
        
        tasks = savedTasks
    }
    
    private func getDemoTasks() -> [Task] {
        let calendar = Calendar.current
        let today = Date()
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        // Вспомогательная функция для установки времени
        func setTime(hour: Int, minute: Int, on date: Date) -> Date {
            var components = calendar.dateComponents([.year, .month, .day], from: date)
            components.hour = hour
            components.minute = minute
            return calendar.date(from: components)!
        }
        
        return [
            Task(
                title: "Сходить в магазин",
                comment: "Купить молоко",
                date: setTime(hour: 11, minute: 0, on: today)
            ),
            Task(
                title: "Написать доклад",
                comment: "Тема: SwiftUI vs UIKit",
                date: setTime(hour: 12, minute: 20, on: today)
            ),
            Task(
                title: "Сделать дела",
                comment: "Закончить проект",
                date: setTime(hour: 15, minute: 0, on: today)
            ),
            Task(
                title: "Позвонить маме",
                comment: "Спросить про здоровье",
                date: setTime(hour: 18, minute: 30, on: today),
                status: .completed
            ),
            Task(
                title: "Встреча с командой",
                comment: "Обсудить спринт",
                date: setTime(hour: 10, minute: 0, on: tomorrow)
            )
        ]
    }
}
