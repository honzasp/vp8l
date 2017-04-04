# Internals of the VP8L encoder

The main function is `Format.Encode`, which encodes a raster image into a byte
stream using the VP8L codec wrapped in the WebP image format. The function
performs the following steps:

1. Analyze the image to determine the appropriate transforms to apply to the
   image.
2. Apply the palette transform.
3. Apply the subtract-green transform.
4. Apply the prediction transform.
5. Encode the image pixels.
6. Wrap the encoded bitstream in the WebP container.

Note that even though the transforms can be applied in any order (the only
restriction imposed by the specification is that no transform can be applied
twice), we use a fixed order, so that we only have to decide which transforms
shall be applied.

## Image analysis

The method of analysing the image is adopted from `libwebp`. The function to
analyze an image is called `Analysis.AnalyzeImage`. To estimate the benefits
from the various transforms, we compute histograms of the following quantities
(represented by the enum `Analysis.HistogramIdx`):

- the red, green, blue and alpha channels of the original image (`RED`, `GREEN`,
  `BLUE`, `ALPHA`)
- deltas in the red, green, blue and alpha channels (`DELTA_RED`, `DELTA_GREEN`,
  `DELTA_BLUE` and `DELTA_ALPHA`)
- the red channel minus green channel (`RED_MINUS_GREEN`)
- the blue channel minus green channel (`BLUE_MINUS_GREEN`)
- the deltas in the red-minus-green and blue-minus-green
  (`DELTA_RED_MINUS_DELTA_GREEN`, `DELTA_BLUE_MINUS_DELTA_GREEN`)
- indices of the palette entries (if a palette can be used) (`PALETTE`)

This allows us to estimate Shannon entropies of the various transform
combinations:

- No transform: entropy of `RED`, `GREEN`, `BLUE` and `ALPHA`
- palette: entropy of `PALETTE`
- subtract-green: entropy of `RED_MINUS_GREEN`, `GREEN`, `BLUE_MINUS_GREEN` and
  `ALPHA`
- prediction: entropy of `DELTA_RED`, `DELTA_GREEN`, `DELTA_BLUE` and
  `DELTA_ALPHA`
- subtract-green + preduction: entropy of `DELTA_RED_MINUS_DELTA_GREEN`,
  `DELTA_GREEN`, `DELTA_BLUE_MINUS_DELTA_GREEN`, `DELTA_ALPHA`.

We then simply select the combination that gives the least entropy. Note that
the entropies are only rough estimates of the actual number of bits needed to
encode the image, but these approximations seem to work well.

## Palette transform

The palette transform, implemented in `Transform.PaletteTransform`, simply
encodes the palette and replaces the pixels of the image by the palette indices.
Multiple indices can be packed in a byte if the palette is small (i.e. if the
indices fit into 4 bits, 2 indices are packed in a byte). No attempt is made to
optimize the order of the palette entries.

## Prediction transform

The prediction transform (`Transform.PredictTransform`) first determines the
resolution of the sub-sample image that encodes the prediction modes across the
image. For each tile of the image, we determine the best prediction mode, apply
it to the image and store it in the sub-sample image.

The best prediction mode for a tile is computed simply by applying all 14 modes
on the pixels and selecting the mode which minimizes the entropy (conditioned by
the entropies of the previous tiles). Note that we determine the prediction
modes in scan-line order, which may not be optimal, but seems to work well in
practice.

## Encoding the image pixels

The function `ImageData.WriteImageData` implements entropy-coding of image data.
The sub-sample images needed by the transforms are encoded in the same way as
the transformed image pixels, so this function is used in `Format.Encode` and in
the transforms.

The image data stream can contain three types of symbols:

- GRBA literals 
- backward references stored as a pair of length and distance
- indices into a color cache, which is an array that contains the recently-used
  colors indexed by a simple multiplicative hash.

The function `ImageData.EncodeImageData` encodes the pixels into a stream of
symbols as follows:

- If a suitable match (i.e., at least 3 matching pixels) is found, a backward
  reference is producted
- otherwise, if the pixel is found in the color cache, we reference the cache
- otherwise, the pixel must be encoded as a literal.

The backward references are stored and looked up in a simple chained hash table
(`ImageData.ChainTable`).

When the symbols are computed, we determine the Huffman codes for each alphabet
(using `Huffman.BuildCodes`) and encode the lengths of the codes in the bit
stream to allow the readers to reconstruct the codes used for encoding. The code
lengths themselves are encoded using a simple Huffman code, so that we must also
determine the code used to encode the code lengths and encode the code length
code lengths. This is accomplished by the function
`CodeLengths.WriteCodeLengths`.

Note that the format allows the use of multiple Huffman codes in case of the
main image data, but we do not use this feature.

## Testing

We test the correctness and quality of our implementation on a small corpus of
various images, stored in `test/input` in the repository. A simple script,
`test.sh`, encodes each image using our encoder and using `libwebp` and compares
the sizes of the files. It also attempts to decode the file produced by our
encoder using `libwebp` to ensure that the produced files are valid.
