# FloatingBasket

**A lightweight macOS drag-and-drop basket for capturing, converting,
and exporting files without interrupting your workflow.**

FloatingBasket lives in the menu bar and summons a small floating drop
target while you drag. Drop a file, image, or text into the basket to
open its available export options, then drag an output format into
another app or Finder.

> FloatingBasket is an independent project and is not affiliated with
> Apple.

## Features

-   **Summon while dragging:** shake a supported drag left and right, or
    drag into the top-center pin zone.
-   **Drop to open:** the summoned window starts as an intake target.
    Dropping an item into it opens the item's format window.
-   **Drag outputs anywhere:** drag a format icon into Finder or another
    compatible app.
-   **Keep the original:** when the source file is known, the basket can
    offer an Original option alongside conversions.
-   **Text and code capture:** supports common text and source-code file
    extensions.
-   **Image conversion:** supports image payloads and exports PNG or
    JPEG.
-   **Menu-bar utility:** use **Paste from Clipboard** to capture
    clipboard contents explicitly.
-   **Floating panels:** panels are positioned near the pointer and kept
    within the visible screen area.
-   **No paid Apple Developer Program membership required for local
    builds.**

## How it works

1.  Start dragging a file, image, or text from another app.
2.  Summon the empty intake basket by shaking the drag or entering the
    top-center pin zone.
3.  Drop the item onto the basket.
4.  The basket opens a compact window showing available output formats.
5.  Drag the desired format into Finder or another app. Choose
    **Original** to export the source file when available.

You can also choose **Paste from Clipboard** in the menu-bar menu.
Clipboard capture is separate from drag-and-drop intake.

## Supported content and formats

Available options depend on the payload and converters registered in the
current version.

  -----------------------------------------------------------------------
  Input                               Behavior / available outputs
  ----------------------------------- -----------------------------------
  Text and source code                Can export Markdown (`.md`), plain
                                      text (`.txt`), and Word (`.docx`)
                                      where supported

  Images                              Can export PNG (`.png`) and JPEG
                                      (`.jpg`)

  DOCX files                          Extracts document text for
                                      conversion and can retain access to
                                      the original file

  RTF files                           Extracts rich-text content for
                                      conversion and can retain access to
                                      the original file

  Other files                         Preserved as file payloads;
                                      available actions depend on
                                      registered converters
  -----------------------------------------------------------------------

Common text extensions include `.txt`, `.md`, `.html`, `.xml`, `.json`,
`.yaml`, `.csv`, `.py`, `.swift`, `.js`, `.ts`, `.c`, `.cpp`, `.java`,
`.go`, `.rs`, `.rb`, `.sh`, `.sql`, and `.css`.

**Note:** support depends on the current implementation; not every file
type can necessarily be converted. Drag-and-drop compatibility can also
vary by source app.

## Installation

### Download pre-compiled binary

1.  Open this repo and navigate to the releases page
2.  Download the dmg latest release file
3.  Open the dmg it and move `FloatingBasket.app` to Applications or another
    location.
4.  Open the app. 
    
5. If macOS warns that it cannot verify the developer, you can click settings -> privacy and security -> floating basket -> run anyways to bypass. Only bypass the warning if
    you trust me (hopefully yes)

### Build from source

#### Requirements
-   A Mac running a macOS version supported by your installed Xcode.
-   Xcode for the local build route.
-   The repository's Xcode project and source files.

You do **not** need a paid Apple Developer Program membership to build
and run locally. Paid membership is generally relevant to distribution
workflows such as Developer ID signing and notarization, not ordinary
local development.

#### Procedure

1.  Clone or download the repository.
2.  Open the `.xcodeproj` in Xcode. If the repository uses an
    `.xcworkspace`, open the workspace instead.
3.  Select the **FloatingBasket** app target and your Mac as the run
    destination.
4.  Choose **Product → Build** (`⌘B`).
5.  Choose **Product → Run** (`⌘R`).

If Xcode asks about signing, configure signing for local development.
You do not need paid Developer Program enrollment just to build locally;
exact signing options depend on the project settings and Xcode version.



## Using the menu-bar app

-   Click the basket icon in the menu bar.
-   Choose **Paste from Clipboard** to create windows from clipboard
    content.
-   Choose **Quit** to exit FloatingBasket.


## Troubleshooting

### The app will not open after downloading a release

See above. Click settings -> privacy and security -> floating basket -> run anyways to bypass. Only bypass if you trust me (hopefully yes).

### Dragging from a particular app does not summon the basket

Drag-and-drop implementations vary between applications. Try shaking the
drag or entering the top-center pin zone, then drop the item directly
into the intake window. If one source app consistently fails, report the
app, item type, and observed behavior.

## Development notes

FloatingBasket uses **SwiftUI** for its interface and **AppKit** for
macOS-specific panels, pasteboard, and drag-and-drop behavior.

Key components include:

-   `FloatingBasketApp.swift` --- app lifecycle, menu-bar commands, and
    floating-window creation.
-   `BasketPanel.swift` --- floating panel, intake UI, drag-and-drop
    ingestion, and format export UI.
-   `MouseShakeDetector.swift` --- shake gesture and top-center pin-zone
    trigger.
-   `IngestionService.swift` --- clipboard ingestion.
-   `ExportManager.swift` and converter implementations --- selecting
    and generating output formats.

File names and responsibilities may change as the project evolves.
