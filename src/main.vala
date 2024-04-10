using myGTK;
<<<<<<< HEAD
using myPA;

void main (string[] args) {
    var pa = new myPA.myIfcPA();
    if (pa.err != 0) return;

    var myApp=new myGTK.myAppGTK(pa);
    if (myApp.err != 0) return;

    myApp.run(args);
=======
using PA;

void main (string[] args) {
    PA.PA pa = new PA.PA();
    if (pa.err != 0) return;

//    GTK.GTK myGTK=new GTK.GTK(args,pa);
    var app=new myAppGTK(pa);
    if (app.err != 0) return;

    app.run(args);
>>>>>>> 92965d9 (.)
}