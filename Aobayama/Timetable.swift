//
//  Timetable.swift
//  Aobayama
//
//  Created by 小平航大 on 2025/11/06.
//

import Foundation

struct TimetableEntry: Codable {
    let hour: Int
    let weekday: [Int]
    let holiday: [Int]
}

struct Timetable: Codable {
    let station: String
    let destination: String
    let entries: [TimetableEntry]
}

struct TimetableManager {
    private var timetable: Timetable?
    
    init() {
        loadTimetable()
    }
    
    mutating func loadTimetable() {
        guard let url = Bundle.main.url(forResource: "aobayama_timetable", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let timetable = try? JSONDecoder().decode(Timetable.self, from: data) else {
            return
        }
        self.timetable = timetable
    }
    
    func getNextTrainTime() -> (minutes: Int, seconds: Int)? {
        guard let timetable = timetable else { return nil }
        
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.hour, .minute, .second, .weekday], from: now)
        guard let currentHour = components.hour,
              let currentMinute = components.minute,
              let currentSecond = components.second,
              let weekday = components.weekday else {
            return nil
        }
        
        // 1=日曜日、7=土曜日。日本の祝日判定は簡易的に土日を祝日として扱う
        let isHoliday = weekday == 1 || weekday == 7
        
        // 現在時刻を秒に変換
        let currentTimeInSeconds = currentHour * 3600 + currentMinute * 60 + currentSecond
        
        // 今日の残りの時刻をチェック
        var nextTrainTimeInSeconds: Int?
        
        for entry in timetable.entries {
            guard entry.hour >= currentHour else { continue }
            
            let minutes = isHoliday ? entry.holiday : entry.weekday
            
            for minute in minutes {
                let trainTimeInSeconds = entry.hour * 3600 + minute * 60
                
                if trainTimeInSeconds > currentTimeInSeconds {
                    if nextTrainTimeInSeconds == nil || trainTimeInSeconds < nextTrainTimeInSeconds! {
                        nextTrainTimeInSeconds = trainTimeInSeconds
                    }
                }
            }
        }
        
        // 今日見つからなければ、翌日の最初の電車を探す
        if nextTrainTimeInSeconds == nil {
            var earliestTrainTime: Int?
            for entry in timetable.entries {
                let minutes = isHoliday ? entry.holiday : entry.weekday
                
                for minute in minutes {
                    let trainTimeInSeconds = entry.hour * 3600 + minute * 60
                    if earliestTrainTime == nil || trainTimeInSeconds < earliestTrainTime! {
                        earliestTrainTime = trainTimeInSeconds
                    }
                }
            }
            // 翌日の場合は24時間を加算
            if let earliestTime = earliestTrainTime {
                nextTrainTimeInSeconds = earliestTime + 24 * 3600
            }
        }
        
        guard let nextTime = nextTrainTimeInSeconds else { return nil }
        
        // 残り時間を計算
        let totalSecondsUntilNext = nextTime - currentTimeInSeconds
        guard totalSecondsUntilNext >= 0 else { return nil }
        
        let minutes = totalSecondsUntilNext / 60
        let seconds = totalSecondsUntilNext % 60
        
        return (minutes: minutes, seconds: seconds)
    }
}

