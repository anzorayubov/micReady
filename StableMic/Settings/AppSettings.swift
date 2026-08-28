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
            case .statusActive: return "Активно"
            case .statusActiveFor(let app): return "Активно для \(app)"
            case .statusWaiting: return "Ожидание"
            case .statusTriggered(let app): return "Триггер: \(app)"
            case .statusNoApps: return "Нет активных приложений"
            case .microphone: return "Микрофон"
            case .targetVolume: return "Цель"
            case .targetMicrophoneVolume: return "Целевая громкость микрофона"
            case .microphoneSource: return "Источник микрофона"
            case .watchedApplications: return "Отслеживаемые приложения"
            case .emptyTitle: return "Нет отслеживаемых приложений"
            case .emptySubtitle: return "Нажмите «Добавить», чтобы выбрать"
            case .addApplication: return "Добавить приложение"
            case .removeApplication: return "Удалить приложение"
            case .quit: return "Выход"
            case .languageSectionTitle: return "Интернационализация"
            case .languageSectionDescription: return "Язык интерфейса можно брать из системы или выбрать вручную."
            case .currentLanguageLabel: return "Текущий язык интерфейса"
            case .selectApplication: return "Выберите приложение"
            case .done: return "Готово"
            case .searchPlaceholder: return "Поиск..."
            case .loadingApplications: return "Загрузка приложений..."
            case .add: return "Добавить"
            case .renameMicrophone: return "Переименовать микрофон"
            case .renameMicrophonePlaceholder: return "Название микрофона"
            case .hideMicrophoneSource: return "Скрыть источник"
            case .showMicrophoneSource: return "Показать источник"
            }
        case .english, .system:
            switch key {
            case .settingsTitle: return "Settings"
            case .statusActive: return "Active"
            case .statusActiveFor(let app): return "Active for \(app)"
            case .statusWaiting: return "Waiting"
            case .statusTriggered(let app): return "Triggered by: \(app)"
            case .statusNoApps: return "No active apps"
            case .microphone: return "Microphone"
            case .targetVolume: return "Target"
            case .targetMicrophoneVolume: return "Target microphone volume"
            case .microphoneSource: return "Microphone Source"
            case .watchedApplications: return "Watched Applications"
            case .emptyTitle: return "No watched applications"
            case .emptySubtitle: return "Click Add to choose one"
            case .addApplication: return "Add Application"
            case .removeApplication: return "Remove application"
            case .quit: return "Quit"
            case .languageSectionTitle: return "Internationalization"
            case .languageSectionDescription: return "Use the macOS language automatically or choose the interface language manually."
            case .currentLanguageLabel: return "Current interface language"
            case .selectApplication: return "Select an Application"
            case .done: return "Done"
            case .searchPlaceholder: return "Search..."
            case .loadingApplications: return "Loading applications..."
            case .add: return "Add"
            case .renameMicrophone: return "Rename microphone"
            case .renameMicrophonePlaceholder: return "Microphone name"
            case .hideMicrophoneSource: return "Hide microphone source"
            case .showMicrophoneSource: return "Show microphone source"
            }
        case .chineseSimplified:
            switch key {
            case .settingsTitle: return "设置"
            case .statusActive: return "活动中"
            case .statusActiveFor(let app): return "为 \(app) 启用"
            case .statusWaiting: return "等待中"
            case .statusTriggered(let app): return "触发应用：\(app)"
            case .statusNoApps: return "没有活动的应用"
            case .microphone: return "麦克风"
            case .targetVolume: return "目标"
            case .targetMicrophoneVolume: return "麦克风目标音量"
            case .microphoneSource: return "麦克风来源"
            case .watchedApplications: return "监控的应用"
            case .emptyTitle: return "没有监控的应用"
            case .emptySubtitle: return "点击“添加”进行选择"
            case .addApplication: return "添加应用"
            case .removeApplication: return "移除应用"
            case .quit: return "退出"
            case .languageSectionTitle: return "国际化"
            case .languageSectionDescription: return "界面语言可以跟随系统，也可以手动选择。"
            case .currentLanguageLabel: return "当前界面语言"
            case .selectApplication: return "选择应用"
            case .done: return "完成"
            case .searchPlaceholder: return "搜索..."
            case .loadingApplications: return "正在加载应用..."
            case .add: return "添加"
            case .renameMicrophone: return "重命名麦克风"
            case .renameMicrophonePlaceholder: return "麦克风名称"
            case .hideMicrophoneSource: return "隐藏麦克风来源"
            case .showMicrophoneSource: return "显示麦克风来源"
            }
        case .hindi:
            switch key {
            case .settingsTitle: return "सेटिंग्स"
            case .statusActive: return "सक्रिय"
            case .statusActiveFor(let app): return "\(app) के लिए सक्रिय"
            case .statusWaiting: return "प्रतीक्षा"
            case .statusTriggered(let app): return "ट्रिगर: \(app)"
            case .statusNoApps: return "कोई सक्रिय ऐप नहीं"
            case .microphone: return "माइक्रोफोन"
            case .targetVolume: return "लक्ष्य"
            case .targetMicrophoneVolume: return "माइक्रोफ़ोन की लक्षित आवाज़"
            case .microphoneSource: return "माइक्रोफोन स्रोत"
            case .watchedApplications: return "निगरानी किए गए ऐप"
            case .emptyTitle: return "कोई निगरानी की जा रही ऐप नहीं"
            case .emptySubtitle: return "चुनने के लिए \"जोड़ें\" दबाएं"
            case .addApplication: return "ऐप जोड़ें"
            case .removeApplication: return "ऐप हटाएँ"
            case .quit: return "बंद करें"
            case .languageSectionTitle: return "अंतरराष्ट्रीयकरण"
            case .languageSectionDescription: return "इंटरफेस भाषा सिस्टम से ली जा सकती है या हाथ से चुनी जा सकती है।"
            case .currentLanguageLabel: return "वर्तमान इंटरफेस भाषा"
            case .selectApplication: return "ऐप चुनें"
            case .done: return "हो गया"
            case .searchPlaceholder: return "खोज..."
            case .loadingApplications: return "ऐप लोड हो रहे हैं..."
            case .add: return "जोड़ें"
            case .renameMicrophone: return "माइक्रोफोन का नाम बदलें"
            case .renameMicrophonePlaceholder: return "माइक्रोफोन का नाम"
            case .hideMicrophoneSource: return "माइक्रोफोन स्रोत छिपाएं"
            case .showMicrophoneSource: return "माइक्रोफोन स्रोत दिखाएं"
            }
        case .spanish:
            switch key {
            case .settingsTitle: return "Configuracion"
            case .statusActive: return "Activo"
            case .statusActiveFor(let app): return "Activo para \(app)"
            case .statusWaiting: return "En espera"
            case .statusTriggered(let app): return "Activado por: \(app)"
            case .statusNoApps: return "No hay aplicaciones activas"
            case .microphone: return "Microfono"
            case .targetVolume: return "Objetivo"
            case .targetMicrophoneVolume: return "Volumen objetivo del micrófono"
            case .microphoneSource: return "Fuente del microfono"
            case .watchedApplications: return "Aplicaciones supervisadas"
            case .emptyTitle: return "No hay aplicaciones supervisadas"
            case .emptySubtitle: return "Pulsa \"Agregar\" para elegir"
            case .addApplication: return "Agregar aplicacion"
            case .removeApplication: return "Eliminar aplicación"
            case .quit: return "Salir"
            case .languageSectionTitle: return "Internacionalizacion"
            case .languageSectionDescription: return "El idioma de la interfaz puede seguir al sistema o elegirse manualmente."
            case .currentLanguageLabel: return "Idioma actual de la interfaz"
            case .selectApplication: return "Seleccionar aplicacion"
            case .done: return "Listo"
            case .searchPlaceholder: return "Buscar..."
            case .loadingApplications: return "Cargando aplicaciones..."
            case .add: return "Agregar"
            case .renameMicrophone: return "Renombrar microfono"
            case .renameMicrophonePlaceholder: return "Nombre del microfono"
            case .hideMicrophoneSource: return "Ocultar fuente del microfono"
            case .showMicrophoneSource: return "Mostrar fuente del microfono"
            }
        case .french:
            switch key {
            case .settingsTitle: return "Parametres"
            case .statusActive: return "Actif"
            case .statusActiveFor(let app): return "Actif pour \(app)"
            case .statusWaiting: return "En attente"
            case .statusTriggered(let app): return "Declenche par : \(app)"
            case .statusNoApps: return "Aucune application active"
            case .microphone: return "Microphone"
            case .targetVolume: return "Cible"
            case .targetMicrophoneVolume: return "Volume cible du microphone"
            case .microphoneSource: return "Source du microphone"
            case .watchedApplications: return "Applications surveillées"
            case .emptyTitle: return "Aucune application surveillee"
            case .emptySubtitle: return "Cliquez sur \"Ajouter\" pour choisir"
            case .addApplication: return "Ajouter une application"
            case .removeApplication: return "Supprimer l’application"
            case .quit: return "Quitter"
            case .languageSectionTitle: return "Internationalisation"
            case .languageSectionDescription: return "La langue de l'interface peut suivre le systeme ou etre choisie manuellement."
            case .currentLanguageLabel: return "Langue actuelle de l'interface"
            case .selectApplication: return "Choisir une application"
            case .done: return "Termine"
            case .searchPlaceholder: return "Rechercher..."
            case .loadingApplications: return "Chargement des applications..."
            case .add: return "Ajouter"
            case .renameMicrophone: return "Renommer le microphone"
            case .renameMicrophonePlaceholder: return "Nom du microphone"
            case .hideMicrophoneSource: return "Masquer la source du microphone"
            case .showMicrophoneSource: return "Afficher la source du microphone"
            }
        case .arabic:
            switch key {
            case .settingsTitle: return "الإعدادات"
            case .statusActive: return "نشط"
            case .statusActiveFor(let app): return "نشط لـ \(app)"
            case .statusWaiting: return "في الانتظار"
            case .statusTriggered(let app): return "تم التفعيل بواسطة: \(app)"
            case .statusNoApps: return "لا توجد تطبيقات نشطة"
            case .microphone: return "الميكروفون"
            case .targetVolume: return "الهدف"
            case .targetMicrophoneVolume: return "مستوى صوت الميكروفون المستهدف"
            case .microphoneSource: return "مصدر الميكروفون"
            case .watchedApplications: return "التطبيقات المراقبة"
            case .emptyTitle: return "لا توجد تطبيقات مراقبة"
            case .emptySubtitle: return "اضغط \"إضافة\" للاختيار"
            case .addApplication: return "إضافة تطبيق"
            case .removeApplication: return "إزالة التطبيق"
            case .quit: return "خروج"
            case .languageSectionTitle: return "تعدد اللغات"
            case .languageSectionDescription: return "يمكن أن تتبع لغة الواجهة النظام أو يتم اختيارها يدويا."
            case .currentLanguageLabel: return "لغة الواجهة الحالية"
            case .selectApplication: return "اختر تطبيقا"
            case .done: return "تم"
            case .searchPlaceholder: return "بحث..."
            case .loadingApplications: return "جار تحميل التطبيقات..."
            case .add: return "إضافة"
            case .renameMicrophone: return "إعادة تسمية الميكروفون"
            case .renameMicrophonePlaceholder: return "اسم الميكروفون"
            case .hideMicrophoneSource: return "إخفاء مصدر الميكروفون"
            case .showMicrophoneSource: return "إظهار مصدر الميكروفون"
            }
        case .bengali:
            switch key {
            case .settingsTitle: return "সেটিংস"
            case .statusActive: return "সক্রিয়"
            case .statusActiveFor(let app): return "\(app)-এর জন্য সক্রিয়"
            case .statusWaiting: return "অপেক্ষা"
            case .statusTriggered(let app): return "ট্রিগার: \(app)"
            case .statusNoApps: return "কোনও সক্রিয় অ্যাপ নেই"
            case .microphone: return "মাইক্রোফোন"
            case .targetVolume: return "লক্ষ্য"
            case .targetMicrophoneVolume: return "মাইক্রোফোনের লক্ষ্য ভলিউম"
            case .microphoneSource: return "মাইক্রোফোন উৎস"
            case .watchedApplications: return "পর্যবেক্ষিত অ্যাপ"
            case .emptyTitle: return "কোনও পর্যবেক্ষিত অ্যাপ নেই"
            case .emptySubtitle: return "\"যোগ করুন\" চাপুন নির্বাচন করতে"
            case .addApplication: return "অ্যাপ যোগ করুন"
            case .removeApplication: return "অ্যাপ সরান"
            case .quit: return "প্রস্থান"
            case .languageSectionTitle: return "আন্তর্জাতিকীকরণ"
            case .languageSectionDescription: return "ইন্টারফেসের ভাষা সিস্টেম থেকে নেওয়া বা হাতে বেছে নেওয়া যেতে পারে।"
            case .currentLanguageLabel: return "বর্তমান ইন্টারফেস ভাষা"
            case .selectApplication: return "অ্যাপ নির্বাচন করুন"
            case .done: return "সম্পন্ন"
            case .searchPlaceholder: return "খুঁজুন..."
            case .loadingApplications: return "অ্যাপ লোড হচ্ছে..."
            case .add: return "যোগ করুন"
            case .renameMicrophone: return "মাইক্রোফোনের নাম বদলান"
            case .renameMicrophonePlaceholder: return "মাইক্রোফোনের নাম"
            case .hideMicrophoneSource: return "মাইক্রোফোন উৎস লুকান"
            case .showMicrophoneSource: return "মাইক্রোফোন উৎস দেখান"
            }
        case .portuguese:
            switch key {
            case .settingsTitle: return "Configuracoes"
            case .statusActive: return "Ativo"
            case .statusActiveFor(let app): return "Ativo para \(app)"
            case .statusWaiting: return "Aguardando"
            case .statusTriggered(let app): return "Acionado por: \(app)"
            case .statusNoApps: return "Nenhum aplicativo ativo"
            case .microphone: return "Microfone"
            case .targetVolume: return "Meta"
            case .targetMicrophoneVolume: return "Volume alvo do microfone"
            case .microphoneSource: return "Fonte do microfone"
            case .watchedApplications: return "Aplicativos monitorados"
            case .emptyTitle: return "Nenhum aplicativo monitorado"
            case .emptySubtitle: return "Clique em \"Adicionar\" para escolher"
            case .addApplication: return "Adicionar aplicativo"
            case .removeApplication: return "Remover aplicativo"
            case .quit: return "Sair"
            case .languageSectionTitle: return "Internacionalizacao"
            case .languageSectionDescription: return "O idioma da interface pode seguir o sistema ou ser escolhido manualmente."
            case .currentLanguageLabel: return "Idioma atual da interface"
            case .selectApplication: return "Selecionar aplicativo"
            case .done: return "Concluir"
            case .searchPlaceholder: return "Pesquisar..."
            case .loadingApplications: return "Carregando aplicativos..."
            case .add: return "Adicionar"
            case .renameMicrophone: return "Renomear microfone"
            case .renameMicrophonePlaceholder: return "Nome do microfone"
            case .hideMicrophoneSource: return "Ocultar fonte do microfone"
            case .showMicrophoneSource: return "Mostrar fonte do microfone"
            }
        case .urdu:
            switch key {
            case .settingsTitle: return "ترتیبات"
            case .statusActive: return "فعال"
            case .statusActiveFor(let app): return "\(app) کے لیے فعال"
            case .statusWaiting: return "انتظار میں"
            case .statusTriggered(let app): return "ٹریگر: \(app)"
            case .statusNoApps: return "کوئی فعال ایپ نہیں"
            case .microphone: return "مائیکروفون"
            case .targetVolume: return "ہدف"
            case .targetMicrophoneVolume: return "مائیکروفون کا ہدفی والیوم"
            case .microphoneSource: return "مائیکروفون ماخذ"
            case .watchedApplications: return "زیر نگرانی ایپس"
            case .emptyTitle: return "کوئی زیر نگرانی ایپ نہیں"
            case .emptySubtitle: return "منتخب کرنے کے لیے \"شامل کریں\" دبائیں"
            case .addApplication: return "ایپ شامل کریں"
            case .removeApplication: return "ایپ ہٹائیں"
            case .quit: return "بند کریں"
            case .languageSectionTitle: return "بین الاقوامی کاری"
            case .languageSectionDescription: return "انٹرفیس کی زبان سسٹم سے لی جا سکتی ہے یا دستی طور پر منتخب کی جا سکتی ہے۔"
            case .currentLanguageLabel: return "موجودہ انٹرفیس زبان"
            case .selectApplication: return "ایپ منتخب کریں"
            case .done: return "ہو گیا"
            case .searchPlaceholder: return "تلاش..."
            case .loadingApplications: return "ایپس لوڈ ہو رہی ہیں..."
            case .add: return "شامل کریں"
            case .renameMicrophone: return "مائیکروفون کا نام تبدیل کریں"
            case .renameMicrophonePlaceholder: return "مائیکروفون کا نام"
            case .hideMicrophoneSource: return "مائیکروفون ماخذ چھپائیں"
            case .showMicrophoneSource: return "مائیکروفون ماخذ دکھائیں"
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
