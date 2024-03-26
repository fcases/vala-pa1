using nsGTK;
using nsPA;

pub fn main() anyerror!void {
    const myPA = pa.Init();
    defer myPA.Terminate();
    if (myPA.err != 0) return;

    var myGtk = gtk.Init(myPA);
    if (myGtk.err != null) return;
    myGtk.RunMain();
}

void main () {
    print ("hello, world\n");
}