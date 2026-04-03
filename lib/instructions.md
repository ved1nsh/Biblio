
# UI Responsiveness Instructions (`instruction.md`)

## Core Principle

All UI components, spacing, fonts, and assets **must** be responsive. We use the `flutter_screenutil` package to ensure the UI scales proportionally across different screen sizes (mobile, tablet, and foldable).

### 1. Initialization

The base design is typically drafted for a **360x690** or **375x812** artboard. Always wrap the app in `ScreenUtilInit`:

```dart
ScreenUtilInit(
  designSize: const Size(393, 852), 
  minTextAdapt: true,
  builder: (context, child) => MaterialApp(...),
)

```

---

### 2. Sizing Methodology

Do **not** use hardcoded `double` values for dimensions. Use the following extensions:

* **Width & Horizontal Spacing:** Use `.w` (e.g., `100.w`)
* **Height & Vertical Spacing:** Use `.h` (e.g., `50.h`)
* **Font Sizes:** Use `.sp` (e.g., `16.sp`). This allows for accessibility scaling.
* **Radius/Padding (Adaptable):** Use `.r` or `.ad` for uniform scaling of corners and padding.

| Feature | Standard Coding (Bad) | Responsive Coding (Good) |
| --- | --- | --- |
| **Width** | `width: 200` | `width: 200.w` |
| **Height** | `height: 50` | `height: 50.h` |
| **Font Size** | `fontSize: 18` | `fontSize: 18.sp` |
| **Padding** | `EdgeInsets.all(12)` | `EdgeInsets.all(12.r)` |

---

### 3. Images and Icons

To prevent images from overflowing or looking tiny on tablets:

1. Wrap images in a `SizedBox` or `Container` with `.w` and `.h` constraints.
2. Use `BoxFit.cover` or `BoxFit.contain` appropriately.
3. For Icons, always apply `.sp` or `.w` to the `size` property.

```dart
// Example
Image.asset(
  'assets/logo.png',
  width: 120.w,
  height: 120.h,
  fit: BoxFit.contain,
)

```

---

### 4. Layout Constraints

* **Avoid** `MediaQuery.of(context).size.width` for small components; it’s too blunt. Use `ScreenUtil` extensions for precision.
* **Spacing:** Use `SizedBox(height: 20.h)` instead of generic padding between vertical elements.
* **Adaptive Grids:** When using `GridView`, calculate the `childAspectRatio` based on responsive widths/heights to ensure items don't stretch weirdly.

---

### 5. Best Practices for the AI

* When generating new widgets, **always** check if a numeric value represents a screen dimension. If it does, suffix it with `.w`, `.h`, `.r`, or `.sp`.
* Prioritize `Flex`, `Expanded`, and `Flexible` for structural layouts, but use `ScreenUtil` for the specific sizing of the elements inside them.

