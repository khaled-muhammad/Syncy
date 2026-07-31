#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include <app_links/app_links_plugin_c_api.h>

#include "flutter_window.h"
#include "utils.h"

namespace {

// The Windows release is a portable ZIP rather than an MSIX installer, so it
// registers the syncy:// protocol for the current user when launched.
void RegisterSyncyProtocol() {
  wchar_t executable_path[MAX_PATH];
  const DWORD path_length =
      ::GetModuleFileNameW(nullptr, executable_path, MAX_PATH);
  if (path_length == 0 || path_length == MAX_PATH) {
    return;
  }

  HKEY protocol_key = nullptr;
  if (::RegCreateKeyExW(
          HKEY_CURRENT_USER, L"Software\\Classes\\syncy", 0, nullptr, 0,
          KEY_WRITE, nullptr, &protocol_key, nullptr) != ERROR_SUCCESS) {
    return;
  }

  const wchar_t description[] = L"URL:Syncy room invite";
  const wchar_t empty_value[] = L"";
  ::RegSetValueExW(
      protocol_key, nullptr, 0, REG_SZ,
      reinterpret_cast<const BYTE*>(description), sizeof(description));
  ::RegSetValueExW(
      protocol_key, L"URL Protocol", 0, REG_SZ,
      reinterpret_cast<const BYTE*>(empty_value), sizeof(empty_value));

  HKEY command_key = nullptr;
  if (::RegCreateKeyExW(
          protocol_key, L"shell\\open\\command", 0, nullptr, 0, KEY_WRITE,
          nullptr, &command_key, nullptr) == ERROR_SUCCESS) {
    const std::wstring command =
        L"\"" + std::wstring(executable_path, path_length) + L"\" \"%1\"";
    ::RegSetValueExW(
        command_key, nullptr, 0, REG_SZ,
        reinterpret_cast<const BYTE*>(command.c_str()),
        static_cast<DWORD>((command.size() + 1) * sizeof(wchar_t)));
    ::RegCloseKey(command_key);
  }

  ::RegCloseKey(protocol_key);
}

bool SendAppLinkToInstance(const std::wstring& title) {
  HWND window =
      ::FindWindowW(L"FLUTTER_RUNNER_WIN32_WINDOW", title.c_str());
  if (window == nullptr) {
    return false;
  }

  SendAppLink(window);

  if (::IsIconic(window)) {
    ::ShowWindow(window, SW_RESTORE);
  }
  ::SetForegroundWindow(window);
  return true;
}

}  // namespace

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  RegisterSyncyProtocol();

  // Forward an invite to an already-running Syncy instance instead of opening
  // a second player window.
  if (SendAppLinkToInstance(L"syncy")) {
    return EXIT_SUCCESS;
  }

  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(L"syncy", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
