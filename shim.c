
#include <windows.h>
#include <gdiplus.h>
#include <wingdi.h>
#include <memory>
#include <string.h>
#include <codecvt>
#include <locale>

using namespace Gdiplus;
#pragma comment (lib,"Gdiplus.lib")

#define ptr int
#define Strue -1
#define Snil 0
#define Sfalse 0

std::wstring widen(const std::string& in)
{
	int len = MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS,
		in.c_str(), in.size(), NULL, 0);
	if (len == 0)
	{
		throw std::runtime_error("Invalid character sequence.");
	}
	std::wstring out(len, 0);
	MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS,
		in.c_str(), in.size(), &out[0], out.size());
	return out;
}

// GLOBAL graphics
const wchar_t font_face[128] = L"Calibri";
int font_size = 8;
int font_Hinting = Gdiplus::TextRenderingHintAntiAliasGridFit;
__declspec(dllexport) Gdiplus::Bitmap* image_surface = nullptr;


Gdiplus::SolidBrush* solid_brush = nullptr;
Gdiplus::SolidBrush* paper_brush = nullptr;
Gdiplus::HatchBrush* hatch_brush = nullptr;
Gdiplus::LinearGradientBrush* gradient_brush = nullptr;
Gdiplus::Color foreground_colour;
Gdiplus::Matrix* transform_matrix = new Gdiplus::Matrix();
Gdiplus::SmoothingMode quality_mode = Gdiplus::SmoothingModeHighQuality;
Gdiplus::Region* ClipRegion;
float _pen_width = (float)1.2;
__declspec(dllexport) int _graphics_mode;

ULONG_PTR           gdiplusToken;

extern "C" __declspec(dllexport)  void gdiplus_init() {
	GdiplusStartupInput gdiplusStartupInput;
	GdiplusStartup(&gdiplusToken, &gdiplusStartupInput, NULL);
}

extern "C" __declspec(dllexport)  void* get_surface() {
	return image_surface;
}


extern "C" __declspec(dllexport) ptr QUALITYHIGH()
{
	quality_mode = Gdiplus::SmoothingModeHighQuality;
	return Strue;
}

extern "C" __declspec(dllexport) ptr QUALITYFAST()
{
	quality_mode = Gdiplus::SmoothingModeHighSpeed;
	return Strue;
}

extern "C" __declspec(dllexport) ptr QUALITYANTIALIAS()
{
	quality_mode = Gdiplus::SmoothingModeAntiAlias;
	return Strue;
}

extern "C" __declspec(dllexport) ptr MATRIXRESET()
{
	if (transform_matrix == nullptr)
	{
		transform_matrix = new Gdiplus::Matrix();
	}
	transform_matrix->Reset();
	return Strue;
}

extern "C" __declspec(dllexport) ptr MATRIXINVERT()
{
	if (transform_matrix == nullptr)
	{
		transform_matrix = new Gdiplus::Matrix();
	}
	transform_matrix->Invert();
	return Strue;
}

extern "C" __declspec(dllexport) ptr MATRIXROTATEAT(int x, int y, int angle)
{
	if (transform_matrix == nullptr)
	{
		transform_matrix = new Gdiplus::Matrix();
	}
	transform_matrix->RotateAt(angle, PointF(x, y));
	return Strue;
}

extern "C" __declspec(dllexport) ptr MATRIXROTATE(int angle)
{
	if (transform_matrix == nullptr)
	{
		transform_matrix = new Gdiplus::Matrix();
	}
	transform_matrix->Rotate(angle);
	return Strue;
}

extern "C" __declspec(dllexport) ptr MATRIXSHEAR(float x, float y)
{
	if (transform_matrix == nullptr)
	{
		transform_matrix = new Gdiplus::Matrix();
	}
	transform_matrix->Shear(x, y);
	return Strue;
}

extern "C" __declspec(dllexport) ptr MATRIXSCALE(float x, float y)
{
	if (transform_matrix == nullptr)
	{
		transform_matrix = new Gdiplus::Matrix();
	}
	transform_matrix->Scale(x, y);
	return Strue;
}

extern "C" __declspec(dllexport) ptr MATRIXTRANSLATE(float x, float y)
{
	if (transform_matrix == nullptr)
	{
		transform_matrix = new Gdiplus::Matrix();
	}
	transform_matrix->Translate(x, y);
	return Strue;
}

int GetEncoderClsid(WCHAR* format, CLSID* pClsid)
{
	unsigned int num = 0, size = 0;

	GetImageEncodersSize(&num, &size);
	if (size == 0) return -1;

	ImageCodecInfo* pImageCodecInfo = (ImageCodecInfo*)(malloc(size));
	if (pImageCodecInfo == NULL) return -1;

	GetImageEncoders(num, size, pImageCodecInfo);
	for (unsigned int j = 0; j < num; ++j)
	{
		if (wcscmp(pImageCodecInfo[j].MimeType, format) == 0) {
			*pClsid = pImageCodecInfo[j].Clsid;
			free(pImageCodecInfo);
			return j;
		}
	}
	free(pImageCodecInfo);
	return -1;
}

Gdiplus::Bitmap* ResizeClone(Bitmap* bmp, INT width, INT height)
{
	UINT o_height = bmp->GetHeight();
	UINT o_width = bmp->GetWidth();
	INT n_width = width;
	INT n_height = height;
	double ratio = ((double)o_width) / ((double)o_height);
	if (o_width > o_height) {
		// Resize down by width
		n_height = static_cast<UINT>(((double)n_width) / ratio);
	}
	else {
		n_width = static_cast<UINT>(n_height * ratio);
	}
	Gdiplus::Bitmap* newBitmap = new Gdiplus::Bitmap(n_width, n_height, bmp->GetPixelFormat());
	Gdiplus::Graphics graphics(newBitmap);
	graphics.DrawImage(bmp, 0, 0, n_width, n_height);
	return newBitmap;
}

Gdiplus::Status HBitmapToBitmap(HBITMAP source, Gdiplus::PixelFormat pixel_format, Gdiplus::Bitmap** result_out)
{
	BITMAP source_info = { 0 };
	if (!::GetObject(source, sizeof(source_info), &source_info))
		return Gdiplus::GenericError;

	Gdiplus::Status s;

	std::unique_ptr<Gdiplus::Bitmap>target(new Gdiplus::Bitmap(source_info.bmWidth, source_info.bmHeight, pixel_format));
	if (!target.get())
		return Gdiplus::OutOfMemory;
	if ((s = target->GetLastStatus()) != Gdiplus::Ok)
		return s;

	Gdiplus::BitmapData target_info;
	Gdiplus::Rect rect(0, 0, source_info.bmWidth, source_info.bmHeight);

	s = target->LockBits(&rect, Gdiplus::ImageLockModeWrite, pixel_format, &target_info);
	if (s != Gdiplus::Ok)
		return s;

	if (target_info.Stride != source_info.bmWidthBytes)
		return Gdiplus::InvalidParameter; // pixel_format is wrong! 

	CopyMemory(target_info.Scan0, source_info.bmBits, source_info.bmWidthBytes * source_info.bmHeight);

	s = target->UnlockBits(&target_info);
	if (s != Gdiplus::Ok)
		return s;

	*result_out = target.release();

	return Gdiplus::Ok;
}

extern "C" __declspec(dllexport) ptr DRAWSTRING(int x, int y, char* text)
{

	std::wstring draw_text = widen(text);
	if (image_surface == nullptr)
	{
		return Snil;
	}

	Graphics g2(image_surface);
	g2.SetClip(ClipRegion, CombineModeReplace);
	g2.SetSmoothingMode(quality_mode);
	g2.SetTransform(transform_matrix);
	g2.SetTextRenderingHint((Gdiplus::TextRenderingHint)font_Hinting);
	PointF origin(x, y);
	Font font(font_face, font_size);
	g2.DrawString(draw_text.data(), draw_text.length(), &font, origin, 0, solid_brush);

	return Strue;
}

extern "C" __declspec(dllexport) ptr DRAWGRADIENTSTRING(int x, int y, char* text)
{

	std::wstring draw_text = widen(text);
	if (image_surface == nullptr)
	{
		return Snil;
	}

	Graphics g2(image_surface);
	g2.SetClip(ClipRegion, CombineModeReplace);
	g2.SetSmoothingMode(quality_mode);
	g2.SetTransform(transform_matrix);
	g2.SetTextRenderingHint((Gdiplus::TextRenderingHint)font_Hinting);
	PointF origin(x, y);
	Font font(font_face, font_size);
	g2.DrawString(draw_text.data(), draw_text.length(), &font, origin, 0, gradient_brush);

	return Strue;
}

extern "C" __declspec(dllexport) ptr SAVEASPNG(char* fname)
{

	std::wstring file_name = widen(fname);
	ULONG uQuality = 100;
	CLSID imageCLSID;
	GetEncoderClsid((WCHAR*)L"image/png", &imageCLSID);
	HRESULT hrRet = image_surface->Save(file_name.data(), &imageCLSID, NULL) == 0 ? S_OK : E_FAIL;
	if (hrRet != S_OK)
	{
		return Sfalse;
	}

	return Strue;
}

extern "C" __declspec(dllexport) ptr SAVEASJPEG(char* fname)
{

	std::wstring file_name = widen(fname);
	ULONG uQuality = 100;
	CLSID imageCLSID;
	EncoderParameters encoderParams;
	encoderParams.Count = 1;
	encoderParams.Parameter[0].NumberOfValues = 1;
	encoderParams.Parameter[0].Guid = EncoderQuality;
	encoderParams.Parameter[0].Type = EncoderParameterValueTypeLong;
	encoderParams.Parameter[0].Value = &uQuality;
	GetEncoderClsid((WCHAR*)L"image/jpeg", &imageCLSID);
	HRESULT hrRet = image_surface->Save(file_name.data(), &imageCLSID, &encoderParams) == 0 ? S_OK : E_FAIL;
	if (hrRet != S_OK)
	{
		return Sfalse;
	}
	return Strue;
}

extern "C" __declspec(dllexport) ptr SAVETOCLIPBOARD(char* fname)
{

	if (!OpenClipboard(NULL))
	{
		return Snil;
	}

	if (!EmptyClipboard())
	{
		return Snil;
	}

	Color color(255, 0, 0, 0);
	HBITMAP hBitmap = NULL;
	image_surface->GetHBITMAP(color, &hBitmap);

	DIBSECTION ds;
	GetObject(hBitmap, sizeof(ds), &ds);
	ds.dsBmih.biCompression = BI_RGB;
	HDC hDC = GetDC(NULL);
	HBITMAP hDDB = CreateDIBitmap(hDC, &ds.dsBmih, CBM_INIT, ds.dsBm.bmBits, (BITMAPINFO*)&ds.dsBmih, DIB_RGB_COLORS);
	ReleaseDC(NULL, hDC);

	// Put data on the clipboard!
	if (!SetClipboardData(CF_BITMAP, hDDB))
	{
		DeleteObject(hBitmap);
		CloseClipboard();
		return Strue;
	}
	DeleteObject(hBitmap);
	CloseClipboard();
	return Snil;
}

extern "C" __declspec(dllexport) ptr FLIP(int d)
{
	if (image_surface == nullptr)
	{
		return Snil;
	}
	image_surface->RotateFlip(static_cast<Gdiplus::RotateFlipType>(d));
	return Strue;
}

extern "C" __declspec(dllexport) ptr SETPIXEL(int x, int y)
{
	if (image_surface == nullptr)
	{
		return Snil;
	}
	image_surface->SetPixel(x, y, foreground_colour);
	return Strue;
}

extern "C" __declspec(dllexport) ptr DISPLAY(int x, int y, HDC h )
{
	if (image_surface == nullptr)
	{
		return Snil;
	}
	Graphics g(h);
	g.DrawImage(image_surface, x, y);
	return Strue;
}

extern "C" __declspec(dllexport) ptr IMAGETOSURFACE(int x, int y, Image* image)
{
	if (image_surface == nullptr)
	{
		return Snil;
	}
	Graphics g(image_surface);
	g.DrawImage(image, x, y);
	return Strue;
}


extern "C" __declspec(dllexport) ptr LOADTOSURFACE(int x, int y, char* filename)
{
	if (image_surface == nullptr)
	{
		return Snil;
	}
	Image image(widen(filename).c_str());
	Graphics g2(image_surface);
	g2.DrawImage(&image, x, y);
	return Strue;
}

extern "C" __declspec(dllexport) ptr RSETPIXEL(REAL x, REAL y)
{
	if (image_surface == nullptr)
	{
		return Snil;
	}
	image_surface->SetPixel(x, y, foreground_colour);
	return Strue;
}

extern "C" __declspec(dllexport) ptr FILLSOLIDRECT(int x, int y, int w, int h)
{
	if (image_surface == nullptr)
	{
		return Snil;
	}
	if (solid_brush == nullptr)
	{
		solid_brush = new Gdiplus::SolidBrush(Gdiplus::Color(255, 0, 0, 0));
	}
	Gdiplus::Pen pen(foreground_colour, _pen_width);
	Graphics g2(image_surface);
	g2.SetClip(ClipRegion, CombineModeReplace);
	g2.SetSmoothingMode(quality_mode);
	g2.SetTransform(transform_matrix);
	g2.FillRectangle(solid_brush, x, y, w, h);
	return Strue;
}

extern "C" __declspec(dllexport) ptr REALFILLSOLIDRECT(REAL x, REAL y, REAL w, REAL h)
{
	if (image_surface == nullptr)
	{
		return Snil;
	}
	if (solid_brush == nullptr)
	{
		solid_brush = new Gdiplus::SolidBrush(Gdiplus::Color(255, 0, 0, 0));
	}
	Gdiplus::Pen pen(foreground_colour, _pen_width);
	Graphics g2(image_surface);
	g2.SetClip(ClipRegion, CombineModeReplace);
	g2.SetSmoothingMode(quality_mode);
	g2.SetTransform(transform_matrix);
	g2.FillRectangle(solid_brush, x, y, w, h);
	return Strue;
}

extern "C" __declspec(dllexport) ptr FILLGRADIENTRECT(int x, int y, int w, int h)
{
	if (image_surface == nullptr)
	{
		return Snil;
	}
	if (gradient_brush == nullptr)
	{
		return Snil;
	}
	Gdiplus::Pen pen(foreground_colour, _pen_width);
	Graphics g2(image_surface);
	g2.SetClip(ClipRegion, CombineModeReplace);
	g2.SetSmoothingMode(quality_mode);
	g2.SetTransform(transform_matrix);
	g2.FillRectangle(gradient_brush, x, y, w, h);
	return Strue;
}

extern "C" __declspec(dllexport) ptr FILLHATCHRECT(int x, int y, int w, int h)
{
	if (image_surface == nullptr)
	{
		return Snil;
	}
	if (hatch_brush == nullptr)
	{
		return Snil;
	}
	Gdiplus::Pen pen(foreground_colour, _pen_width);
	Graphics g2(image_surface);
	g2.SetClip(ClipRegion, CombineModeReplace);
	g2.SetSmoothingMode(quality_mode);
	g2.SetTransform(transform_matrix);
	g2.FillRectangle(hatch_brush, x, y, w, h);
	return Strue;
}

extern "C" __declspec(dllexport) ptr FILLSOLIDELLIPSE(int x, int y, int w, int h)
{
	if (image_surface == nullptr)
	{
		return Snil;
	}
	if (solid_brush == nullptr)
	{
		solid_brush = new Gdiplus::SolidBrush(Gdiplus::Color(255, 0, 0, 0));
	}
	Gdiplus::Pen pen(foreground_colour, _pen_width);
	Graphics g2(image_surface);
	g2.SetClip(ClipRegion, CombineModeReplace);
	g2.SetSmoothingMode(quality_mode);
	g2.SetTransform(transform_matrix);
	g2.FillEllipse(solid_brush, x, y, w, h);
	return Strue;
}

extern "C" __declspec(dllexport) ptr FILLGRADIENTELLIPSE(int x, int y, int w, int h)
{
	if (image_surface == nullptr)
	{
		return Snil;
	}
	if (gradient_brush == nullptr)
	{
		return Snil;
	}
	Gdiplus::Pen pen(foreground_colour, _pen_width);
	Graphics g2(image_surface);
	g2.SetClip(ClipRegion, CombineModeReplace);
	g2.SetSmoothingMode(quality_mode);
	g2.SetTransform(transform_matrix);
	g2.FillEllipse(gradient_brush, x, y, w, h);
	return Strue;
}

extern "C" __declspec(dllexport) ptr FILLHATCHELLIPSE(int x, int y, int w, int h)
{
	if (image_surface == nullptr)
	{
		return Snil;
	}
	if (hatch_brush == nullptr)
	{
		return Snil;
	}
	Gdiplus::Pen pen(foreground_colour, _pen_width);
	Graphics g2(image_surface);
	g2.SetClip(ClipRegion, CombineModeReplace);
	g2.SetSmoothingMode(quality_mode);
	g2.SetTransform(transform_matrix);
	g2.FillEllipse(hatch_brush, x, y, w, h);
	return Strue;
}

extern "C" __declspec(dllexport) ptr FILLSOLIDPIE(int x, int y, int w, int h, int i, int j)
{
	if (image_surface == nullptr)
	{
		return Snil;
	}
	if (solid_brush == nullptr)
	{
		solid_brush = new Gdiplus::SolidBrush(Gdiplus::Color(255, 0, 0, 0));
	}
	Gdiplus::Pen pen(foreground_colour, _pen_width);
	Graphics g2(image_surface);
	g2.SetClip(ClipRegion, CombineModeReplace);
	g2.SetSmoothingMode(quality_mode);
	g2.SetTransform(transform_matrix);
	g2.FillPie(solid_brush, x, y, w, h, i, j);
	return Strue;
}

extern "C" __declspec(dllexport) ptr FILLGRADIENTPIE(int x, int y, int w, int h, int i, int j)
{
	if (image_surface == nullptr)
	{
		return Snil;
	}
	if (gradient_brush == nullptr)
	{
		return Snil;
	}
	Gdiplus::Pen pen(foreground_colour, _pen_width);
	Graphics g2(image_surface);
	g2.SetClip(ClipRegion, CombineModeReplace);
	g2.SetSmoothingMode(quality_mode);
	g2.SetTransform(transform_matrix);
	g2.FillPie(gradient_brush, x, y, w, h, i, j);
	return Strue;
}

extern "C" __declspec(dllexport) ptr FILLHATCHPIE(int x, int y, int w, int h, int i, int j)
{
	if (image_surface == nullptr)
	{
		return Snil;
	}
	if (hatch_brush == nullptr)
	{
		return Snil;
	}
	Gdiplus::Pen pen(foreground_colour, _pen_width);
	Graphics g2(image_surface);
	g2.SetClip(ClipRegion, CombineModeReplace);
	g2.SetSmoothingMode(quality_mode);
	g2.SetTransform(transform_matrix);
	g2.FillPie(hatch_brush, x, y, w, h, i, j);
	return Strue;
}
extern "C" __declspec(dllexport) ptr DRAWRECT(int x, int y, int w, int h)
{
	if (image_surface == nullptr)
	{
		return Snil;
	}
	Gdiplus::Pen pen(foreground_colour, _pen_width);
	Graphics g2(image_surface);
	g2.SetClip(ClipRegion, CombineModeReplace);
	g2.SetSmoothingMode(quality_mode);
	g2.SetTransform(transform_matrix);
	g2.DrawRectangle(&pen, x, y, w, h);
	return Strue;
}

extern "C" __declspec(dllexport) ptr DRAWARC(int x, int y, int w, int h, int i, int j)
{
	if (image_surface == nullptr)
	{
		return Snil;
	}
	Gdiplus::Pen pen(foreground_colour, _pen_width);
	Graphics g2(image_surface);
	g2.SetClip(ClipRegion, CombineModeReplace);
	g2.SetSmoothingMode(quality_mode);
	g2.SetTransform(transform_matrix);
	g2.DrawArc(&pen, x, y, w, h, i, j);
	return Strue;
}

extern "C" __declspec(dllexport) ptr DRAWELLIPSE(int x, int y, int w, int h)
{
	if (image_surface == nullptr)
	{
		return Snil;
	}
	Gdiplus::Pen pen(foreground_colour, _pen_width);
	Graphics g2(image_surface);
	g2.SetClip(ClipRegion, CombineModeReplace);
	g2.SetSmoothingMode(quality_mode);
	g2.SetTransform(transform_matrix);
	g2.DrawEllipse(&pen, x, y, w, h);
	return Strue;
}

extern "C" __declspec(dllexport) ptr DRAWPIE(int x, int y, int w, int h, int i, int j)
{
	if (image_surface == nullptr)
	{
		return Snil;
	}
	Gdiplus::Pen pen(foreground_colour, _pen_width);
	Graphics g2(image_surface);
	g2.SetClip(ClipRegion, CombineModeReplace);
	g2.SetSmoothingMode(quality_mode);
	g2.SetTransform(transform_matrix);
	g2.DrawPie(&pen, x, y, w, h, i, j);
	return Strue;
}

extern "C" __declspec(dllexport) ptr DRAWLINE(int x, int y, int x0, int y0)
{
	if (image_surface == nullptr)
	{
		return Snil;
	}
	Gdiplus::Pen pen(foreground_colour, _pen_width);
	Graphics g2(image_surface);
	g2.SetClip(ClipRegion, CombineModeReplace);
	g2.SetSmoothingMode(quality_mode);
	g2.SetTransform(transform_matrix);
	g2.DrawLine(&pen, x, y, x0, y0);
	return Strue;
}

extern "C" __declspec(dllexport) ptr DRAWGRADIENTLINE(int x, int y, int x0, int y0)
{
	if (image_surface == nullptr)
	{
		return Snil;
	}
	Gdiplus::Pen pen(gradient_brush, _pen_width);
	Graphics g2(image_surface);
	g2.SetClip(ClipRegion, CombineModeReplace);
	g2.SetSmoothingMode(quality_mode);
	g2.SetTransform(transform_matrix);
	g2.DrawLine(&pen, x, y, x0, y0);
	return Strue;
}

extern "C" __declspec(dllexport) ptr PENWIDTH(float w)
{
	_pen_width = w;
	return Strue;
}

extern "C" __declspec(dllexport) ptr SETFONTSIZE(int w)
{
	font_size = w;
	return Strue;
}

extern "C" __declspec(dllexport) ptr COLR(int r, int g, int b, int a)
{
	foreground_colour = Gdiplus::Color(a, r, g, b);
	return Strue;
}

extern "C" __declspec(dllexport) ptr GRADIENTBRUSH(int x, int y, int w, int h, int r, int g, int b, int a, int r0, int g0, int b0, int a0, double angle, bool z)
{
	if (gradient_brush != nullptr)
	{
		delete gradient_brush;
	}
	gradient_brush = new Gdiplus::LinearGradientBrush(Gdiplus::Rect(x, y, w, h), Color(a, r, g, b), Color(a0, r0, g0, b0), angle, z);
	return Strue;
}

extern "C" __declspec(dllexport) ptr GRADIENTSHAPE(char* type, float focus, float scale)
{
	if (gradient_brush == nullptr)
	{
		return Snil;
	}
	if (strcmp(type, "bell") == 0)
	{
		gradient_brush->SetBlendBellShape(focus, scale);
	}
	else if (strcmp(type, "triangular") == 0)
	{
		gradient_brush->SetBlendTriangularShape(focus, scale);
	}
	else
	{
		return Snil;
	}
	return Strue;
}

extern "C" __declspec(dllexport) ptr SOLIDBRUSH(int r, int g, int b, int a)
{
	if (solid_brush != nullptr)
	{
		delete solid_brush;
	}
	solid_brush = new Gdiplus::SolidBrush(Gdiplus::Color(a, r, g, b));
	return Strue;
}

extern "C" __declspec(dllexport) ptr SETHATCHBRUSH(int style, int r, int g, int b, int a, int r0, int g0, int b0, int a0)
{
	if (hatch_brush != nullptr)
	{
		delete hatch_brush;
	}

	hatch_brush = new Gdiplus::HatchBrush(Gdiplus::HatchStyle(style), Gdiplus::Color(a, r, g, b), Color(a0, r0, g0, b0));
	return Strue;
}

extern "C" __declspec(dllexport) ptr PAPER(int r, int g, int b, int a)
{
	if (paper_brush != nullptr)
	{
		delete paper_brush;
	}
	paper_brush = new Gdiplus::SolidBrush(Gdiplus::Color(a, r, g, b));
	return Strue;
}

extern "C" __declspec(dllexport) ptr CLG(int w, int h)
{
	if (transform_matrix == nullptr)
	{
		transform_matrix = new Gdiplus::Matrix();
	}
	if (paper_brush == nullptr)
	{
		paper_brush = new Gdiplus::SolidBrush(Gdiplus::Color(255, 0, 0, 0));
	}
	if (image_surface != nullptr)
	{
		delete image_surface;
	}
	image_surface = new Gdiplus::Bitmap(w, h, PixelFormat32bppRGB);
	ClipRegion = new Gdiplus::Region(Gdiplus::Rect(0, 0, image_surface->GetWidth(), image_surface->GetHeight()));
	Gdiplus::Graphics g2(image_surface);
	g2.FillRectangle(paper_brush, 0, 0, w, h);
	return Strue;
}

extern "C" __declspec(dllexport) void* MAKESURFACE(int w, int h)
{
	auto new_surface = new Gdiplus::Bitmap(w, h, PixelFormat32bppRGB);
	Gdiplus::Graphics g2(image_surface);
	g2.FillRectangle(paper_brush, 0, 0, w, h);
	return(void*)image_surface;
}

extern "C" __declspec(dllexport) void* LOADIMAGE(char* filename)
{
	auto new_image = new Image(widen(filename).c_str());
	return new_image;
}


extern "C" __declspec(dllexport) ptr GRMODE(int m)
{
	_graphics_mode = m;
	return Strue;
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

