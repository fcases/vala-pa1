using GTK;
using PA;

void main (string[] args) {
    PA.PA myPA = new PA.PA();
    if (myPA.err != 0) return;

    GTK.GTK myGTK=new GTK.GTK(args,myPA);
    if (myGTK.err != 0) return;

    myGTK.RunMain();
}