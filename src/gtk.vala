using Gtk;
using Cairo;
using Math;

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

        public static  uint many=0;
        public double time=0;
        Timer t1;
        public static Timer t2=new Timer();
        ulong microseconds;

        
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

            t1=new Timer();

            return;
        }

        public uint UpdatingThread() {
            Thread.usleep(50100);
            bThreadRunning = true;
            
            while( !bEvKillThread ) {
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

                t1.start();
            }
        }
    
        void butCbStop() {
            if( bThreadRunning ) {
                bEvKillThread = true;
                theThread.join();
                thePA.Stop();
                miEvent.reset();
                cbtIn.set_sensitive(true);
                cbtOut.set_sensitive(true);

                t1.stop();
                double seconds;
    
                seconds = t1.elapsed (out microseconds);
                print ("gtk: Total segundos: %s\n", seconds.to_string ());
                print ("gtk: milisec por vez: %f\n", seconds*1000/many);
                print ("gtk: %5.0f veces, %f veces/s \n", many, many/seconds);
                print ("gtk: cb total time en ms  %f, usec por vez %f\n",time*1000,time*1000000/many);
                print ("gtk: ===========\n\n");
                many=0;
                time=0;    
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
            var app=myAppGTK.GetApp();
            app.t2.start();

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

            app.t2.stop(); double microseconds;
            app.time+=app.t2.elapsed(out microseconds);

            return false;
        }    

        bool DrawRaw(Widget w, Context cr) {
            var app=myAppGTK.GetApp();
            app.t2.start();

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

            //  var app=myAppGTK.GetApp();
            app.miEvent.set();
    
            app.many++;
            app.t2.stop(); double microseconds;
            app.time+=app.t2.elapsed(out microseconds);

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

