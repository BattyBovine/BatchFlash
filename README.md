BatchFlash
==========

BatchFlash is a program for quickly and easily rendering SWF files to high-resolution image sequences. It's currently riddled with issues, but it's certainly useable.

Features:
- Easily drag and drop SWF files into the program and render each one to a high-resolution image sequence with a single click.
- Render settings that allow for various common resolution settings, as well as manual resolutions, plus the ability to scale or crop the image to fit new aspect ratios.
- Preview how the output will look by scrubbing through your SWF files to view a sample render.

Known Issues:
- The interface is REALLY REALLY SLOW when rendering. This will be addressed in the future by using pseudo-threads or, on the off-chance that Adobe ever actually implements the proper multi-threading they've been promising for about two years now, by using actual processing threads.
- Letterbox aspect correction does not currently work properly.
- "Virtual cameras" are not supported, and likely never will be.
- Movie clip filters may render strangely when up- or down-scaling an SWF file. This is a limitation of how the Flash player renders filters, and there is no easy fix. Nevertheless, the issue will be looked at in the future.
- The application looks a little boring. This is due to a limitation in my ability to care about designing a skin right now.