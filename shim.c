// SHIM for forth to create window 

#include "framework.h"
#include <windows.h>
#include <stdlib.h>
#include <string>
#include <tchar.h>

#define USE_IMPORT_EXPORT
#define USE_WINDOWS_DLL_SEMANTICS

#pragma comment(lib, "kernel32.lib")
#pragma comment(lib, "user32.lib")

extern "C" {

	// FORTH call back
	WNDPROC call_forth = nullptr;

	LRESULT CALLBACK MainWndProc(
		HWND hwnd,        // handle to window
		UINT uMsg,        // message identifier
		WPARAM wParam,    // first message parameter
		LPARAM lParam)    // second message parameter
	{
		int forth_response = call_forth(hwnd, uMsg, wParam, lParam);
		if (forth_response == 4444) {
			return 0; // handled by FORTH
		}
		return DefWindowProc(hwnd, uMsg, wParam, lParam);
	}



	__declspec(dllexport) HANDLE make_window(WNDPROC cb, int x, int y, int w, int h) {

		auto hInst = GetModuleHandle(NULL);

		call_forth = cb;

		SetProcessDpiAwarenessContext(DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2);

		WNDCLASSEX window_class;
		window_class.cbSize = sizeof(WNDCLASSEX);
		window_class.style = CS_HREDRAW | CS_VREDRAW;
		window_class.lpfnWndProc = (WNDPROC)MainWndProc;
		window_class.cbClsExtra = 0;
		window_class.cbWndExtra = 0;
		window_class.hInstance = hInst;
		window_class.hIcon = LoadIcon(hInst, IDI_ASTERISK);
		window_class.hCursor = LoadCursor(nullptr, IDC_ARROW);
		window_class.hbrBackground = reinterpret_cast<HBRUSH>(COLOR_WINDOW + 1);
		window_class.lpszMenuName = nullptr;
		window_class.lpszClassName = L"win_shim";
		window_class.hIconSm = NULL;

		if (!RegisterClassEx(&window_class))
		{
			MessageBox(nullptr,
				_T("Call to RegisterClassEx failed "),
				_T("Window failed"),
				NULL);

			return nullptr;
		}

		HWND hWnd = CreateWindowEx(
			NULL,
			L"win_shim",
			L"Change me later",
			WS_OVERLAPPEDWINDOW,
			x, y,
			w,
			h,
			NULL,
			NULL,
			hInst,
			NULL
		);

		if (!hWnd)
		{
			MessageBox(nullptr,
				_T("Call to CreateWindow failed!"),
				_T("windows shim"),
				NULL);

			return NULL;
		}
		return hWnd;
	}
}

BOOL APIENTRY DllMain(HMODULE hModule,
	DWORD  ul_reason_for_call,
	LPVOID lpReserved
)
{
	switch (ul_reason_for_call)
	{
	case DLL_PROCESS_ATTACH:
	case DLL_THREAD_ATTACH:
	case DLL_THREAD_DETACH:
	case DLL_PROCESS_DETACH:
		break;
	}
	return TRUE;
}

