A little demo I made of scaling using different scaling algorithms in MonoGame.

Uses modified shader code from https://github.com/Blinue/Magpie, which is under GPL 3.0 license.

Usage:

Press F5

Use keys 1-4 to select the different scaling modes:

1: Bilinear (what SpriteBatch does by default)

2: Lanczos

3: FSR EASU pass (edge-adaptive Lanczos basically)

4: FSR - this is EASU + a sharpening pass.
