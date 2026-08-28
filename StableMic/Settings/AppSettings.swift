import Foundation

final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    enum AppLanguage: String, CaseIterable, Identifiable {
        case system
        case russian
        case english
        case chineseSimplified
        case hindi
        case spanish
        case french
        case arabic
        case bengali
        case portuguese
        case urdu

        var id: String { rawValue }
    }

    @Published var selectedLanguage: AppLanguage {
        didSet {
            defaults.set(selectedLanguage.rawValue, forKey: selectedLanguageKey)
        }
    }

    private let defaults = UserDefaults.standard
    private let selectedLanguageKey = "selectedLanguage"

    private init() {
        let storedValue = defaults.string(forKey: selectedLanguageKey)
        selectedLanguage = AppLanguage(rawValue: storedValue ?? "") ?? .system
    }

    var resolvedLanguage: AppLanguage {
        switch selectedLanguage {
        case .system:
            let code = Locale.preferredLanguages.first?
                .split(separator: "-")
                .first?
                .lowercased()

            switch code {
            case "ru":
                return .russian
            case "en":
                return .english
            case "zh":
                return .chineseSimplified
            case "hi":
                return .hindi
            case "es":
                return .spanish
            case "fr":
                return .french
            case "ar":
                return .arabic
            case "bn":
                return .bengali
            case "pt":
                return .portuguese
            case "ur":
                return .urdu
            default:
                return .english
            }
        case .russian, .english, .chineseSimplified, .hindi, .spanish, .french, .arabic, .bengali, .portuguese, .urdu:
            return selectedLanguage
        }
    }

    var resolvedLanguageDescription: String {
        switch selectedLanguage {
        case .system:
            switch resolvedLanguage {
            case .russian:
                return "System: Russian"
            case .english:
                return "System: English"
            case .chineseSimplified:
                return "System: Chinese (Simplified)"
            case .hindi:
                return "System: Hindi"
            case .spanish:
                return "System: Spanish"
            case .french:
                return "System: French"
            case .arabic:
                return "System: Arabic"
            case .bengali:
                return "System: Bengali"
            case .portuguese:
                return "System: Portuguese"
            case .urdu:
                return "System: Urdu"
            case .system:
                return "System"
            }
        case .russian:
            return languageDisplayName(.russian)
        case .english:
            return languageDisplayName(.english)
        case .chineseSimplified:
            return languageDisplayName(.chineseSimplified)
        case .hindi:
            return languageDisplayName(.hindi)
        case .spanish:
            return languageDisplayName(.spanish)
        case .french:
            return languageDisplayName(.french)
        case .arabic:
            return languageDisplayName(.arabic)
        case .bengali:
            return languageDisplayName(.bengali)
        case .portuguese:
            return languageDisplayName(.portuguese)
        case .urdu:
            return languageDisplayName(.urdu)
        }
    }

    func languageDisplayName(_ language: AppLanguage) -> String {
        switch language {
        case .system: return localizedLanguageLabel(system: true, language: resolvedLanguage)
        case .russian: return "Русский"
        case .english: return "English"
        case .chineseSimplified: return "简体中文"
        case .hindi: return "हिन्दी"
        case .spanish: return "Español"
        case .french: return "Français"
        case .arabic: return "العربية"
        case .bengali: return "বাংলা"
        case .portuguese: return "Português"
        case .urdu: return "اردو"
        }
    }

    func text(_ key: LocalizedText) -> String {
        switch resolvedLanguage {
        case .russian:
            switch key {
            case .settingsTitle: return "Настройки"
            case .microphone: return "Микрофон"
            case .targetVolume: return "Цель"
            case .targetMicrophoneVolume: return "Целевая громкость микрофона"
            case .microphoneSource: return "Источник микрофона"
            case .quit: return "Выход"
            case .launchAtLogin: return "Запускать при входе в систему"
            case .languageSectionTitle: return "Интернационализация"
            case .languageSectionDescription: return "Язык интерфейса можно брать из системы или выбрать вручную."
            case .currentLanguageLabel: return "Текущий язык интерфейса"
            case .done: return "Готово"
            case .renameMicrophone: return "Переименовать микрофон"
            case .renameMicrophonePlaceholder: return "Название микрофона"
            case .hideMicrophoneSource: return "Скрыть источник"
            case .showMicrophoneSource: return "Показать источник"
            case .microphoneSwitchError: return "Произошла ошибка"
            }
        case .english, .system:
            switch key {
            case .settingsTitle: return "Settings"
            case .microphone: return "Microphone"
            case .targetVolume: return "Target"
            case .targetMicrophoneVolume: return "Target microphone volume"
            case .microphoneSource: return "Microphone Source"
            case .quit: return "Quit"
            case .launchAtLogin: return "Launch at login"
            case .languageSectionTitle: return "Internationalization"
            case .languageSectionDescription: return "Use the macOS language automatically or choose the interface language manually."
            case .currentLanguageLabel: return "Current interface language"
            case .done: return "Done"
            case .renameMicrophone: return "Rename microphone"
            case .renameMicrophonePlaceholder: return "Microphone name"
            case .hideMicrophoneSource: return "Hide microphone source"
            case .showMicrophoneSource: return "Show microphone source"
            case .microphoneSwitchError: return "An error occurred"
            }
        case .chineseSimplified:
            switch key {
            case .settingsTitle: return "设置"
            case .microphone: return "麦克风"
            case .targetVolume: return "目标"
            case .targetMicrophoneVolume: return "麦克风目标音量"
            case .microphoneSource: return "麦克风来源"
            case .quit: return "退出"
            case .launchAtLogin: return "登录时启动"
            case .languageSectionTitle: return "国际化"
            case .languageSectionDescription: return "界面语言可以跟随系统，也可以手动选择。"
            case .currentLanguageLabel: return "当前界面语言"
            case .done: return "完成"
            case .renameMicrophone: return "重命名麦克风"
            case .renameMicrophonePlaceholder: return "麦克风名称"
            case .hideMicrophoneSource: return "隐藏麦克风来源"
            case .showMicrophoneSource: return "显示麦克风来源"
            case .microphoneSwitchError: return "发生错误"
            }
        case .hindi:
            switch key {
            case .settingsTitle: return "सेटिंग्स"
            case .microphone: return "माइक्रोफोन"
            case .targetVolume: return "लक्ष्य"
            case .targetMicrophoneVolume: return "माइक्रोफ़ोन की लक्षित आवाज़"
            case .microphoneSource: return "माइक्रोफोन स्रोत"
            case .quit: return "बंद करें"
            case .launchAtLogin: return "लॉगिन पर शुरू करें"
            case .languageSectionTitle: return "अंतरराष्ट्रीयकरण"
            case .languageSectionDescription: return "इंटरफेस भाषा सिस्टम से ली जा सकती है या हाथ से चुनी जा सकती है।"
            case .currentLanguageLabel: return "वर्तमान इंटरफेस भाषा"
            case .done: return "हो गया"
            case .renameMicrophone: return "माइक्रोफोन का नाम बदलें"
            case .renameMicrophonePlaceholder: return "माइक्रोफोन का नाम"
            case .hideMicrophoneSource: return "माइक्रोफोन स्रोत छिपाएं"
            case .showMicrophoneSource: return "माइक्रोफोन स्रोत दिखाएं"
            case .microphoneSwitchError: return "एक त्रुटि हुई"
            }
        case .spanish:
            switch key {
            case .settingsTitle: return "Configuracion"
            case .microphone: return "Microfono"
            case .targetVolume: return "Objetivo"
            case .targetMicrophoneVolume: return "Volumen objetivo del micrófono"
            case .microphoneSource: return "Fuente del microfono"
            case .quit: return "Salir"
            case .launchAtLogin: return "Abrir al iniciar sesión"
            case .languageSectionTitle: return "Internacionalizacion"
            case .languageSectionDescription: return "El idioma de la interfaz puede seguir al sistema o elegirse manualmente."
            case .currentLanguageLabel: return "Idioma actual de la interfaz"
            case .done: return "Listo"
            case .renameMicrophone: return "Renombrar microfono"
            case .renameMicrophonePlaceholder: return "Nombre del microfono"
            case .hideMicrophoneSource: return "Ocultar fuente del microfono"
            case .showMicrophoneSource: return "Mostrar fuente del microfono"
            case .microphoneSwitchError: return "Se produjo un error"
            }
        case .french:
            switch key {
            case .settingsTitle: return "Parametres"
            case .microphone: return "Microphone"
            case .targetVolume: return "Cible"
            case .targetMicrophoneVolume: return "Volume cible du microphone"
            case .microphoneSource: return "Source du microphone"
            case .quit: return "Quitter"
            case .launchAtLogin: return "Ouvrir à l’ouverture de session"
            case .languageSectionTitle: return "Internationalisation"
            case .languageSectionDescription: return "La langue de l'interface peut suivre le systeme ou etre choisie manuellement."
            case .currentLanguageLabel: return "Langue actuelle de l'interface"
            case .done: return "Termine"
            case .renameMicrophone: return "Renommer le microphone"
            case .renameMicrophonePlaceholder: return "Nom du microphone"
            case .hideMicrophoneSource: return "Masquer la source du microphone"
            case .showMicrophoneSource: return "Afficher la source du microphone"
            case .microphoneSwitchError: return "Une erreur est survenue"
            }
        case .arabic:
            switch key {
            case .settingsTitle: return "الإعدادات"
            case .microphone: return "الميكروفون"
            case .targetVolume: return "الهدف"
            case .targetMicrophoneVolume: return "مستوى صوت الميكروفون المستهدف"
            case .microphoneSource: return "مصدر الميكروفون"
            case .quit: return "خروج"
            case .launchAtLogin: return "التشغيل عند تسجيل الدخول"
            case .languageSectionTitle: return "تعدد اللغات"
            case .languageSectionDescription: return "يمكن أن تتبع لغة الواجهة النظام أو يتم اختيارها يدويا."
            case .currentLanguageLabel: return "لغة الواجهة الحالية"
            case .done: return "تم"
            case .renameMicrophone: return "إعادة تسمية الميكروفون"
            case .renameMicrophonePlaceholder: return "اسم الميكروفون"
            case .hideMicrophoneSource: return "إخفاء مصدر الميكروفون"
            case .showMicrophoneSource: return "إظهار مصدر الميكروفون"
            case .microphoneSwitchError: return "حدث خطأ"
            }
        case .bengali:
            switch key {
            case .settingsTitle: return "সেটিংস"
            case .microphone: return "মাইক্রোফোন"
            case .targetVolume: return "লক্ষ্য"
            case .targetMicrophoneVolume: return "মাইক্রোফোনের লক্ষ্য ভলিউম"
            case .microphoneSource: return "মাইক্রোফোন উৎস"
            case .quit: return "প্রস্থান"
            case .launchAtLogin: return "লগইন করলে চালু করুন"
            case .languageSectionTitle: return "আন্তর্জাতিকীকরণ"
            case .languageSectionDescription: return "ইন্টারফেসের ভাষা সিস্টেম থেকে নেওয়া বা হাতে বেছে নেওয়া যেতে পারে।"
            case .currentLanguageLabel: return "বর্তমান ইন্টারফেস ভাষা"
            case .done: return "সম্পন্ন"
            case .renameMicrophone: return "মাইক্রোফোনের নাম বদলান"
            case .renameMicrophonePlaceholder: return "মাইক্রোফোনের নাম"
            case .hideMicrophoneSource: return "মাইক্রোফোন উৎস লুকান"
            case .showMicrophoneSource: return "মাইক্রোফোন উৎস দেখান"
            case .microphoneSwitchError: return "একটি ত্রুটি ঘটেছে"
            }
        case .portuguese:
            switch key {
            case .settingsTitle: return "Configuracoes"
            case .microphone: return "Microfone"
            case .targetVolume: return "Meta"
            case .targetMicrophoneVolume: return "Volume alvo do microfone"
            case .microphoneSource: return "Fonte do microfone"
            case .quit: return "Sair"
            case .launchAtLogin: return "Abrir ao iniciar sessão"
            case .languageSectionTitle: return "Internacionalizacao"
            case .languageSectionDescription: return "O idioma da interface pode seguir o sistema ou ser escolhido manualmente."
            case .currentLanguageLabel: return "Idioma atual da interface"
            case .done: return "Concluir"
            case .renameMicrophone: return "Renomear microfone"
            case .renameMicrophonePlaceholder: return "Nome do microfone"
            case .hideMicrophoneSource: return "Ocultar fonte do microfone"
            case .showMicrophoneSource: return "Mostrar fonte do microfone"
            case .microphoneSwitchError: return "Ocorreu um erro"
            }
        case .urdu:
            switch key {
            case .settingsTitle: return "ترتیبات"
            case .microphone: return "مائیکروفون"
            case .targetVolume: return "ہدف"
            case .targetMicrophoneVolume: return "مائیکروفون کا ہدفی والیوم"
            case .microphoneSource: return "مائیکروفون ماخذ"
            case .quit: return "بند کریں"
            case .launchAtLogin: return "لاگ اِن پر شروع کریں"
            case .languageSectionTitle: return "بین الاقوامی کاری"
            case .languageSectionDescription: return "انٹرفیس کی زبان سسٹم سے لی جا سکتی ہے یا دستی طور پر منتخب کی جا سکتی ہے۔"
            case .currentLanguageLabel: return "موجودہ انٹرفیس زبان"
            case .done: return "ہو گیا"
            case .renameMicrophone: return "مائیکروفون کا نام تبدیل کریں"
            case .renameMicrophonePlaceholder: return "مائیکروفون کا نام"
            case .hideMicrophoneSource: return "مائیکروفون ماخذ چھپائیں"
            case .showMicrophoneSource: return "مائیکروفون ماخذ دکھائیں"
            case .microphoneSwitchError: return "ایک خرابی پیش آگئی"
            }
        }
    }

    private func localizedLanguageLabel(system: Bool, language: AppLanguage) -> String {
        if system {
            switch language {
            case .russian: return "Системный"
            case .english: return "System"
            case .chineseSimplified: return "系统"
            case .hindi: return "सिस्टम"
            case .spanish: return "Sistema"
            case .french: return "Systeme"
            case .arabic: return "النظام"
            case .bengali: return "সিস্টেম"
            case .portuguese: return "Sistema"
            case .urdu: return "سسٹم"
            case .system: return "System"
            }
        }

        return "System"
    }
}
