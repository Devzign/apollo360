import SwiftUI

struct HomeFeelingSectionView: View {
    let recentSymptoms: [DashboardRecentSymptom]
    let onLogTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack(alignment: .bottomLeading) {
                LinearGradient(
                    colors: [AppColor.green, AppColor.green.opacity(0.72)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
                HStack(spacing: 12) {
                    ZStack {
                        Circle().fill(Color.white.opacity(0.20)).frame(width: 44, height: 44)
                        Image(systemName: "heart.fill")
                            .font(.system(size: 19, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("I'm Feeling")
                            .font(AppFont.display(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        Text(recentSymptoms.isEmpty
                             ? "Nothing logged yet"
                             : "\(recentSymptoms.count) entr\(recentSymptoms.count == 1 ? "y" : "ies") logged")
                            .font(AppFont.body(size: 12, weight: .regular))
                            .foregroundColor(.white.opacity(0.82))
                    }
                    Spacer()
                    Button(action: onLogTap) {
                        HStack(spacing: 5) {
                            Image(systemName: "plus")
                                .font(.system(size: 11, weight: .bold))
                            Text("Log")
                                .font(AppFont.body(size: 13, weight: .semibold))
                        }
                        .foregroundColor(AppColor.green)
                        .padding(.horizontal, 14)
                        .frame(height: 34)
                        .background(Capsule().fill(Color.white))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
            .frame(maxWidth: .infinity)
            .cornerRadius(16)
            .shadow(color: AppColor.green.opacity(0.28), radius: 12, y: 4)

            if recentSymptoms.isEmpty {
                VStack(spacing: 14) {
                    ZStack {
                        Circle().fill(AppColor.green.opacity(0.08)).frame(width: 72, height: 72)
                        Image(systemName: "heart.slash.fill")
                            .font(.system(size: 30))
                            .foregroundColor(AppColor.green.opacity(0.40))
                    }
                    Text("Nothing logged yet")
                        .font(AppFont.body(size: 16, weight: .semibold))
                        .foregroundColor(AppColor.color414141)
                    Text("Tap \"Log\" above to record how you're feeling.")
                        .font(AppFont.body(size: 13, weight: .regular))
                        .foregroundColor(AppColor.grey)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 44)
                .background(RoundedRectangle(cornerRadius: 16).fill(Color.white))
                .shadow(color: Color.black.opacity(0.04), radius: 8, y: 3)
            } else {
                VStack(spacing: 10) {
                    ForEach(Array(recentSymptoms.enumerated()), id: \.offset) { _, symptom in
                        let (icon, accent) = symptomMeta(symptom.symptoms)
                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(accent.opacity(0.13))
                                    .frame(width: 46, height: 46)
                                Image(systemName: icon)
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(accent)
                            }
                            VStack(alignment: .leading, spacing: 3) {
                                Text(symptom.symptoms)
                                    .font(AppFont.body(size: 15, weight: .semibold))
                                    .foregroundColor(AppColor.color414141)
                                Text(feelingSmartDate(symptom.createdAt))
                                    .font(AppFont.body(size: 12, weight: .regular))
                                    .foregroundColor(AppColor.grey)
                            }
                            Spacer()
                            Text(symptomCategory(symptom.symptoms))
                                .font(AppFont.body(size: 10, weight: .semibold))
                                .foregroundColor(accent)
                                .padding(.horizontal, 9)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(accent.opacity(0.12)))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.04), radius: 6, y: 2)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(accent.opacity(0.12), lineWidth: 1)
                        )
                    }
                }
            }
        }
    }

    private func symptomMeta(_ s: String) -> (String, Color) {
        let lower = s.lowercased()
        if lower.contains("chest") { return ("heart.fill", Color(red: 0.90, green: 0.25, blue: 0.28)) }
        if lower.contains("palpit") { return ("waveform.path.ecg", Color(red: 0.88, green: 0.35, blue: 0.28)) }
        if lower.contains("breath") { return ("lungs.fill", Color(red: 0.30, green: 0.55, blue: 0.90)) }
        if lower.contains("dizz") { return ("tornado", Color(red: 0.62, green: 0.40, blue: 0.90)) }
        if lower.contains("fatigue") || lower.contains("tired") { return ("battery.25percent", Color(red: 0.85, green: 0.62, blue: 0.18)) }
        if lower.contains("pain") { return ("cross.circle.fill", Color(red: 0.85, green: 0.28, blue: 0.38)) }
        if lower.contains("happy") { return ("face.smiling.fill", Color(red: 0.25, green: 0.72, blue: 0.42)) }
        if lower.contains("sad") { return ("cloud.rain.fill", Color(red: 0.35, green: 0.52, blue: 0.88)) }
        if lower.contains("anxious") { return ("bolt.fill", Color(red: 0.90, green: 0.58, blue: 0.18)) }
        if lower.contains("nausea") || lower.contains("sick") { return ("allergens", Color(red: 0.50, green: 0.72, blue: 0.38)) }
        return ("heart.text.square.fill", AppColor.green)
    }

    private func symptomCategory(_ s: String) -> String {
        let lower = s.lowercased()
        if lower.contains("chest") || lower.contains("palpit") || lower.contains("breath") { return "Cardiac" }
        if lower.contains("pain") || lower.contains("dizz") { return "Physical" }
        if lower.contains("happy") || lower.contains("sad") || lower.contains("anxious") { return "Mental" }
        if lower.contains("fatigue") || lower.contains("tired") { return "Energy" }
        return "General"
    }

    private func feelingSmartDate(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)

        var parsed: Date?
        let isoFull = ISO8601DateFormatter()
        isoFull.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        parsed = isoFull.date(from: trimmed)
        if parsed == nil {
            isoFull.formatOptions = [.withInternetDateTime]
            parsed = isoFull.date(from: trimmed)
        }
        if parsed == nil {
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd"
            df.timeZone = TimeZone(identifier: "UTC")
            parsed = df.date(from: String(trimmed.prefix(10)))
        }
        guard let d = parsed else { return String(trimmed.prefix(10)) }

        let isDateOnly = trimmed.count <= 10
            || trimmed.hasSuffix("T00:00:00.000Z")
            || trimmed.hasSuffix("T00:00:00Z")

        let cal = Calendar.current
        if cal.isDateInToday(d) { return "Today" }
        if cal.isDateInYesterday(d) { return "Yesterday" }

        let df = DateFormatter()
        df.dateFormat = isDateOnly ? "EEE, d MMM yyyy" : "EEE, d MMM yyyy · h:mm a"
        return df.string(from: d)
    }
}
