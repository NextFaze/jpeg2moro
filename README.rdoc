
= JPEG2moro

https://github.com/2moro/jpeg2moro

== DESCRIPTION

JPEG2moro is a method of encoding arbitrary data (including an alpha channel) within the JPEG Application Segment APP10.

See SPEC.txt for the technical details.

== SYNOPSIS (ruby)

 # create a jpeg with transparency from a png file (creates image.jpg)
  > ruby/scripts/jpeg2moro source.png

  # specify alpha channel bit depth (1 bit) and output file output.jpg
  > ruby/scripts/jpeg2moro source.png -a 1 -o output.jpg

== SYNOPSIS (objective c)

  #import "JPEG2moro.h"

  ...
  JPEG2moro *jpg = [JPEG2moro imageNamed:@"output.jpg"];
  UIImage *img = [jpg image];

