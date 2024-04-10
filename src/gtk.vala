using Gtk;
using Cairo;
using Math;

<<<<<<< HEAD
using myPA;

namespace myGTK{

    //////////////////////////////////////
    //  class myAppGTK
    //////////////////////////////////////
    public class myAppGTK: Gtk.Application {
        // Control de la app
        public int err=0;
        static myAppGTK TheApp=null;
        public myPA.myIfcPA thePA;
        bool bThreadRunning = false;
        bool bEvKillThread = false;
        public Thread<uint> theThread;
        public ResetEvent miEvent= new ResetEvent();
    
        // UI
        const uint GTK_STYLE_PROVIDER_PRIORITY_USER=800;
        const uint GTK_STATE_NORMAL=0;
        Builder builder;
        Dialog window;
        Button butQuit;
        public Button butPlay;
        public Button butStop;
        public myDALed LedGo;
        public myDALed LedNoGo;
        myDAAudio drawFFT;
        myDAAudio drawRaw;
        public myCBTDecvices cbtIn;
        public myCBTDecvices cbtOut;

        
        public myAppGTK(myIfcPA *pa_ptr) {
            Object (application_id: "es.k6site.exampleGtkApp");
            if( TheApp==null ) TheApp=this;
            thePA=pa_ptr;
        }

        public static myAppGTK GetApp(){
            return TheApp;
        }

        protected override void activate() {
            // Builder from file
            builder=new Builder.from_file("./src/pa1.glade");

            // Direct Widgets
            window = (Dialog) builder.get_object("miWindow");
            butQuit = (Button) builder.get_object("miQuit");
            butPlay = (Button)builder.get_object("miPlay");
            butStop = (Button)builder.get_object("miStop");

            // Indirect Widgets
            LedGo=new myDALed((DrawingArea)builder.get_object("miLedOn"),GREEN,OFF);
            LedNoGo=new myDALed((DrawingArea)builder.get_object("miLedOff"),RED,ON);
            drawFFT= new myDAAudio((DrawingArea)builder.get_object("miLienzoFFT"),FFT);
            drawRaw= new myDAAudio((DrawingArea)builder.get_object("miLienzoRaw"),RAW);
            cbtIn = new myCBTDecvices((ComboBoxText)builder.get_object("miCBTIn"),IN);
            cbtOut = new myCBTDecvices((ComboBoxText)builder.get_object("miCBTOut"),OUT);

            // Direct Widgets signals (indirect Ws. have connect in their constructors)
            window.destroy.connect (this.Terminate);
            butQuit.clicked.connect(this.Terminate);
            butPlay.clicked.connect(this.butCbPlay);
            butStop.clicked.connect(this.butCbStop);
        
            //Other initializations
            Gdk.Color negro=  {0,0,0,0};
            window.modify_bg(GTK_STATE_NORMAL,negro);

            var myCssProvider= new CssProvider();
            myCssProvider.load_from_path("theme.css");
            StyleContext.add_provider_for_screen(Gdk.Screen.get_default(), (StyleProvider)myCssProvider, GTK_STYLE_PROVIDER_PRIORITY_USER);

            butPlay.set_sensitive(false);
            add_window(window);

            return;
        }

        public uint UpdatingThread() {
            Thread.usleep(50100);
            bThreadRunning = true;
            
            while( !bEvKillThread ) {
                //  Thread.usleep(70000);
                //  if( miEvent.timedWait(10000000) ) continue;
                if( miEvent.timedWait(10000) ) continue;
                miEvent.reset();
                if( thePA.GetInputdata( drawRaw.DrawingDataRaw, drawFFT.DrawingDataMod) ) {
                    drawFFT.queue_draw();
                    drawRaw.queue_draw();
                } else miEvent.set();
            }
    
            drawFFT.ResetData(); drawFFT.queue_draw();
            drawRaw.ResetData(); drawRaw.queue_draw();
    
            bThreadRunning = false;
            Thread.exit(0);
            return 0;
        }

        void Terminate() {
            if( bThreadRunning ) {
                bEvKillThread = true;
                theThread.join();
            }
            quit();
        }

        void butCbPlay() {
            if( !bThreadRunning ) {
                bEvKillThread = false;
                thePA.Start();
                theThread = new Thread<uint>("updating", this.UpdatingThread);
                miEvent.set();
                butPlay.set_sensitive(false);
                cbtIn.set_sensitive(false);
                cbtOut.set_sensitive(false);
=======
using PA;
// #define GTK_STYLE_PROVIDER_PRIORITY_USER 800
const uint GTK_STYLE_PROVIDER_PRIORITY_USER= 800;

namespace myGTK{

    public class myAppGTK: Gtk.Application {
        public int err = 0;
        bool bThreadRunning = false;
        PA.PA thePA;

        Cairo.Pattern pat;
        Builder builder;

        Dialog window;
        Button butQuit;
        Button butPlay;
        Button butStop;
        myLedPaint drawLOn;
    
        public myAppGTK(PA.PA *aPA){
            Object (application_id: "org.k6systems.myAppGTK",
                    flags: ApplicationFlags.FLAGS_NONE);

            thePA=aPA;
        }

        void UpdatingThread() {
        }

        string? embedFile(string file){
            FileStream stream = FileStream.open(file, "r");
            string? line = null;
            string? str="";
            while ((line = stream.read_line ()) != null) str=str+line;

            return str;
        }

        void loadWindowFromUI(string UIFile){
            string? str=embedFile(UIFile);
            builder=new Builder();
            try {
                builder.add_from_string(str,str.length);
            } catch (GLib.Error ex) {
                err=1;
                print(ex.message);
            } 
        }

        protected override void activate() {
            // Create Objects:
            loadWindowFromUI("./src/pa1.glade");

            //Create pattern
            pat = new Cairo.Pattern.linear(0.0, 0.0, 0.0, 1.0);
            pat.add_color_stop_rgb(0.2, 1, 0, 0);
            pat.add_color_stop_rgb( 0.35, 1, 1, 0);
            pat.add_color_stop_rgb( 0.65, 0, 1, 0);    

            //Create Widgets
            window = (Dialog) builder.get_object("miWindow"); 
            butQuit = (Button) builder.get_object("miQuit");
            butPlay = (Button) builder.get_object("miPlay");
            butStop = (Button) builder.get_object("miStop");
            drawLOn = (myLedPaint) builder.get_object("miLedOn");
    
            //Connect signal callbacks
            window.destroy.connect (this.terminate);
            butQuit.clicked.connect(this.terminate);
            butPlay.clicked.connect(this.butCbPlay);
            butStop.clicked.connect(this.butCbStop);
    
            // Other initializations
            var cssProvider= new CssProvider();
            cssProvider.load_from_path("theme.css");
            StyleContext.add_provider_for_screen(Gdk.Screen.get_default(), (StyleProvider)cssProvider, GTK_STYLE_PROVIDER_PRIORITY_USER);

            this.add_window(window);
        }

        //  If you're calling g_application_run() then you don't need to call gtk_main() 
        //  (and before gtk.init) as well: the run() method will spin the main loop for you.
        //  You also don't use gtk_main_quit() to stop the application's main loop: you 
        //  should use g_application_quit() instead.
        void terminate()  {
            if (bThreadRunning) {
            //      self.bEvKillThread = true;
            //      _ = c.g_thread_join(self.theThread);
            }
            this.quit();
        }

        void butCbPlay()  {
            if (!bThreadRunning) {
                //  self.bEvKillThread = false;
                //  self.thePA.Start();
                //  self.theThread = c.g_thread_new("updating", @as(c.GThreadFunc, @ptrCast(&UpdatingThread)), self);
                //  self.miEvent.set();
                butPlay.set_sensitive(false);
                //  c.gtk_widget_set_sensitive(@ptrCast(self.cbtIn), 0);
                //  c.gtk_widget_set_sensitive(@ptrCast(self.cbtOut), 0);
>>>>>>> 92965d9 (.)
            }
        }
    
        void butCbStop() {
<<<<<<< HEAD
            if( bThreadRunning ) {
                bEvKillThread = true;
                theThread.join();
                thePA.Stop();
                miEvent.reset();
                cbtIn.set_sensitive(true);
                cbtOut.set_sensitive(true);
            }
    
            if( myCBTDecvices.GetReadyToPlay() ) {
                butPlay.set_sensitive(true);
            }
        }
    }

    //////////////////////////////////////
    //  class myDALed
    //////////////////////////////////////
    public class myDALed: Object {
        public enum Color {RED,GREEN}
        public enum State {ON,OFF}

        DrawingArea da;
        Color color;
        State state;
        Cairo.Pattern pat;
    
        public  myDALed(DrawingArea da_ref,Color c, State s) {
            Object();

            da=da_ref;
            color=c;
            state=s;
            da.draw.connect(this.DrawLed);

            // Patterns
            pat = new Cairo.Pattern.linear(0.0, 0.0, 1.0, 1.0);
            pat.add_color_stop_rgb( 0.15, 0.80, 0.80, 0.80);
            pat.add_color_stop_rgb( 0.35, 0.65, 0.65, 0.65);
            pat.add_color_stop_rgb( 0.55, 0.25, 0.25, 0.25);    
        }

        bool DrawLed(Widget w, Context cr) {
            float width =w.get_allocated_width();
            float height=w.get_allocated_height();
    
            cr.scale(width, height);
    
            cr.set_line_width(0.08);
            cr.set_source(pat);
            cr.arc(0.50, 0.50, 0.50, 0, 2 * Math.PI);
            cr.fill();
    
            double intens = (state==ON) ? 1.0 : 0.25 ;
            double mired = (color==RED) ? intens : 0 ;
            double migreen = (color!=RED) ? 0.7*intens : 0.05 ;
            cr.set_source_rgb( mired, migreen, 0.05);
            cr.arc(0.50, 0.50, 0.35, 0, 2 * Math.PI);
            cr.fill();
    
            cr.translate( 0.4, 0.4);
            cr.rotate( -Math.PI / 4);
            cr.scale( 1.5, 1);
            cr.set_source_rgba( 1, 1, 1, 0.25);
            cr.arc( 0, 0, 0.1, 0, 2 * Math.PI);
            cr.fill();
    
            return false;
        }    

        public void SetState(State s) {
            state=s;
            da.queue_draw();
        }
    }

    //////////////////////////////////////
    //  class myDAAudio
    //////////////////////////////////////
    class myDAAudio: Object {
        public enum Kind {FFT,RAW}

        const float DIVISIONES_F = 64f;
        const float INC_F = 1f / DIVISIONES_F;
        const float SEP_MIN_F = INC_F / 4f;
        const float DIVISIONES_R = 1024;
        const float INC_R = 1f / DIVISIONES_R;
        const float SEP_MIN_R = INC_R / 4f;

        DrawingArea da;
        Kind kind;
        Cairo.Pattern pat;
        public float[] DrawingDataRaw=new float[1024];
        public float[] DrawingDataMod=new float[1024];

        public  myDAAudio(DrawingArea da_ref,Kind k) {
            Object();

            da=da_ref;
            kind=k;
            if(kind==FFT) {
                da.draw.connect(this.DrawFFT);
                // Patterns
                pat = new Cairo.Pattern.linear(0.0, 0.0, 0.0, 1.0);
                pat.add_color_stop_rgb( 0.20, 1, 0, 0);
                pat.add_color_stop_rgb( 0.35, 1, 1, 0);
                pat.add_color_stop_rgb( 0.65, 0, 1, 0);    
            }
            else {
                da.draw.connect(this.DrawRaw);
                pat = new Cairo.Pattern.radial(0.0, 0.0, 0.0, 0.0, 0.0, 1.0);
                pat.add_color_stop_rgb( 0.10, 1, 0, 0);
                pat.add_color_stop_rgb( 0.17, 1, 1, 0);
                pat.add_color_stop_rgb( 0.25, 0, 1, 0);    
                pat.add_color_stop_rgb( 0.32, 1, 1, 0);
                pat.add_color_stop_rgb( 0.40, 1, 0, 0);
            }

            ResetData();
        }

        public void ResetData() {
            if(kind==FFT) 
                for( int i=0; i<1024; i++) DrawingDataMod[i]= 0.02f;
            else
                Memory.set(DrawingDataRaw,0,sizeof(float)*DrawingDataRaw.length);
        }

        public void queue_draw() {
            da.queue_draw();
        }

        bool DrawFFT(Widget w, Context cr) {
            float width =w.get_allocated_width();
            float height=w.get_allocated_height();

            var context = w.get_style_context();
            context.render_background(cr, 0, 0, width, height);
            //        if (!self.bThreadRunning) return c.FALSE;
    
            cr.scale(width, height);
            cr.set_source(pat);
    
            var i = 0f;
            var ANCHO_MAX_F = INC_F - SEP_MIN_F;
            float ANCHO_F;
            if (ANCHO_MAX_F > 0.1) ANCHO_F=0.1f; else ANCHO_F=ANCHO_MAX_F;
    
            uint pos = 0;
            uint POS_INC_F = (uint)(1024 / 16 / DIVISIONES_F); // 22 Khz => 1024/2,    si 11KHz => 1024/4
            while (i < 1) {
                cr.rectangle( i, 1.0, ANCHO_F, -DrawingDataMod[pos]);
                
                pos += POS_INC_F;
                i += INC_F;
            }
            cr.fill();

            return false;
        }    

        bool DrawRaw(Widget w, Context cr) {
            float width =w.get_allocated_width();
            float height=w.get_allocated_height();
    
            var context = w.get_style_context();
            context.render_background(cr, 0, 0, width, height);
            // if (!self.bThreadRunning) return c.FALSE;
    
            cr.scale(width, height);
            cr.set_line_width(0.005);
    
            float i = 0, K = 1.8f, R = 0.15f;
            float m = 0.0f, fi= 0.0f;
            float  x = R, y = 0;
    
            cr.translate(0.5, 0.5);
            cr.set_source(pat);
            cr.move_to(K * (x + DrawingDataRaw[0]), 0.0);
    
            int pos = 0;
            while (i < 1) {
                m = R + DrawingDataRaw[pos];
                x = K * m * (float)Math.cos(fi);
                y = -K * m * (float)Math.sin(fi);
                cr.line_to(x, y);

                pos ++; i += INC_R;
                fi = i * 2f * (float)Math.PI;
            }

            cr.line_to( K * (0.15 + DrawingDataRaw[0]), 0.0);
            cr.stroke();

            var app=myAppGTK.GetApp();
            app.miEvent.set();
    
            return false;
        }
    }

    //////////////////////////////////////
    //  class myCBTDecvices
    //////////////////////////////////////
    public class myCBTDecvices: Object {
        public enum Kind {IN,OUT}

        ComboBoxText cbt;
        Kind kind;
        static myAppGTK app;
        static int[] DevPair = { -1, -1 };

        public  myCBTDecvices(ComboBoxText cbt_ref,Kind k) {
            Object();

            cbt=cbt_ref;
            kind=k;
            app=myAppGTK.GetApp();

            unowned var theListDev =  app.thePA.GetDevices();
            var numDevices=theListDev.length();
            for( int i=0; i<numDevices; i++ ) {
                var name=theListDev.nth_data(i).name;
                int max=0;
                if( kind == IN && theListDev.nth_data(i).max_input_channels>0) 
                    cbt.append_text(name);
                if( kind == OUT && theListDev.nth_data(i).max_output_channels>0) 
                    cbt.append_text(name);
            }
    
            cbt.changed.connect(this.inoutCbtChanged);
        }

        public static  bool GetReadyToPlay() {
            if( DevPair[0] != -1 && DevPair[1] != -1 ) {
                return app.thePA.CheckCompatibility(DevPair[0], DevPair[1]);
            } else return false;
        }  

        public void set_sensitive(bool b) {
            cbt.set_sensitive(b);
        }

        void inoutCbtChanged(ComboBox cbt_ref) {
            var in = getIndexFromCBT(cbt_ref);
    
            var ptrW= (Widget)cbt_ref;
            var name = ptrW.get_name();
            if( name== "miCBTIn" ) DevPair[0] = in;
            else DevPair[1] = in;
    
            if( GetReadyToPlay() ) {
                app.butPlay.set_sensitive(true);
    
                app.LedGo.SetState(ON);
                app.LedNoGo.SetState(OFF);
            } else app.butPlay.set_sensitive(false);
        }
    
        int getIndexFromCBT(ComboBox cb_ref) {
            var text=cbt.get_active_text();
            
            unowned var theListDev=app.thePA.GetDevices();
            var numDevices=theListDev.length();
            for( int i=0; i<numDevices; i++ ) {
                if( theListDev.nth_data(i).name == text ) return i;
            }
    
            return -1;
        }
    }


    //////////////////////////////////////
    //  class ResetEvent
    //////////////////////////////////////
    public class ResetEvent {
        private uchar aux='a';
        private AsyncQueue<uchar*> miQueue;
    
        public ResetEvent() {
            miQueue=new AsyncQueue<uchar*>();
        }
    
        public void set() {
            miQueue.push(&aux);
        }
    
        public void reset() {
            while( miQueue.length()>0 ) miQueue.pop();
        }
    
        public void wait() {
            miQueue.pop();
        }

        public bool timedWait(int milliseconds) {
            return miQueue.timeout_pop(milliseconds)==null?true:false;
=======
            if (bThreadRunning) {
                //  self.bEvKillThread = true;
                //  _ = c.g_thread_join(self.theThread);
                //  self.thePA.Stop();
                //  self.miEvent.reset();
                //  c.gtk_widget_set_sensitive(@ptrCast(self.cbtIn), 1);
                //  c.gtk_widget_set_sensitive(@ptrCast(self.cbtOut), 1);
            }
    
            //  if (self.GetReadyToPlay()) {
               if(true) {
                    butPlay.set_sensitive(true);
            }
        }
    
    }

    class myLedPaint: DrawingArea{
        public myLedPaint.Init(DrawingArea da){
            Object(da);

>>>>>>> 92965d9 (.)
        }
    }
}
//      public class ResetEvent {
//          private Mutex mutex;
//          private Cond cond;
//          private bool signaled = false;
    
//          public ResetEvent() {
//          }
    
//          public void set() {
//              mutex.lock();
//              signaled = true;
//              cond.signal();
//              mutex.unlock();
//          }
    
//          public void reset() {
//              mutex.lock();
//              signaled = false;
//              mutex.unlock();
//          }
    
//          public void wait() {
//              mutex.lock();
//              while (!signaled) {
//                  cond.wait(mutex);
//              }
//              mutex.unlock();
//          }

//          public bool timedWait(int milliseconds) {
//              bool timeout_ended=false;

//              mutex.lock();
//              if (!signaled) {
//                  var timeout = Timeout.add(milliseconds, () => {
//                      timeout_ended=true;
//                      cond.signal();
//                      return false; // Para que el temporizador se detenga después de la primera ejecución
//                  });
    
//                  while (!signaled) {
//                      cond.wait(mutex);
//                  }
//              }
//              mutex.unlock();
//              return timeout_ended;
//          }
//      }
//  }

<<<<<<< HEAD
=======
pub const GTK = struct {
    err: [*c][*c]c.GError = null,
    pat: ?*c.cairo_pattern_t = null,
    window: [*c]c.GObject = null,
    butQuit: [*c]c.GObject = null,
    drawFFT: [*c]c.GObject = null,
    drawFall: [*c]c.GObject = null,
    cbtIn: [*c]c.GObject = null,
    cbtOut: [*c]c.GObject = null,
    butPlay: [*c]c.GObject = null,
    butStop: [*c]c.GObject = null,
    drawLOn: [*c]c.GObject = null,
    drawLOff: [*c]c.GObject = null,
    bLedOnState: bool = false,
    bLedOffState: bool = true,

    bEvKillThread: bool = false,
    bThreadRunning: bool = false,
    theThread: [*c]c.GThread = null,

    thePA: *pa.PA = undefined,
    DevPair: [2]i32 = .{ -1, -1 },
    DrawingDataRaw: [1024]f32 = .{0} ** 1024,
    DrawingDataMod: [1024]f32 = .{0.02} ** 1024,
    miEvent: std.Thread.ResetEvent = std.Thread.ResetEvent{},

    pub fn Init(paptr: *pa.PA) *GTK {


        const drawFFT = c.gtk_builder_get_object(builder, "miLienzoFFT");
        const drawFall = c.gtk_builder_get_object(builder, "miLienzoFall");
        const cbtIn = c.gtk_builder_get_object(builder, "miCBTIn");
        const cbtOut = c.gtk_builder_get_object(builder, "miCBTOut");
        const drawLOn = c.gtk_builder_get_object(builder, "miLedOn");
        const drawLOff = c.gtk_builder_get_object(builder, "miLedOff");

    }

    pub fn RunMain(self: *GTK) void {

        const theListDev = self.thePA.GetDevices();
        for (0..theListDev.len) |n| {
            const dev = theListDev.get(n);

            var ptr: [*c]c.GtkComboBoxText = @ptrCast(self.cbtIn);
            if (dev.maxInputChannels > 0) c.gtk_combo_box_text_append_text(ptr, dev.name);

            ptr = @ptrCast(self.cbtOut);
            if (dev.maxOutputChannels > 0) c.gtk_combo_box_text_append_text(ptr, dev.name);
        }


        SignalConnect(self.drawFFT, "draw", @ptrCast(&DrawFFT), self);
        SignalConnect(self.drawFall, "draw", @ptrCast(&DrawFall), self);
        SignalConnect(self.cbtIn, "changed", @ptrCast(&inoutCbChanged), self);
        SignalConnect(self.cbtOut, "changed", @ptrCast(&inoutCbChanged), self);
        SignalConnect(self.drawLOn, "draw", @ptrCast(&DrawLOn), self);
        SignalConnect(self.drawLOff, "draw", @ptrCast(&DrawLOff), self);

        c.gtk_widget_set_sensitive(@ptrCast(self.butPlay), 0);

        return;
    }

    fn UpdatingThread(self: *GTK) void {
        c.g_usleep(50_100);
        self.bThreadRunning = true;
        c.g_print("bThreadRunning: %d\n", self.bThreadRunning);

        while (!self.bEvKillThread) {
            //c.g_usleep(70_000);
            //self.miEvent.timedWait(30_000_000) catch continue;
            self.miEvent.timedWait(10_000_000) catch continue;
            self.miEvent.reset();
            if (self.thePA.GetInputdata(&self.DrawingDataRaw, &self.DrawingDataMod)) {
                c.gtk_widget_queue_draw(@ptrCast(self.drawFFT));
                c.gtk_widget_queue_draw(@ptrCast(self.drawFall));
            } else self.miEvent.set();
        }

        self.DrawingDataRaw = .{0.0} ** 1024;
        self.DrawingDataMod = .{0.02} ** 1024;
        c.gtk_widget_queue_draw(@ptrCast(self.drawFFT));
        c.gtk_widget_queue_draw(@ptrCast(self.drawFall));

        c.g_print("bEvKillThread: %d\n", self.bEvKillThread);
        self.bThreadRunning = false;
        var zero: u8 = 0;
        c.g_thread_exit(@as(c.gpointer, &zero));
    }


    fn DrawFall(widget: [*c]c.GtkWidget, cr: *c.cairo_t, ptrSelf: c.gpointer) c.gboolean {
        const width: f64 = @floatFromInt(c.gtk_widget_get_allocated_width(widget));
        const height: f64 = @floatFromInt(c.gtk_widget_get_allocated_height(widget));

        const context = c.gtk_widget_get_style_context(widget);
        c.gtk_render_background(context, cr, 0, 0, width, height);

        const self: *GTK = @ptrCast(@alignCast(ptrSelf));
        //        if (!self.bThreadRunning) return c.FALSE;

        c.cairo_scale(cr, width, height);
        c.cairo_set_source_rgba(cr, 0.4, 0.8, 0, 0.8);
        c.cairo_set_line_width(cr, 0.005);

        var i: f64 = 0;
        const DIVISIONES: f64 = 1024;
        const INC = 1 / DIVISIONES;

        const K: f64 = 1.8;
        const R: f64 = 0.15;
        var m: f64 = 0.0;
        var fi: f64 = 0.0;
        var x: f64 = R;
        var y: f64 = 0;

        c.cairo_translate(cr, 0.5, 0.5);
        c.cairo_move_to(cr, K * (x + self.DrawingDataRaw[0]), 0.0);

        var pos: usize = 0.0;
        i = 0;
        while (i < 1) : ({
            pos += 1;
            i += INC;
            fi = i * 2 * std.math.pi;
        }) {
            m = R + self.DrawingDataRaw[pos];
            x = K * m * std.math.cos(fi);
            y = -K * m * std.math.sin(fi);
            c.cairo_line_to(cr, x, y);
        }
        c.cairo_line_to(cr, K * (0.15 + self.DrawingDataRaw[0]), 0.0);
        c.cairo_stroke(cr);

        self.miEvent.set();

        return c.FALSE;
    }

    fn DrawFFT(widget: [*c]c.GtkWidget, cr: *c.cairo_t, ptrSelf: c.gpointer) c.gboolean {
        const width: f64 = @floatFromInt(c.gtk_widget_get_allocated_width(widget));
        const height: f64 = @floatFromInt(c.gtk_widget_get_allocated_height(widget));

        const context = c.gtk_widget_get_style_context(widget);
        c.gtk_render_background(context, cr, 0, 0, width, height);

        const self: *GTK = @ptrCast(@alignCast(ptrSelf));
        //        if (!self.bThreadRunning) return c.FALSE;

        c.cairo_scale(cr, width, height);

        c.cairo_set_source(cr, self.pat);

        var i: f64 = 0;
        const DIVISIONES: f64 = 64; // si quiero visualizar hasta 22Khz => max 512 divs, si quiero hasta 11KHz => max 256 divs, y asi
        const INC = 1 / DIVISIONES;
        const SEP_MIN: f64 = INC / 4;
        const ANCHO_MAX = INC - SEP_MIN;
        const ANCHO: f64 = if (ANCHO_MAX > 0.1) 0.1 else ANCHO_MAX;

        var pos: usize = 0;
        const POS_INC: usize = @intFromFloat(1024 / 16 / DIVISIONES); // 22 Khz => 1024/2,    si 11KHz => 1024/4
        while (i < 1) : ({
            //pos += 8;
            //i += INC * 2;
            pos += POS_INC;
            i += INC;
        }) {
            c.cairo_rectangle(cr, i, 1.0, ANCHO, -self.DrawingDataMod[pos]);
        }
        c.cairo_fill(cr);

        return c.FALSE;
    }

    fn DrawLOn(widget: [*c]c.GtkWidget, cr: *c.cairo_t, ptrSelf: c.gpointer) c.gboolean {
        const self: *GTK = @ptrCast(@alignCast(ptrSelf));

        DrawLed(widget, cr, false, self.bLedOnState);

        return c.FALSE;
    }

    fn DrawLOff(widget: [*c]c.GtkWidget, cr: *c.cairo_t, ptrSelf: c.gpointer) c.gboolean {
        const self: *GTK = @ptrCast(@alignCast(ptrSelf));

        DrawLed(widget, cr, true, self.bLedOffState);
        return c.FALSE;
    }

    fn DrawLed(widget: [*c]c.GtkWidget, cr: *c.cairo_t, red: bool, on: bool) void {
        const width: f64 = @floatFromInt(c.gtk_widget_get_allocated_width(widget));
        const height: f64 = @floatFromInt(c.gtk_widget_get_allocated_height(widget));

        c.cairo_scale(cr, width, height);

        //c.cairo_set_line_width(cr, 0.08);
        c.cairo_set_source_rgb(cr, 0.3, 0.3, 0.3);
        c.cairo_arc(cr, 0.50, 0.50, 0.50, 0, 2 * c.G_PI);
        //c.cairo_stroke_preserve(cr);
        c.cairo_fill(cr);

        const intens: f64 = if (on) 1.0 else 0.25;
        const mired: f64 = if (red) intens else 0;
        const migreen: f64 = if (!red) 0.7 * intens else 0.05;
        c.cairo_set_source_rgb(cr, mired, migreen, 0.05);
        c.cairo_arc(cr, 0.50, 0.50, 0.35, 0, 2 * c.G_PI);
        c.cairo_fill(cr);

        c.cairo_translate(cr, 0.4, 0.4);
        c.cairo_rotate(cr, -c.G_PI / 4);
        c.cairo_scale(cr, 1.5, 1);
        c.cairo_set_source_rgba(cr, 1, 1, 1, 0.25);
        c.cairo_arc(cr, 0, 0, 0.1, 0, 2 * c.G_PI);
        c.cairo_fill(cr);

        return;
    }

    fn inoutCbChanged(cbt: [*c]c.GtkComboBox, ptrSelf: c.gpointer) void {
        const self: *GTK = @ptrCast(@alignCast(ptrSelf));
        const in = self.getIndexFromCBT(cbt);

        const ptrW: [*c]c.GtkWidget = @ptrCast(cbt);
        const name: [*:0]u8 = @constCast(c.gtk_widget_get_name(ptrW));
        const result = std.mem.orderZ(u8, name, "In");
        if (result == .eq) self.DevPair[0] = in else self.DevPair[1] = in;

        if (self.GetReadyToPlay()) {
            c.gtk_widget_set_sensitive(@ptrCast(self.butPlay), 1);

            self.bLedOnState = true;
            self.bLedOffState = false;
            c.gtk_widget_queue_draw(@ptrCast(self.drawLOn));
            c.gtk_widget_queue_draw(@ptrCast(self.drawLOff));
        } else c.gtk_widget_set_sensitive(@ptrCast(self.butPlay), 0);
    }

    fn getIndexFromCBT(self: *GTK, cbt: [*c]c.GtkComboBox) i32 {
        const myPtr: [*c]c.GtkComboBoxText = @ptrCast(cbt);
        const text: [*:0]u8 = c.gtk_combo_box_text_get_active_text(myPtr);
        defer c.g_free(text);

        const theListDev = self.thePA.GetDevices();

        for (0..theListDev.len) |n| {
            const dev = theListDev.get(n);
            const result = std.mem.orderZ(u8, text, dev.name);
            if (result == .eq) return @intCast(n);
        }

        return -1;
    }

    fn GetReadyToPlay(self: *GTK) bool {
        if (self.DevPair[0] != -1 and self.DevPair[1] != -1) {
            return TheGTK.thePA.CheckCompatibility(self.DevPair[0], self.DevPair[1]);
        } else return false;
    }
};
*/
>>>>>>> 92965d9 (.)
