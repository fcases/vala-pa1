using myGTK;
using myPA;

void main (string[] args) {
    var pa = new myPA.myIfcPA();
    if (pa.err != 0) return;

    var myApp=new myGTK.myAppGTK(pa);
    if (myApp.err != 0) return;

    myApp.run(args);
}