# VP8L (WebP lossless) encoder

The program loads an image (in any of the widely supported formats such as JPEG,
PNG or BMP) and encodes it in the WebP lossless format (VP8L codec). The program
uses most of the features of the VP8L format to achieve better compression than
PNG and is not much worse than the official `libwebp` implementation. However,
the program is quite slow compared to the heavily optimized image compression
libraries currently in use, but this is mostly due to the focus on clarity
rather than on performance.

The implemented VP8L features include:

- entropy coding of image data using canonical Huffman codes
- LZ77 backward references
- local color cache references (currently disabled, as it does not improve
  compression)
- palettization, possibly using sub-byte packing
- subtract-green color transform to crudely decorrelate color channels
- spatially-varying prediction

The notable features that are *not* implemented are:

- spatially-varying Huffman codes
- advanced cross-color transform

The encoded images are usually 65%--90% size of PNG and 110%--160% the size of
lossless WebP images produced by `libwebp`.

## Usage

Compile all the C# files in the `VP8L/` directory and add a reference to
`System.Drawing` to get an executable `VP8L.exe`. A `Makefile` is attached that
invokes `mcs` that will do the trick. The executable can be invoked with two
command-line arguments, as

    VP8L.exe [input] [output]

where `[input]` is the path to the input image and `[output]` is the name of the
produced `.webp` file. The default paths are `input.png` and `output.webp`.

## Test images

The distribution includes a small corpus of images in `test/input`, used to test
the program. The included script `test.sh` invokes the program and stores the
generated images in `test/output`. It also converts the images into WebP using
`cwebp`, the tool shipped with `libwebp`, and saves them to `test/ref` for
comparison. To check that the output images are valid, the script converts them
back to PNG using `dwebp`, which also serves as a check that the produced WebP
images are valid.

Note that the script expects to find the `dwebp` and `cwebp` binaries in the
`test/` directory and executes the program using `mono VP8L.exe`.

## Source guide

The `Main` is located in `VP8L/VP8L.cs`, other source files are mostly named
after the main `class` they contain (`Argb.cs`, `Image.cs`, ...) or the `static
class` that must be used to wrap functions (`Transform.cs`, `ImageData.cs`,
...). Read the comments to gain basic understanding of the inner workings.
