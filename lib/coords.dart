class Coords
{
  int c;
  int r;

  Coords( this.c, this.r );

  bool equals( Coords there )
  { return there.c==c && there.r==r;
  }
}