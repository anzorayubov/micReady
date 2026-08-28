#!/bin/zsh

set -u
setopt pipe_fail

readonly project_root="${0:A:h}"
readonly project_file="$project_root/StableMic.xcodeproj"
readonly source_directory="$project_root/StableMic"
readonly derived_data_directory="${TMPDIR:-/tmp}/StableMicLiveReload"
readonly application_name="StableMic"
readonly application_path="$derived_data_directory/Build/Products/Debug/$application_name.app"
readonly watcher_lock_directory="${TMPDIR:-/tmp}/StableMicLiveReloadWatcher"

acquire_watcher_lock() {
    if mkdir "$watcher_lock_directory" 2>/dev/null; then
        print -r -- "$$" > "$watcher_lock_directory/pid"
        return
    fi

    local existing_pid=''
    if [[ -r "$watcher_lock_directory/pid" ]]; then
        read -r existing_pid < "$watcher_lock_directory/pid"
    fi

    if [[ -n "$existing_pid" ]] && kill -0 "$existing_pid" 2>/dev/null; then
        print -u2 "[StableMic] Live reload уже запущен (PID $existing_pid)."
        exit 1
    fi

    rm -f "$watcher_lock_directory/pid"
    rmdir "$watcher_lock_directory" 2>/dev/null || true

    if ! mkdir "$watcher_lock_directory" 2>/dev/null; then
        print -u2 '[StableMic] Не удалось создать блокировку watcher.'
        exit 1
    fi

    print -r -- "$$" > "$watcher_lock_directory/pid"
}

release_watcher_lock() {
    local owner_pid=''
    if [[ -r "$watcher_lock_directory/pid" ]]; then
        read -r owner_pid < "$watcher_lock_directory/pid"
    fi

    if [[ "$owner_pid" == "$$" ]]; then
        rm -f "$watcher_lock_directory/pid"
        rmdir "$watcher_lock_directory" 2>/dev/null || true
    fi
}

source_fingerprint() {
    find "$source_directory" "$project_file" \
        -type f \
        ! -path '*/xcuserdata/*' \
        ! -name '*.xcuserstate' \
        -exec stat -f '%m:%z:%N' {} + 2>/dev/null \
        | LC_ALL=C sort \
        | shasum \
        | awk '{ print $1 }'
}

running_application_pids() {
    pgrep -x "$application_name" 2>/dev/null || true
}

stop_attached_debuggers() {
    local application_pid
    local parent_pid
    local parent_command

    for application_pid in "$@"; do
        parent_pid="$(ps -p "$application_pid" -o ppid= 2>/dev/null | tr -d '[:space:]')"
        [[ -n "$parent_pid" ]] || continue

        parent_command="$(ps -p "$parent_pid" -o comm= 2>/dev/null)"
        if [[ "${parent_command:t}" == 'debugserver' ]]; then
            print "[StableMic] Останавливаю debug-сессию Xcode (PID $parent_pid)…"
            kill -TERM "$parent_pid" 2>/dev/null || true
        fi
    done
}

stop_running_applications() {
    local -a application_pids
    application_pids=(${(f)"$(running_application_pids)"})

    (( ${#application_pids} == 0 )) && return 0

    print "[StableMic] Завершаю старые экземпляры: ${application_pids[*]}"
    kill -TERM "${application_pids[@]}" 2>/dev/null || true

    for _ in {1..20}; do
        application_pids=(${(f)"$(running_application_pids)"})
        (( ${#application_pids} == 0 )) && return 0
        sleep 0.1
    done

    stop_attached_debuggers "${application_pids[@]}"

    for _ in {1..10}; do
        application_pids=(${(f)"$(running_application_pids)"})
        (( ${#application_pids} == 0 )) && return 0
        sleep 0.1
    done

    print "[StableMic] Принудительно завершаю зависшие экземпляры: ${application_pids[*]}"
    kill -KILL "${application_pids[@]}" 2>/dev/null || true

    for _ in {1..20}; do
        application_pids=(${(f)"$(running_application_pids)"})
        (( ${#application_pids} == 0 )) && return 0
        sleep 0.1
    done

    print -u2 '[StableMic] Не удалось завершить старое приложение. Новый экземпляр не запущен.'
    return 1
}

build_and_restart() {
    print '\n[StableMic] Собираю приложение…'

    if ! xcodebuild \
        -project "$project_file" \
        -scheme "$application_name" \
        -configuration Debug \
        -destination 'platform=macOS' \
        -derivedDataPath "$derived_data_directory" \
        CODE_SIGNING_ALLOWED=NO \
        -quiet \
        build; then
        print -u2 '[StableMic] Ошибка сборки. Исправьте её — watcher продолжает работать.'
        return 1
    fi

    stop_running_applications || return 1

    open -n "$application_path"
    print '[StableMic] Готово. Ожидаю изменений…'
}

handle_signal() {
    print '\n[StableMic] Live reload остановлен.'
    exit 0
}

trap release_watcher_lock EXIT
trap handle_signal INT TERM

acquire_watcher_lock
last_fingerprint="$(source_fingerprint)"
build_and_restart || true

while true; do
    sleep 0.7
    current_fingerprint="$(source_fingerprint)"

    if [[ "$current_fingerprint" != "$last_fingerprint" ]]; then
        # Даём редактору закончить серию быстрых операций записи.
        sleep 0.3
        last_fingerprint="$(source_fingerprint)"
        build_and_restart || true
    fi
done
