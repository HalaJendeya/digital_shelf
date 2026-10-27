// Generates the Digital Shelf launcher icon artwork from the design-system
// palette: books on a shelf over coffee brown.
//
//   dart run tool/generate_icon.dart && dart run flutter_launcher_icons
//
// Outputs (1024×1024):
//   assets/icon/app_icon.png             full icon (iOS, legacy Android)
//   assets/icon/app_icon_foreground.png  transparent foreground for Android adaptive icons
import 'dart:io';

import 'package:image/image.dart' as img;

const _size = 1024;
const _ss = 2; // supersampling factor for smooth edges

// Mirrors lib/design_system/tokens/app_colors.dart (AppPalette).
final _coffee = img.ColorRgba8(0x6F, 0x4E, 0x37, 255);
final _latte = img.ColorRgba8(0xD9, 0xB0, 0x8C, 255);
final _cream = img.ColorRgba8(0xEB, 0xD9, 0xC6, 255);
final _rust = img.ColorRgba8(0xB5, 0x65, 0x1D, 255);
final _gold = img.ColorRgba8(0xE0, 0xC3, 0x6E, 255);
final _sage = img.ColorRgba8(0xA9, 0xC4, 0x7A, 255);
final _pumpkin = img.ColorRgba8(0xF0, 0xA8, 0x68, 255);

img.ColorRgba8 _shade(img.ColorRgba8 c, double f) =>
    img.ColorRgba8((c.r * f).round(), (c.g * f).round(), (c.b * f).round(), 255);

/// Draws the shelf scene. Coordinates are in a 1024 design grid; [scale]
/// grows the artwork around the centre (adaptive icons need a smaller safe zone).
void _drawScene(img.Image canvas, double scale) {
  const cx = _size / 2, cy = _size / 2 + 20;
  int p(num v, num centre) => ((centre + (v - centre) * scale) * _ss).round();

  void rect(num x1, num y1, num x2, num y2, img.Color color, {num radius = 0}) => img.fillRect(
    canvas,
    x1: p(x1, cx),
    y1: p(y1, cy),
    x2: p(x2, cx),
    y2: p(y2, cy),
    color: color,
    radius: radius * scale * _ss,
  );

  void book(num x1, num top, num x2, img.ColorRgba8 color) {
    const bottom = 700;
    final band = _shade(color, 0.78);
    final h = bottom - top;
    rect(x1, top, x2, bottom, color, radius: 10);
    rect(x1, top + h * 0.14, x2, top + h * 0.14 + 16, band);
    rect(x1, bottom - h * 0.14 - 16, x2, bottom - h * 0.14, band);
    // Title label on the spine.
    final inset = (x2 - x1) * 0.22;
    rect(x1 + inset, top + h * 0.38, x2 - inset, top + h * 0.54, band, radius: 6);
  }

  book(262, 330, 362, _cream);
  book(374, 270, 474, _rust);
  book(486, 360, 566, _gold);
  book(578, 300, 680, _sage);

  // A book leaning against the row.
  final lean = _pumpkin;
  img.fillPolygon(
    canvas,
    vertices: [
      img.Point(p(690, cx), p(700, cy)),
      img.Point(p(770, cx), p(700, cy)),
      img.Point(p(800 - 98, cx), p(352, cy)),
      img.Point(p(800 - 178, cx), p(352 + 18, cy)),
    ],
    color: lean,
  );

  // Shelf plank with a darker lip.
  rect(214, 700, 810, 752, _latte, radius: 14);
  rect(214, 736, 810, 752, _shade(_latte, 0.82), radius: 8);
}

img.Image _render({required bool withBackground, required double scale}) {
  final canvas = img.Image(width: _size * _ss, height: _size * _ss, numChannels: 4);
  // Transparent pixels carry the background RGB so downsampled edges blend
  // into brown rather than leaving a dark fringe.
  img.fill(
    canvas,
    color: withBackground ? _coffee : img.ColorRgba8(_coffee.r.toInt(), _coffee.g.toInt(), _coffee.b.toInt(), 0),
  );
  _drawScene(canvas, scale);
  return img.copyResize(canvas, width: _size, height: _size, interpolation: img.Interpolation.average);
}

void main() {
  Directory('assets/icon').createSync(recursive: true);
  File('assets/icon/app_icon.png').writeAsBytesSync(img.encodePng(_render(withBackground: true, scale: 1.18)));
  // Adaptive foreground: launchers crop to the inner ~66%, so keep art smaller.
  File(
    'assets/icon/app_icon_foreground.png',
  ).writeAsBytesSync(img.encodePng(_render(withBackground: false, scale: 0.86)));
  stdout.writeln('Wrote assets/icon/app_icon.png and assets/icon/app_icon_foreground.png');
}
