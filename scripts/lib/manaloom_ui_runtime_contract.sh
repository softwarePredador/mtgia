#!/usr/bin/env bash

manaloom_web_runtime_device_contract() {
  local profile="$1"
  case "$profile" in
    web_mobile_390x844)
      printf '%s' \
        'Chrome real release build; Flutter surface requested at 390x844; device metrics DPR 1; symmetric near-white host margins cropped by the driver when present'
      ;;
    web_desktop_1440x900)
      printf '%s' \
        'Chrome real release build; Flutter surface requested at 1440x900; device metrics DPR 1; symmetric near-white host margins cropped by the driver when present'
      ;;
    web_wide_1920x1080)
      printf '%s' \
        'Chrome real release build; Flutter surface requested at 1920x1080; device metrics DPR 1; symmetric near-white host margins cropped by the driver when present'
      ;;
    web_battle_live_1440x900)
      printf '%s' \
        'Chrome real release build; Battle Live Flutter surface requested at 1440x900; device metrics DPR 1; symmetric near-white host margins cropped by the driver when present'
      ;;
    *)
      echo "Unsupported Web runtime profile: $profile" >&2
      return 2
      ;;
  esac
}

manaloom_android_runtime_device_contract() {
  local model="$1"
  local android_version="$2"
  local runtime_kind="$3"
  local serial="$4"
  local device_size="$5"
  local capture_posture="$6"
  local display_size="$device_size"
  display_size="${display_size#Physical size: }"
  display_size="${display_size#Override size: }"
  printf '%s' \
    "$model, Android $android_version, $runtime_kind runtime, serial $serial, display $display_size; capture posture: $capture_posture"
}
