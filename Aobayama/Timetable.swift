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

struct TrainInfo {
    let hour: Int
    let minute: Int
    let minutesUntil: Int
    let secondsUntil: Int
    let isNextDay: Bool
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
    
    func getNextTrains(count: Int = 3) -> [TrainInfo] {
        guard let timetable = timetable else { return [] }
        
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.hour, .minute, .second, .weekday], from: now)
        guard let currentHour = components.hour,
              let currentMinute = components.minute,
              let currentSecond = components.second,
              let weekday = components.weekday else {
            return []
        }
        
        // 1=日曜日、7=土曜日。日本の祝日判定は簡易的に土日を祝日として扱う
        let isHoliday = weekday == 1 || weekday == 7
        
        // 現在時刻を秒に変換
        let currentTimeInSeconds = currentHour * 3600 + currentMinute * 60 + currentSecond
        
        // すべての未来の電車時刻を収集
        var trainTimes: [(hour: Int, minute: Int, seconds: Int)] = []
        
        // 今日の残りの時刻をチェック
        for entry in timetable.entries {
            guard entry.hour >= currentHour else { continue }
            
            let minutes = isHoliday ? entry.holiday : entry.weekday
            
            for minute in minutes {
                let trainTimeInSeconds = entry.hour * 3600 + minute * 60
                
                if trainTimeInSeconds > currentTimeInSeconds {
                    trainTimes.append((hour: entry.hour, minute: minute, seconds: trainTimeInSeconds))
                }
            }
        }
        
        // 今日見つからなければ、翌日の電車も追加
        if trainTimes.isEmpty {
            for entry in timetable.entries {
                let minutes = isHoliday ? entry.holiday : entry.weekday
                
                for minute in minutes {
                    let trainTimeInSeconds = entry.hour * 3600 + minute * 60
                    trainTimes.append((hour: entry.hour, minute: minute, seconds: trainTimeInSeconds + 24 * 3600))
                }
            }
        } else {
            // 今日の電車が少ない場合は、翌日の電車も追加
            if trainTimes.count < count {
                for entry in timetable.entries {
                    let minutes = isHoliday ? entry.holiday : entry.weekday
                    
                    for minute in minutes {
                        let trainTimeInSeconds = entry.hour * 3600 + minute * 60
                        trainTimes.append((hour: entry.hour, minute: minute, seconds: trainTimeInSeconds + 24 * 3600))
                    }
                }
            }
        }
        
        // 時刻順にソート
        trainTimes.sort { $0.seconds < $1.seconds }
        
        // 指定された数の電車情報を返す
        var result: [TrainInfo] = []
        for i in 0..<min(count, trainTimes.count) {
            let train = trainTimes[i]
            let totalSecondsUntil = train.seconds - currentTimeInSeconds
            guard totalSecondsUntil >= 0 else { continue }
            
            // 翌日の電車かどうかを判定（24時間以上先なら翌日）
            // train.secondsに24*3600が加算されている場合は翌日の電車
            let isNextDay = train.seconds >= 24 * 3600
            
            let minutesUntil = totalSecondsUntil / 60
            let secondsUntil = totalSecondsUntil % 60
            
            result.append(TrainInfo(
                hour: train.hour,
                minute: train.minute,
                minutesUntil: minutesUntil,
                secondsUntil: secondsUntil,
                isNextDay: isNextDay
            ))
        }
        
        return result
    }
}

