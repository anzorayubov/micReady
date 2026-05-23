# MicReady
<img width="326" height="552" alt="image" src="https://github.com/user-attachments/assets/6bc37c64-81b7-4168-82b6-6be2f4862180" />

Приложение для menu bar macOS, которое автоматически поддерживает выбранную громкость микрофона, когда запущены указанные приложения (Zoom, Teams, Google Meet и т.д.).

## Требования

- macOS 13.0+
- Xcode 15+

## Сборка

1. Открой `MicReady.xcodeproj` в Xcode
2. Выбери таргет `MicReady`
3. В настройках Signing & Capabilities — укажи свой Apple ID (бесплатный достаточно)
4. `Cmd+R` — собрать и запустить

## Добавление в автозапуск

После первого запуска: Настройки macOS → Основные → Объекты входа → добавь MicReady.app

## Как работает

- Каждые 2 секунды проверяет список запущенных приложений
- При выборе конкретного источника в интерфейсе переключает системный input device macOS на этот микрофон
- Если запущено хотя бы одно из отслеживаемых — поддерживает выбранную громкость микрофона через CoreAudio API
- Целевую громкость можно выбрать в popover с помощью горизонтального ползунка с шагами `0 / 25 / 50 / 75 / 100`
- Настройки сохраняются в UserDefaults между запусками
- Иконка в menu bar показывает текущий статус (зелёная = активен)

## Структура файлов

```
MicReady/
├── MicReadyApp.swift              # Точка входа
├── AppDelegate.swift              # Menu bar иконка и popover
├── MicrophoneMonitor.swift        # Оркестрация мониторинга
├── Models/
│   ├── AudioInputDevice.swift     # Модель входного аудиоустройства
│   └── WatchedApp.swift           # Модель отслеживаемого приложения
├── Services/
│   ├── AudioDeviceService.swift   # CoreAudio операции
│   ├── InstalledAppsService.swift # Поиск установленных приложений
│   └── SettingsStore.swift        # Persistence через UserDefaults
├── Settings/
│   ├── AppSettings.swift          # Настройки и локализация
│   └── LocalizedText.swift        # Ключи локализованных строк
├── Views/
│   ├── ContentView.swift          # Root container интерфейса
│   ├── AppPicker/
│   │   ├── AppIconProvider.swift
│   │   └── AppPickerView.swift
│   ├── Main/
│   │   ├── EmptyStateView.swift
│   │   ├── FooterView.swift
│   │   ├── HeaderView.swift
│   │   ├── StatusView.swift
│   │   ├── VolumeControlView.swift
│   │   ├── WatchedAppRow.swift
│   │   └── WatchedAppsListView.swift
│   └── Settings/
│       └── SettingsView.swift
└── MicReady.entitlements          # Права доступа к аудио
```

## Известные ограничения

- Некоторые USB/Bluetooth микрофоны не поддерживают программное управление громкостью через CoreAudio — в этом случае приложение не сможет изменить громкость аппаратно
- Если AGC в Zoom/Teams очень агрессивный, рекомендуется также отключить его в настройках самого приложения
